@tool
class_name PopochiuMigration14
extends PopochiuMigration

const VERSION = 14
const DESCRIPTION = "Normalize GUI inventory component unique names"
const STEPS = [
	"Normalize copied GUI inventory component node names and unique-name flags",
]
const COMPONENT_SCENES := [
	{
		path = "res://game/gui/components/9_verb_panel/9_verb_panel.tscn",
		current_name = "9VerbInventoryGrid",
		target_name = "9VerbInventoryGrid",
	},
	{
		path = "res://game/gui/components/9_verb_panel_high_res/9_verb_panel_high_res.tscn",
		current_name = "9VerbInventoryGridHighRes",
		target_name = "9VerbInventoryGrid",
	},
	{
		path = "res://game/gui/components/sierra_inventory_popup/sierra_inventory_popup.tscn",
		current_name = "SierraInventoryGrid",
		target_name = "SierraInventoryGrid",
	},
	{
		path = "res://game/gui/components/sierra_inventory_popup_high_res/sierra_inventory_popup_high_res.tscn",
		current_name = "SierraInventoryGridHighRes",
		target_name = "SierraInventoryGrid",
	},
	{
		path = "res://game/gui/components/simple_click_bar/simple_click_bar.tscn",
		current_name = "SimpleClickBar",
		target_name = "SimpleClickBar",
	},
	{
		path = "res://game/gui/components/simple_click_bar_high_res/simple_click_bar_high_res.tscn",
		current_name = "SimpleClickBarHighRes",
		target_name = "SimpleClickBar",
	},
]


#region Virtual ####################################################################################
func _is_migration_needed() -> bool:
	for scene_data: Dictionary in COMPONENT_SCENES:
		var node := _get_inventory_component_node(scene_data.path, scene_data.current_name, scene_data.target_name)
		if not is_instance_valid(node):
			continue

		if node.name != scene_data.target_name or not node.unique_name_in_owner:
			return true

	return false


func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[_normalize_inventory_component_unique_names]
	)


#endregion

#region Private ####################################################################################
func _normalize_inventory_component_unique_names() -> Completion:
	var updated_any := false

	for scene_data: Dictionary in COMPONENT_SCENES:
		if not FileAccess.file_exists(scene_data.path):
			continue

		var packed_scene := ResourceLoader.load(
			scene_data.path, "", ResourceLoader.CACHE_MODE_IGNORE
		) as PackedScene
		if not packed_scene:
			PopochiuUtils.print_error(
				"Migration %d: Couldn't load GUI component scene %s" % [VERSION, scene_data.path]
			)
			return Completion.FAILED

		var scene := packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		var node := _find_inventory_component_node(
			scene, scene_data.current_name, scene_data.target_name
		)
		if not is_instance_valid(node):
			continue

		var changed := false
		if node.name != scene_data.target_name:
			node.name = scene_data.target_name
			changed = true

		if not node.unique_name_in_owner:
			node.unique_name_in_owner = true
			changed = true

		if not changed:
			continue

		if PopochiuEditorHelper.pack_scene(scene, scene_data.path) != OK:
			PopochiuUtils.print_error(
				"Migration %d: Couldn't update GUI component scene %s" % [VERSION, scene_data.path]
			)
			return Completion.FAILED

		updated_any = true

	return Completion.DONE if updated_any else Completion.IGNORED


func _get_inventory_component_node(
	scene_path: String, current_name: String, target_name: String
) -> Node:
	if not FileAccess.file_exists(scene_path):
		return null

	var packed_scene := ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if not packed_scene:
		return null

	var scene := packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	return _find_inventory_component_node(scene, current_name, target_name)


func _find_inventory_component_node(scene: Node, current_name: String, target_name: String) -> Node:
	if scene.name == current_name or scene.name == target_name:
		return scene

	var node := scene.find_child(target_name, true, false)
	if is_instance_valid(node):
		return node

	return scene.find_child(current_name, true, false)


#endregion