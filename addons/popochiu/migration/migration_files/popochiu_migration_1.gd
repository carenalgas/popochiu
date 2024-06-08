@tool
class_name PopochiuMigration1
extends PopochiuMigration
## Migrates the popochiu 1.x project structure to the new popochiu 2.x project structure, which
## changed in popochiu 2.0 beta 1.
##
## This migration does the following:
## - move files/folders from "res://popochiu" to "res://game"
## - rename files/folders to snake case
## - update the "res://game/popochiu_data.cfg" file references
## - update the *.tres file references
## - update the godot project file to have correct reference for the default scene
## - add the [migration] section and version key to the "res://game/popochiu_data.cfg" file

const VERSION = 1
const DESCRIPTION = "Migrate project structure to Popochiu 2.0 format"
const STEPS = [
	"Delete [b]res://popochiu/autoloads/[/b].",
	"Move folders in [b]res://popochiu/[/b] to [b]res://game/[/b].",
	"Rename all to snake_case.",
	"Select the default GUI template (OPTIONAL).",
	"Update paths in [b]res://game/popochiu_data.cfg[/b].",
	"Rename [b]res://popochiu/[/b] references to [b]res://game/[/b].",
	"Rename inventory item files from [b]item_xxx[/b] to [b]inventory_item_xxx[/b].",
	"Update assignation of voices in [b]PopochiuCharacter[/b].",
	"Update external scenes and assign scripts that didn't exist before.",
	"Replace deprecated method calls.",
]
const RESET_CHILDREN_OWNER = "reset_children_owner"
const PopochiuGuiTemplatesHelper = preload(
	"res://addons/popochiu/editor/helpers/popochiu_gui_templates_helper.gd"
)

var _room_scene_path_template := PopochiuResources.ROOMS_PATH.path_join("%s/room_%s.tscn")


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	# Only perform conversion if both the PopochiuMigrationHelper.POPOCHIU_PATH and
	# PopochiuResources.GAME_PATH directories exist
	if (
		DirAccess.dir_exists_absolute(PopochiuMigrationHelper.POPOCHIU_PATH)
		and DirAccess.dir_exists_absolute(PopochiuResources.GAME_PATH)
	):
		# No need to move the autoloads directory as Popochiu 2 creates them automatically. This
		# will also fix the issue related with using [preload()] in old [A] autoload.
		_print_step(0)
		if not _delete_popochiu_folder_autoloads():
			return false
		completed.append(0)
		
		_print_step(1)
		if not _move_game_data():
			return false
		completed.append(1)
		
		_print_step(2)
		_rename_data_to_snake_case()
		completed.append(2)
		
		if PopochiuResources.get_data_value("ui", "template", "").is_empty():
			_print_step(3)
			await _select_gui_template()
				
			completed.append(3)
		
		_print_step(4)
		PopochiuMigrationHelper.rebuild_popochiu_data_file()
		completed.append(4)
		
		_print_step(5)
		_rename_game_folder_references()
		completed.append(5)
		
		_print_step(6)
		_rename_inventory_item_filenames()
		completed.append(6)
		
		_print_step(7)
		_update_characters_voices()
		completed.append(7)
		
		_print_step(8)
		await _update_external_scenes_and_missing_scripts()
		completed.append(8)
		
		_print_step(9)
		_replace_deprecated_method_calls()
		completed.append(9)
		
		return true
	else:
		PopochiuUtils.print_error(
			"Both the %s and %s folders must exist. Make sure that the Popochiu plugin is enabled" \
			+ " and that there is Popochiu 1.x data to convert." % [
			PopochiuMigrationHelper.POPOCHIU_PATH, PopochiuResources.GAME_PATH
		])
		return false


#endregion

#region Private ####################################################################################
## Delete the POPOCHIU_PATH autoloads directory if it exists
func _delete_popochiu_folder_autoloads() -> bool:
	var all_done := false
	var autoloads_path := PopochiuMigrationHelper.POPOCHIU_PATH.path_join("Autoloads")
	
	if DirAccess.dir_exists_absolute(autoloads_path):
		all_done = PopochiuMigrationHelper.delete_folder_and_contents(autoloads_path)
	elif DirAccess.dir_exists_absolute(autoloads_path.to_lower()):
		all_done = PopochiuMigrationHelper.delete_folder_and_contents(autoloads_path.to_lower())
	
	return all_done


