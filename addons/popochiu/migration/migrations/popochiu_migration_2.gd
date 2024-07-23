@tool
class_name PopochiuMigration2
extends PopochiuMigration
## Migrates projects from Beta to Release.

const VERSION = 2
const DESCRIPTION = "Make changes from beta-x to 2.0.0 release"
const STEPS = [
	"Add a [b]ScalingPolygon[/b] node to each [b]PopochiuCharacter[/b]. (pre [i]beta 1[/i])",
	"Create PopochiuMarkers. (pre [i]beta 2[/i])",
	"Move popochiu_settings.tres to ProjectSettings. (pre [i]beta 3[/i])",
	"Update the DialogMenu GUI component. (pre [i]beta 3[/i])",
	"(Optional) Update SettingsBar in 2-click Context-sensitive GUI template. (pre [i]beta 3[/i])",
	"Remove [b]BaselineHelper[/b] and [b]WalkToHelper[/b] nodes in [b]PopochiuClickable[/b]s." \
	+ " Also remove [b]DialogPos[/b] node in [b]PopochiuCharacter[/b]s. (pre [i]release[/i])",
	"Update uses of deprecated properties and methods. (pre [i]release[/i])",
]
const GAME_INVENTORY_BAR_PATH =\
"res://game/graphic_interface/components/inventory_bar/inventory_bar.tscn"
const GAME_SETTINGS_BAR_PATH =\
"res://game/graphic_interface/components/settings_bar/settings_bar.tscn"
const GAME_DIALOG_MENU_PATH = "res://game/graphic_interface/components/dialog_menu/dialog_menu.tscn"
const GAME_DIALOG_MENU_OPTION_PATH =\
"res://game/graphic_interface/components/dialog_menu/dialog_menu_option/"
const ADDON_DIALOG_MENU_PATH =\
"res://addons/popochiu/engine/objects/graphic_interface/components/dialog_menu/dialog_menu.tscn"
const TextSpeedOption = preload(
	PopochiuResources.GUI_TEMPLATES_FOLDER
	+ "simple_click/components/settings_bar/resources/text_speed_option.gd"
)

var _gui_templates_helper := preload(
	"res://addons/popochiu/editor/helpers/popochiu_gui_templates_helper.gd"
)


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_add_scaling_polygon_to_characters,
			_create_markers,
			_move_settings_to_project_settings,
			_update_dialog_menu,
			_update_simple_click_settings_bar,
			_remove_helper_nodes,
			_replace_deprecated,
		]
	)


#endregion

#region Private ####################################################################################
func _add_scaling_polygon_to_characters() -> Completion:
	# Get the characters' .tscn files
	var file_paths := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.CHARACTERS_PATH,
		["tscn"]
	)
	var any_character_updated := PopochiuUtils.any_exhaustive(file_paths, _add_scaling_polygon_to)
	return Completion.DONE if any_character_updated else Completion.IGNORED


## Loads the [PopochiuCharacter] in [param scene_path] and add a [CollisionPolygon2D] node if it
## doesn't has a [code]ScalingPolygon[/code] child.
func _add_scaling_polygon_to(scene_path: String) -> bool:
	var popochiu_character: PopochiuCharacter = (load(scene_path) as PackedScene).instantiate()
	var was_scene_updated := false
	
	# ---- Add the ScalingPolygon node if needed ---------------------------------------------------
	if not popochiu_character.has_node("ScalingPolygon"):
		was_scene_updated = true
		var scaling_polygon := CollisionPolygon2D.new()
		scaling_polygon.name = "ScalingPolygon"
		scaling_polygon.polygon = PackedVector2Array([
			Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)
		])
		popochiu_character.add_child(scaling_polygon)
		popochiu_character.move_child(scaling_polygon, 1)
		scaling_polygon.owner = popochiu_character
	
	if was_scene_updated and PopochiuEditorHelper.pack_scene(popochiu_character) != OK:
		PopochiuUtils.print_error(
			"Couldn't update [b]%s[/b] with new voices array." % popochiu_character.script_name
		)
	
	return was_scene_updated


