@tool
class_name PopochiuMigration17
extends PopochiuMigration

const VERSION = 17
const DESCRIPTION = "Migrate inventory checks and copied GUI components to 2.1.1"
const STEPS = [
	"Update unambiguous player inventory checks",
	"Update copied GUI inventory hook signatures",
	"Update active GUI component unique names",
	"Update copied GUI component scripts",
	"Report inventory code that needs manual migration",
]

const GUI_SCENE_PATH := "res://game/gui/gui.tscn"
const VERB_PANEL_SCENE_PATH := "res://game/gui/components/9_verb_panel/9_verb_panel.tscn"
const VERB_PANEL_HIGH_RES_SCENE_PATH := (
	"res://game/gui/components/9_verb_panel_high_res/9_verb_panel_high_res.tscn"
)
const SIERRA_POPUP_SCENE_PATH := (
	"res://game/gui/components/sierra_inventory_popup/sierra_inventory_popup.tscn"
)
const SIERRA_POPUP_HIGH_RES_SCENE_PATH := (
	"res://game/gui/components/sierra_inventory_popup_high_res/sierra_inventory_popup_high_res.tscn"
)
const INVENTORY_GRID_ADDON_PATH := (
	"res://addons/popochiu/engine/objects/gui/components/inventory_grid/inventory_grid.gd"
)
const INVENTORY_GRID_GAME_PATH := "res://game/gui/components/inventory_grid/inventory_grid.gd"

const LEGACY_PATTERNS := [
	"I.items",
	"PopochiuUtils.i.items",
	r"I\.[A-Za-z_]\w*\.in_inventory\b",
	"in_inventory\\s*=",
	"I\\.add_item\\(",
	"I\\.remove_item\\(",
	"func _on_item_added(item: PopochiuInventoryItem) -> void:",
	"func _on_item_removed(item: PopochiuInventoryItem) -> void:",
	"func _on_item_replaced(item: PopochiuInventoryItem, new_item: PopochiuInventoryItem) -> void:",
]


#region Virtual ####################################################################################
func _is_migration_needed() -> bool:
	return (
		not _get_game_scripts_with_legacy_inventory_code().is_empty()
		or _gui_component_migration_needed()
		or _gui_scripts_migration_needed()
	)


func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_migrate_player_inventory_checks,
			_migrate_gui_inventory_hooks,
			_migrate_gui_component_unique_names,
			_migrate_gui_component_scripts,
			_report_legacy_inventory_code,
		]
	)


#endregion

#region Private ####################################################################################
## Converts the old, player-only ownership check to the explicit player API.
## This is safe because the old I.Item.in_inventory API always targeted the player character.
func _migrate_player_inventory_checks() -> Completion:
	var replacements: Array[Dictionary] = []
	replacements.assign([
		{
			pattern = r"I\.([A-Za-z_]\w*)\.in_inventory\b",
			to = "C.player.has_inventory_item(\"$1\")",
		},
	])
	var folders_to_ignore: Array[String] = []
	folders_to_ignore.assign(["autoloads"])
	var replaced := PopochiuMigrationHelper.replace_regex_in_scripts(
		replacements, folders_to_ignore
	)
	return Completion.DONE if replaced else Completion.IGNORED


## Updates hooks copied from older GUI templates to the per-character signatures.
func _migrate_gui_inventory_hooks() -> Completion:
	var replacements: Array[Dictionary] = []
	replacements.assign([
		{
			pattern = r"func _on_item_added\(item: PopochiuInventoryItem\) -> void:",
			to = "func _on_item_added(item: PopochiuInventoryItem, _character: PopochiuCharacter) -> void:",
		},
		{
			pattern = r"func _on_item_removed\(item: PopochiuInventoryItem\) -> void:",
			to = "func _on_item_removed(item: PopochiuInventoryItem, _character: PopochiuCharacter) -> void:",
		},
		{
			pattern = r"func _on_item_replaced\(item: PopochiuInventoryItem, new_item: PopochiuInventoryItem\) -> void:",
			to = "func _on_item_replaced(item: PopochiuInventoryItem, new_item: PopochiuInventoryItem, _character: PopochiuCharacter) -> void:",
		},
		{
			pattern = r"await super\(item\)",
			to = "await super(item, _character)",
		},
		{
			pattern = r"await super\(item, new_item\)",
			to = "await super(item, new_item, _character)",
		},
	])
	var folders_to_ignore: Array[String] = []
	folders_to_ignore.assign(["autoloads"])
	var replaced := PopochiuMigrationHelper.replace_regex_in_scripts(
		replacements, folders_to_ignore
	)
	return Completion.DONE if replaced else Completion.IGNORED


## Updates the active GUI scene nodes required by the 2.1.1 GUI scripts.
func _migrate_gui_component_unique_names() -> Completion:
	var scenes := _get_gui_component_scenes()
	if scenes.is_empty():
		return Completion.IGNORED

	var updated_any := false
	for scene_data: Dictionary in scenes:
		var scene_path: String = scene_data.path
		var node_names: Array[String] = scene_data.node_names
		if _set_scene_node_unique_name(scene_path, node_names):
			updated_any = true

	return Completion.DONE if updated_any else Completion.IGNORED