## Moves game data from PopochiuMigrationHelper.POPOCHIU_PATH to PopochiuResources.GAME_PATH
func _move_game_data() -> bool:
	var folders := DirAccess.get_directories_at(PopochiuMigrationHelper.POPOCHIU_PATH)
	var files := DirAccess.get_files_at(PopochiuMigrationHelper.POPOCHIU_PATH)
	
	# Move files from PopochiuMigrationHelper.POPOCHIU_PATH to PopochiuResources.GAME_PATH
	for file in files:
		var src := PopochiuMigrationHelper.POPOCHIU_PATH.path_join(file)
		var dest := PopochiuResources.GAME_PATH.path_join(file.to_snake_case())
		
		var err := DirAccess.rename_absolute(src, dest)
		if err != OK:
			PopochiuUtils.print_error("Couldn't move %s to %s: %d" % [src, dest, err])
			return false
	
	# Move folders from PopochiuMigrationHelper.POPOCHIU_PATH to PopochiuResources.GAME_PATH
	for folder in folders:
		var src := PopochiuMigrationHelper.POPOCHIU_PATH.path_join(folder)
		var dest := PopochiuResources.GAME_PATH.path_join(folder.to_snake_case())
		
		DirAccess.remove_absolute(dest)
		
		var err := DirAccess.rename_absolute(src, dest)
		if err != OK:
			PopochiuUtils.print_error("Couldn't move %s to %s: %d" % [src, dest, err])
			return false
	
	# All files/folders moved to PopochiuResources.GAME_PATH so delete the
	# PopochiuMigrationHelper.POPOCHIU_PATH directory
	return DirAccess.remove_absolute(PopochiuMigrationHelper.POPOCHIU_PATH) == OK


## Rename PopochiuResources.GAME_PATH files and folders to snake case
func _rename_data_to_snake_case():
	for folder: String in PopochiuMigrationHelper.get_absolute_directory_paths_at(
		PopochiuResources.GAME_PATH
	):
		_rename_files_to_snake_case(folder)
		_rename_folders_to_snake_case(folder)


## Rename [param folder_path] files to snake_case
func _rename_files_to_snake_case(folder_path: String) -> void:
	for file: String in DirAccess.get_files_at(folder_path):
		var src := folder_path.path_join(file)
		var dest := folder_path.path_join(file.to_snake_case())
		DirAccess.rename_absolute(src, dest)


## Rename [param path] folders and the content in the folders recursively to snake_case
func _rename_folders_to_snake_case(path: String) -> void:
	for sub_folder: String in PopochiuMigrationHelper.get_absolute_directory_paths_at(path):
		_rename_files_to_snake_case(sub_folder)
		DirAccess.rename_absolute(sub_folder, sub_folder.to_snake_case())
		# recursively rename files/folders to snake_case
		_rename_folders_to_snake_case(sub_folder.to_snake_case())


func _select_gui_template() -> void:
	# Assume the project is from Popochiu 1.x or Popochiu 2 - Alpha X and assign the SimpleCick
	# GUI template
	await PopochiuGuiTemplatesHelper.copy_gui_template(
		"SimpleClick",
		func (_progress: int, _msg: String) -> void: return,
		func () -> void: return,
	)


## Renames uses of [b]res://popochiu/[/b] to [b]res://game/[/b] in .tscn, .tres, and .gd files.
func _rename_game_folder_references() -> void:
	# Update the path to the main scene in Project Settings
	var main_scene_path := ProjectSettings.get_setting(PopochiuResources.MAIN_SCENE, "")
	
	if PopochiuMigrationHelper.POPOCHIU_PATH in main_scene_path:
		ProjectSettings.set_setting(PopochiuResources.MAIN_SCENE, main_scene_path.replace(
			PopochiuMigrationHelper.POPOCHIU_PATH, PopochiuResources.GAME_PATH
		))
		ProjectSettings.save()
	
	# Go over gd, tscn, and tres files to update their references to res://popochiu/ by res://game/
	var files := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.GAME_PATH, ["gd", "tscn", "tres", "cfg"], ["autoloads"]
	)
	
	PopochiuMigrationHelper.replace_text_in_files(
		Array(files), PopochiuMigrationHelper.POPOCHIU_PATH, PopochiuResources.GAME_PATH
	)