func _create_markers() -> Completion:
	var any_room_updated := PopochiuUtils.any_exhaustive(
		PopochiuEditorHelper.get_rooms(), _create_room_marker
	)
	return Completion.DONE if any_room_updated else Completion.IGNORED


func _create_room_marker(popochiu_room: PopochiuRoom) -> bool:
	var markers := popochiu_room.get_markers()
	if markers.is_empty():
		return false
	
	var markers_to_add := []
	for source: Marker2D in markers.filter(
		func (node: Node) -> bool: return node is Marker2D
	):
		var factory := PopochiuMarkerFactory.new()
		if factory.create_from(source, popochiu_room) != ResultCodes.SUCCESS:
			continue
		
		source.name += "_"
		var new_obj: Marker2D = factory.get_obj_scene()
		popochiu_room.get_node(factory.get_group()).add_child(new_obj)
		markers_to_add.append(new_obj)
		new_obj.position = source.position
		
		source.free()
	
	if markers_to_add.is_empty():
		return false
	
	for marker: Marker2D in markers_to_add:
		marker.owner = popochiu_room
	
	if PopochiuEditorHelper.pack_scene(popochiu_room) != OK:
		PopochiuUtils.print_error(
			"Migration 2: Couldn't update markes in [b]%s[/b]." % popochiu_room.script_name
		)
	
	return true


func _move_settings_to_project_settings() -> Completion:
	var old_settings_file := PopochiuMigrationHelper.old_settings_file
	
	if not FileAccess.file_exists(old_settings_file):
		return Completion.IGNORED
	
	# Move custom defined values in the old [popochiu_settings.tres] file to Project Settings
	var old_settings: PopochiuSettings = load(old_settings_file)
	var settings_map := {
		# ---- GUI ---------------------------------------------------------------------------------
		"SCALE_GUI": "",
		"FADE_COLOR": "",
		"SKIP_CUTSCENE_TIME": "",
		# ---- Dialogs -----------------------------------------------------------------------------
		"TEXT_SPEED": old_settings.text_speeds[old_settings.default_text_speed],
		"AUTO_CONTINUE_TEXT": "",
		"USE_TRANSLATIONS": "",
		# ---- Inventory ---------------------------------------------------------------------------
		"INVENTORY_LIMIT": "",
		# ---- Pixel game --------------------------------------------------------------------------
		"PIXEL_ART_TEXTURES": "is_pixel_art_game",
		"PIXEL_PERFECT": "is_pixel_perfect",
	}
	
	for key: String in settings_map:
		PopochiuConfig.set_project_setting(
			key,
			old_settings[key.to_lower()] if key.is_empty() else settings_map[key]
		)
	
	for item_name: StringName in old_settings.items_on_start:
		var items_on_start := PopochiuConfig.get_inventory_items_on_start()
		items_on_start.append(str(item_name))
		PopochiuConfig.set_inventory_items_on_start(items_on_start)
	
	# Move custom defined values in the old [popochiu_settings.tres] to their corresponding GUI
	# components
	if FileAccess.file_exists(GAME_INVENTORY_BAR_PATH):
		var inventory_bar: Control = load(GAME_INVENTORY_BAR_PATH).instantiate()
		inventory_bar.always_visible = old_settings.inventory_always_visible
		PopochiuEditorHelper.pack_scene(inventory_bar)
	
	if FileAccess.file_exists(GAME_SETTINGS_BAR_PATH):
		var settings_bar: PanelContainer = load(GAME_SETTINGS_BAR_PATH).instantiate()
		settings_bar.always_visible = old_settings.toolbar_always_visible
		PopochiuEditorHelper.pack_scene(settings_bar)
	
	# Remove the old [popochiu_settings.tres]
	if DirAccess.remove_absolute(old_settings_file) != OK:
		PopochiuUtils.print_error("Couldn't delete [code]%s[/code]." % old_settings_file)
		return Completion.FAILED
	
	return Completion.DONE