## Refreshes the GUI component scripts copied to the game folder with the 2.1.1
## implementation (per-character inventory). Game copies keep the GUI class
## prefix so they never collide with the addon class_names.
func _migrate_gui_component_scripts() -> Completion:
	var copies := _get_gui_script_copies()
	if copies.is_empty():
		return Completion.IGNORED

	var updated_any := false
	for copy: Dictionary in copies:
		var addon_path: String = copy.addon
		var game_path: String = copy.game
		if not _is_gui_script_copy_stale(addon_path, game_path):
			continue
		if not _refresh_gui_script_copy(addon_path, game_path):
			return Completion.FAILED
		PopochiuUtils.print_normal(
			"Migration %d: Updated copied GUI script %s" % [VERSION, game_path]
		)
		updated_any = true

	return Completion.DONE if updated_any else Completion.IGNORED


## Reports patterns whose target character or intended side effects cannot be inferred safely.
func _report_legacy_inventory_code() -> Completion:
	var matches := _get_game_scripts_with_legacy_inventory_code()
	if matches.is_empty():
		return Completion.IGNORED

	var files_list := ""
	for file_path: String in matches:
		files_list += "\n- %s" % file_path

	PopochiuUtils.print_warning(
		"Migration %d: Found inventory code that requires manual migration:%s\n" % [
			VERSION, files_list
		]
		+ "I.items and direct in_inventory assignments no longer identify a "
		+ "character reliably. Use C.player.inventory or the character inventory API "
		+ "and pass the target character explicitly when needed."
	)
	return Completion.DONE


func _get_game_scripts_with_legacy_inventory_code() -> Array[String]:
	var script_paths := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.GAME_PATH, ["gd"], ["autoloads"]
	)
	var matching_files: Array[String] = []

	for file_path: String in script_paths:
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			continue
		var content := file.get_as_text()
		file.close()

		for pattern: String in LEGACY_PATTERNS:
			var regex := RegEx.new()
			if regex.compile(pattern) == OK and regex.search(content):
				matching_files.append(file_path)
				break

	return matching_files


func _get_gui_template() -> String:
	var template := PopochiuResources.get_data_value("ui", "template", "") as String
	return template.to_lower().replace("_", "").replace(" ", "").replace("-", "")


func _get_gui_component_scenes() -> Array[Dictionary]:
	var template := _get_gui_template()
	var scenes: Array[Dictionary] = []

	if template.contains("simpleclick"):
		var node_names: Array[String] = []
		node_names.assign(["SimpleClickBar", "SimpleClickBarHighRes"])
		scenes.assign([
			{ path = GUI_SCENE_PATH, node_names = node_names },
		])
	elif template.contains("9verb"):
		var base_names: Array[String] = []
		base_names.assign(["9VerbInventoryGrid", "9VerbInventoryGridHighRes"])
		var high_res_names: Array[String] = []
		high_res_names.assign(["9VerbInventoryGrid", "9VerbInventoryGridHighRes"])
		scenes.assign([
			{ path = VERB_PANEL_SCENE_PATH, node_names = base_names },
			{ path = VERB_PANEL_HIGH_RES_SCENE_PATH, node_names = high_res_names },
		])
	elif template.contains("sierra") or template.contains("actionbar"):
		var base_names: Array[String] = []
		base_names.assign(["SierraInventoryGrid", "SierraInventoryGridHighRes"])
		var high_res_names: Array[String] = []
		high_res_names.assign(["SierraInventoryGrid", "SierraInventoryGridHighRes"])
		scenes.assign([
			{ path = SIERRA_POPUP_SCENE_PATH, node_names = base_names },
			{ path = SIERRA_POPUP_HIGH_RES_SCENE_PATH, node_names = high_res_names },
		])

	return scenes


func _gui_component_migration_needed() -> bool:
	var scenes := _get_gui_component_scenes()
	if scenes.is_empty():
		return false

	for scene_data: Dictionary in scenes:
		var scene_path: String = scene_data.path
		var node_names: Array[String] = scene_data.node_names
		if not FileAccess.file_exists(scene_path):
			continue
		var packed_scene := ResourceLoader.load(
			scene_path, "", ResourceLoader.CACHE_MODE_IGNORE
		) as PackedScene
		if not packed_scene:
			continue
		var scene := packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		var node: Node = null
		for node_name: String in node_names:
			node = scene.find_child(node_name, true, false)
			if is_instance_valid(node):
				break
		if is_instance_valid(node) and (
			node.name != node_names[0] or not node.unique_name_in_owner
		):
			return true

	return false