func _rename_inventory_item_filenames() -> void:
	var inventory_items_folders := PopochiuMigrationHelper.get_absolute_directory_paths_at(
		PopochiuResources.INVENTORY_ITEMS_PATH
	)
	
	# Get all the inventory item file paths that were previously called item_*.*
	var files_by_folder := Array(inventory_items_folders).map(
		func (folder_path: String) -> Array:
			return Array(PopochiuMigrationHelper.get_absolute_file_paths_at(folder_path)).filter(
				func (file_path: String) -> bool:
					return "/item_" in file_path
			)
	)
	
	# Rename the files to inventory_item_*.* and update the internal paths to match the new path
	files_by_folder.all(
		func (file_paths: Array) -> bool:
			var old_file_name := (file_paths[0] as String).get_file().get_basename()
			var new_file_name := old_file_name.replace("item_", "inventory_item_")
			PopochiuMigrationHelper.replace_text_in_files(file_paths, old_file_name, new_file_name)
			
			for path: String in file_paths:
				DirAccess.rename_absolute(path, path.replace("/item_", "/inventory_item_"))
			
			return true
	)


func _update_characters_voices() -> void:
	# Get the characters' .tscn files
	var file_paths := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.CHARACTERS_PATH,
		["tscn"]
	)
	
	Array(file_paths).all(_load_character_voices)


func _load_character_voices(scene_path: String) -> bool:
	var popochiu_character: PopochiuCharacter = (load(scene_path) as PackedScene).instantiate()
	var voices: Array = PopochiuResources.get_data_value("audio", "vo_cues", [])
	
	popochiu_character.voices = popochiu_character.voices.map(
		func (emotion_dic: Dictionary) -> Dictionary:
			var arr: Array[AudioCueSound] = []
			var new_emotion_dic := {
				emotion = emotion_dic.emotion,
				variations = arr
			}
			
			for num: int in emotion_dic.variations:
				var cue_name := "%s_%s" % [emotion_dic.cue, str(num + 1).pad_zeros(2)]
				var cue_path: String = voices.filter(
					func (cue_path: String) -> bool:
						return cue_name in cue_path
				)[0]
				
				var popochiu_audio_cue: AudioCueSound = load(cue_path)
				new_emotion_dic.variations.append(popochiu_audio_cue)
			
			return new_emotion_dic
	)
	
	if PopochiuEditorHelper.pack_scene(popochiu_character, scene_path) != OK:
		PopochiuUtils.print_error(
			"Couldn't update [b]%s[/b] with new voices array." % popochiu_character.script_name
		)
		return false
	return true


## Update external scenes and assign missing scripts for each prop, hotspot, region, and walkable area
## that didn't exist prior [i]beta 1[/i].
func _update_external_scenes_and_missing_scripts() -> bool:
	var room_scene_paths := PopochiuResources.get_section_keys("rooms").map(
		func (room_name: String) -> PopochiuRoom:
			var scene_path := _room_scene_path_template.replace("%s", room_name.to_snake_case())
			return (load(scene_path) as PackedScene).instantiate()
	)
	return room_scene_paths.all(_update_room)


## Update the children of the different groups in [param popochiu_room] so the use instances of the
## new objects: [PopochiuProp], [PopochiuHotspot], [PopochiuRegion], and [PopochiuWalkableArea].
func _update_room(popochiu_room: PopochiuRoom) -> bool:
	var room_objects_to_add := []
	[
		PopochiuPropFactory.new(),
		PopochiuHotspotFactory.new(),
		PopochiuRegionFactory.new(),
		PopochiuWalkableAreaFactory.new(),
		# TODO: Include Position2D to update them to Marker2D
	].all(_create_new_obj.bind(popochiu_room, room_objects_to_add))
	
	for group: Dictionary in room_objects_to_add:
		group.objects.all(
			func (new_obj) -> bool:
				# Add the new instance to the room and do the same for its children (those that
				# were marked as PopochiuRoomObjFactory.CHILD_VISIBLE_IN_ROOM_META)
				popochiu_room.get_node(group.factory.get_group()).add_child(new_obj)
				new_obj.owner = popochiu_room
				
				for child: Node in new_obj.get_meta(RESET_CHILDREN_OWNER):
					child.owner = popochiu_room
				new_obj.remove_meta(RESET_CHILDREN_OWNER)
				
				return true
		)
	
	if PopochiuEditorHelper.pack_scene(popochiu_room) != OK:
		PopochiuUtils.print_error(
			"Migration 1: Couldn't update [b]%s[/b]." % popochiu_room.script_name
		)
		return false
	
	popochiu_room.free()
	return true