func _update_dialog_menu() -> Completion:
	if (
		not FileAccess.file_exists(GAME_DIALOG_MENU_PATH)
		or DirAccess.dir_exists_absolute(GAME_DIALOG_MENU_OPTION_PATH)
	):
		# The game's GUI is not using the DialogMenu GUI component or is already using its beta-3
		# version
		return Completion.IGNORED
	
	# Copy the new [PopochiuDialogMenuOption] component to the game's GUI components folder
	await _gui_templates_helper.copy_components(ADDON_DIALOG_MENU_PATH)
	
	# Store the scene of the new [PopochiuDialogMenuOption] in the game's graphic interface folder
	var game_dialog_menu_option: PackedScene = load(PopochiuResources.GUI_GAME_FOLDER.path_join(
		"components/dialog_menu/dialog_menu_option/dialog_menu_option.tscn"
	))
	
	# Assign the new [PopochiuDialogMenuOption] to the game's GUI dialog menu component and delete
	# any option inside its DialogOptionsContainer child
	var game_dialog_menu: PopochiuDialogMenu = load(GAME_DIALOG_MENU_PATH).instantiate()
	game_dialog_menu.option_scene = game_dialog_menu_option
	for opt in game_dialog_menu.get_node("ScrollContainer/DialogOptionsContainer").get_children():
		opt.owner = null
		opt.free()
	
	var done := PopochiuEditorHelper.pack_scene(game_dialog_menu)
	if done != OK:
		PopochiuUtils.print_error(
			"Couldn't update PopochiuDialogMenuOption reference in PopochiuDialogMenu"
		)
		return Completion.FAILED
	
	# Update the dependency to [PopochiuDialogMenuOption] in the game's graphic interface scene
	var game_gui: PopochiuGraphicInterface = load(PopochiuResources.GUI_GAME_SCENE).instantiate()
	game_gui.get_node("DialogMenu").option_scene = game_dialog_menu_option
	done = PopochiuEditorHelper.pack_scene(game_gui)
	if done != OK:
		PopochiuUtils.print_error(
			"Couldn't update PopochiuDialogMenuOption reference in PopochiuGraphicInterface"
		)
		return Completion.FAILED
	
	# Delete the old [dialog_menu_option.tscn] file
	done = DirAccess.remove_absolute(
		"res://game/graphic_interface/components/dialog_menu/dialog_menu_option.tscn"
	)
	if done != OK:
		PopochiuUtils.print_error(
			"Couldn't update PopochiuDialogMenuOption reference in PopochiuDialogMenu"
		)
		return Completion.FAILED
	
	return Completion.DONE


func _update_simple_click_settings_bar() -> Completion:
	if not FileAccess.file_exists(GAME_SETTINGS_BAR_PATH):
		# The game's GUI does not use the SettingsBar GUI component
		return Completion.IGNORED
	
	var game_settings_bar: PanelContainer = load(GAME_SETTINGS_BAR_PATH).instantiate()
	var dialog_speed_button: TextureButton = game_settings_bar.get_node("Box/BtnDialogSpeed")
	
	if not dialog_speed_button.speed_options.is_empty():
		# The component is up to date with the beta-3 version
		return Completion.IGNORED
	
	var addons_settings_bar: PanelContainer = load(PopochiuResources.GUI_TEMPLATES_FOLDER.path_join(
		"simple_click/components/settings_bar/settings_bar.tscn"
	)).instantiate()
	
	# Store the speed options defined in the original component
	var speed_options := []
	for opt: TextSpeedOption in addons_settings_bar.get_node("Box/BtnDialogSpeed").speed_options:
		var option := TextSpeedOption.new()
		option.resource_name = opt.resource_name
		option.speed = opt.speed
		option.description = opt.description
		option.icon = load(opt.icon.resource_path.replace(
			PopochiuResources.GUI_TEMPLATES_FOLDER.path_join(
				"simple_click/components/settings_bar/sprites/"
			),
			"res://game/graphic_interface/components/settings_bar/sprites/"
		))
		
		speed_options.append(option)
	
	# Assign the options to the component in the game's graphic interface component and save the
	# SettingsBat scene
	dialog_speed_button.speed_options = speed_options
	var scene_updated := PopochiuEditorHelper.pack_scene(game_settings_bar)
	
	return Completion.DONE if scene_updated == OK else Completion.FAILED