## Lists the (addon source, game copy) script pairs of the active GUI template.
## High-res templates reuse the base template scripts.
func _get_gui_script_copies() -> Array[Dictionary]:
	var template := _get_gui_template()
	var copies: Array[Dictionary] = []
	var addon_gui := "res://addons/popochiu/engine/objects/gui"
	var game_components := "res://game/gui/components"
	var game_templates := "res://game/gui/templates"

	if template.contains("simpleclick"):
		var bar_addon := (
			addon_gui + "/templates/simple_click/components/simple_click_bar/simple_click_bar.gd"
		)
		copies.assign([
			{
				addon = bar_addon,
				game = game_templates + "/simple_click/components/simple_click_bar/simple_click_bar.gd",
			},
			{
				addon = bar_addon,
				game = game_templates + "/simple_click_high_res/components/simple_click_bar_high_res/"
					+ "simple_click_bar_high_res.gd",
			},
		])
	elif template.contains("9verb"):
		var panel_addon := (
			addon_gui + "/templates/9_verb/components/9_verb_panel/9_verb_panel.gd"
		)
		var grid_addon := (
			addon_gui + "/templates/9_verb/components/9_verb_inventory_grid/9_verb_inventory_grid.gd"
		)
		copies.assign([
			{
				addon = panel_addon,
				game = game_components + "/9_verb_panel/9_verb_panel.gd",
			},
			{
				addon = panel_addon,
				game = game_components + "/9_verb_panel_high_res/9_verb_panel_high_res.gd",
			},
			{
				addon = grid_addon,
				game = game_components + "/9_verb_inventory_grid/9_verb_inventory_grid.gd",
			},
			{
				addon = grid_addon,
				game = game_components + "/9_verb_inventory_grid_high_res/9_verb_inventory_grid_high_res.gd",
			},
		])
	elif template.contains("sierra") or template.contains("actionbar"):
		var popup_addon := (
			addon_gui + "/templates/sierra/components/sierra_inventory_popup/sierra_inventory_popup.gd"
		)
		copies.assign([
			{ addon = INVENTORY_GRID_ADDON_PATH, game = INVENTORY_GRID_GAME_PATH },
			{
				addon = popup_addon,
				game = game_components + "/sierra_inventory_popup/sierra_inventory_popup.gd",
			},
			{
				addon = popup_addon,
				game = game_components + "/sierra_inventory_popup_high_res/sierra_inventory_popup.gd",
			},
		])

	return copies


func _gui_scripts_migration_needed() -> bool:
	for copy: Dictionary in _get_gui_script_copies():
		var addon_path: String = copy.addon
		var game_path: String = copy.game
		if _is_gui_script_copy_stale(addon_path, game_path):
			return true

	return false


func _is_gui_script_copy_stale(addon_path: String, game_path: String) -> bool:
	if not FileAccess.file_exists(addon_path) or not FileAccess.file_exists(game_path):
		return false

	var addon_file := FileAccess.open(addon_path, FileAccess.READ)
	var game_file := FileAccess.open(game_path, FileAccess.READ)
	if addon_file == null or game_file == null:
		if addon_file:
			addon_file.close()
		if game_file:
			game_file.close()
		return false
	var expected_content := _apply_gui_class_prefix(addon_file.get_as_text())
	addon_file.close()
	var game_content := game_file.get_as_text()
	game_file.close()
	return expected_content != game_content


func _refresh_gui_script_copy(addon_path: String, game_path: String) -> bool:
	var addon_file := FileAccess.open(addon_path, FileAccess.READ)
	if addon_file == null:
		return false
	var expected_content := _apply_gui_class_prefix(addon_file.get_as_text())
	addon_file.close()

	var game_file := FileAccess.open(game_path, FileAccess.WRITE)
	if game_file == null:
		PopochiuUtils.print_error(
			"Migration %d: Couldn't update copied GUI script %s" % [VERSION, game_path]
		)
		return false
	game_file.store_string(expected_content)
	game_file.close()
	return true


# Mirrors PopochiuGuiTemplatesHelper._copy_component_script so refreshed copies
# keep the GUI class prefix and never collide with the addon class_names.
func _apply_gui_class_prefix(source_code: String) -> String:
	if "class_name " in source_code:
		source_code = source_code.replace("class_name Popochiu", "class_name GUI")
	return source_code


func _set_scene_node_unique_name(scene_path: String, node_names: Array[String]) -> bool:
	if not FileAccess.file_exists(scene_path):
		return false

	var packed_scene := ResourceLoader.load(
		scene_path, "", ResourceLoader.CACHE_MODE_IGNORE
	) as PackedScene
	if not packed_scene:
		PopochiuUtils.print_error(
			"Migration %d: Couldn't load GUI scene %s" % [VERSION, scene_path]
		)
		return false

	var scene := packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var node: Node = null
	for node_name: String in node_names:
		node = scene.find_child(node_name, true, false)
		if is_instance_valid(node):
			break
	if not is_instance_valid(node):
		return false
	if node.name == node_names[0] and node.unique_name_in_owner:
		return false

	if node.name != node_names[0]:
		node.name = node_names[0]
	node.unique_name_in_owner = true
	return PopochiuEditorHelper.pack_scene(scene, scene_path) == OK


#endregion