## Create a new scene of the [param factory] type. The scene will be placed in its corresponding
## folder inside the [param popochiu_room] folder. Created [Node]s will be stored in
## [param room_objects_to_add] so they are added to the room later.
func _create_new_obj(
	factory: PopochiuRoomObjFactory, popochiu_room: PopochiuRoom, room_objects_to_add := []
) -> bool:
	var group := {
		factory = factory,
		objects = []
	}
	for obj in popochiu_room.get_node(factory.get_group()).get_children():
		# Copy the points of the polygon to use as [PopochiuClickable.interaction_polygon]
		if obj is PopochiuProp or obj is PopochiuHotspot:
			var polygon: PackedVector2Array = obj.get_node("InteractionPolygon").polygon
			
			if obj.has_node("InteractionPolygon2"):
				polygon = obj.get_node("InteractionPolygon2").polygon
			
			obj.interaction_polygon = polygon
		
		# Create the new scene (and script if needed) of the [obj]
		var obj_factory: PopochiuRoomObjFactory = factory.get_new_instance()
		if obj_factory.create_from(obj, popochiu_room) != ResultCodes.SUCCESS:
			return false
		
		# Map the properties of the [obj] to its new instance
		group.objects.append(_create_new_room_obj(obj_factory, obj, popochiu_room))
		
		# Remove the old [obj] from the room
		obj.free()
	
	room_objects_to_add.append(group)
	return true


## Maps the properties (and nodes if needed) of [param source] to a new instance of itself created
## from [param obj_factory]. This assures that objects coming from versions prior to [i]beta 1[/i]
## will have the corresponding structure of new Popochiu versions.
func _create_new_room_obj(
	obj_factory: PopochiuRoomObjFactory, source: Node, room: PopochiuRoom
) -> Node:
	var new_obj: Node = (load(obj_factory.get_scene_path()) as PackedScene).instantiate()
	new_obj.set_meta(RESET_CHILDREN_OWNER, [])
	
	if new_obj is PopochiuProp or new_obj is PopochiuHotspot:
		new_obj.baseline = source.baseline
		new_obj.walk_to_point = source.walk_to_point
	
	if new_obj is PopochiuProp:
		new_obj.texture = source.texture
		new_obj.frames = source.frames
		new_obj.v_frames = source.v_frames
		new_obj.link_to_item = source.link_to_item
	
	if new_obj is PopochiuRegion:
		var interaction_polygon := source.get_node("InteractionPolygon")
		interaction_polygon.owner = null
		interaction_polygon.reparent(new_obj, false)
		new_obj.get_meta(RESET_CHILDREN_OWNER).append(interaction_polygon)
	
	if new_obj is PopochiuWalkableArea:
		var perimeter: NavigationRegion2D = source.get_node("Perimeter")
		perimeter.navigation_polygon.agent_radius = 0.0
		perimeter.owner = null
		perimeter.reparent(new_obj, false)
		new_obj.get_meta(RESET_CHILDREN_OWNER).append(perimeter)
	
	new_obj.position = source.position
	return new_obj


## Replace calls to old methods:
## - [code]R.get_point[/code] by [code]R.get_marker[/code].
## - [code]G.display[/code] to [code]G.show_system_text[/code].
## - Methods with [code]_now[/code] suffix.
## - [code]super.on_click() | super.on_right_click() | super.on_item_used(item)[/code] by
## [code]E.command_fallback()[/code]
func _replace_deprecated_method_calls() -> void:
	var scripts_paths := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.GAME_PATH, ["gd"]
	)
	
	for dic: Dictionary in [
		{from = "R.get_point", to = "R.get_marker"},
		{from = "G.display", to = "G.show_system_text"},
		{from = "disable_now()", to = "disable()"},
		{from = "enable_now()", to = "enable()"},
		{from = "change_frame_now(", to = "change_frame("},
		{from = "super.on_click()", to = "E.command_fallback()"},
		{from = "super.on_right_click()", to = "E.command_fallback()"},
		{from = "super.on_item_used(item)", to = "E.command_fallback()"},
	]:
		PopochiuMigrationHelper.replace_text_in_files(Array(scripts_paths), dic.from, dic.to)


#endregion