func _remove_helper_nodes() -> Completion:
	var characters_paths := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.CHARACTERS_PATH,
		["tscn"]
	)
	var props_and_hotspots_paths :=\
	PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.ROOMS_PATH,
		["tscn"],
		["markers", "regions", "walkable_areas"]
	).filter(
		func (file_path: String) -> bool:
			return not "room_" in file_path
	)
	var popochiu_clickables := characters_paths + props_and_hotspots_paths
	var any_updated := PopochiuUtils.any_exhaustive(popochiu_clickables, _remove_helper_nodes_in)
	
	return Completion.DONE if any_updated else Completion.IGNORED


func _remove_helper_nodes_in(scene_path: String) -> bool:
	# Load the scene ignoring cache so changes made in previous steps are taken into account
	var popochiu_clickable: PopochiuClickable = (
		ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	
	var was_scene_updated := false
	
	# ---- Remove the BaselineHelper and WalkToHelper nodes ----------------------------------------
	if _remove_node(popochiu_clickable, "BaselineHelper"):
		was_scene_updated = true
	
	if _remove_node(popochiu_clickable, "WalkToHelper"):
		was_scene_updated = true
	
	# ---- Remove the DialogPos node ---------------------------------------------------------------
	# TODO: Uncomment this once PR #241 is merged
	if popochiu_clickable is PopochiuCharacter and popochiu_clickable.has_node("DialogPos"):
		popochiu_clickable.dialog_pos = popochiu_clickable.get_node("DialogPos").position
		_remove_node(popochiu_clickable, "DialogPos")
		was_scene_updated = true
	
	if was_scene_updated and PopochiuEditorHelper.pack_scene(popochiu_clickable, scene_path) != OK:
			PopochiuUtils.print_error(
				"Couldn't remove helper nodes in [b]%s[/b]." % popochiu_clickable.script_name
			)
	
	return was_scene_updated


func _remove_node(parent: Node, node_path: NodePath) -> bool:
	if parent.has_node(node_path):
		var child: Node = parent.get_node(node_path)
		child.owner = null
		child.free()
		return true
	return false


## Replace calls to deprecated properties and methods:
## - [code]E.current_room[/code] by [code]R.current[/code].
func _replace_deprecated() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = "E.current_room", to = "R.current"},
		{from = "E.goto_room(", to = "R.goto_room("},
		{from = "E.queue_camera_offset(", to = "E.camera.queue_change_offset("},
		{from = "E.camera_offset(", to = "E.camera.change_offset("},
		{from = "E.queue_camera_shake(", to = "E.camera.queue_shake("},
		{from = "E.camera_shake(", to = "E.camera.shake("},
		{from = "E.queue_camera_shake_bg(", to = "E.camera.queue_shake_bg("},
		{from = "E.camera_shake_bg(", to = "E.camera.shake_bg("},
		{from = "E.queue_camera_zoom(", to = "E.camera.queue_change_zoom("},
		{from = "E.camera_zoom(", to = "E.camera.change_zoom("},
		{from = "E.stop_camera_shake()", to = "E.camera.stop_shake()"},
		# autoloads
		{from = "return super.get_runtime_room(", to = "return get_runtime_room("},
		{from = "return super.get_runtime_character(", to = "return get_runtime_character("},
		{from = "return super.get_item_instance(", to = "return get_item_instance("},
		{from = "return E.get_dialog(", to = "return get_instance("},
	]) else Completion.IGNORED


#endregion
