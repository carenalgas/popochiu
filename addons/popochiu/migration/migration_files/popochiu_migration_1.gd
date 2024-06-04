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
	"Assign script to all PopochiuProps and fix possible scene ref issues (alpha 1).",
	"Update PopochiuWalkableArea's Perimeter [b]agent_radius[/b] to 0",
	"Replace calls to [b]R.get_point[/b] by [b]R.get_marker[/b]",
	"Replace calls to [b]G.display[/b] to [b]G.show_system_text[/b].",
	"Replace calls to methods with [b]_now[/b] suffix.",
]
const PopochiuGuiTemplatesHelper = preload(
	"res://addons/popochiu/editor/helpers/popochiu_gui_templates_helper.gd"
)

var _room_scene_path_template := PopochiuResources.ROOMS_PATH.path_join("%s/room_%s.tscn")
var _prop_file_template := "%s/props/&p/prop_&p"


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
		await PopochiuEditorHelper.wait(0.1)
		_assign_prop_script_and_fix_scene_ref()
		completed.append(8)
		
		#"Update PopochiuWalkableArea's Perimeter [b]agent_radius[/b] to 0",
		#"Replace calls to [b]R.get_point[/b] by [b]R.get_marker[/b]",
		#"Replace calls to [b]G.display[/b] to [b]G.show_system_text[/b].",
		#"Replace calls to methods with [b]_now[/b] suffix.",
		
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
	
	# Go over gd, tscn, and tres files to update their references to res://popochiu/ by res://game/
	var files := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.GAME_PATH, ["gd", "tscn", "tres", "cfg"], ["autoloads"]
	)
	
	PopochiuMigrationHelper.replace_path_reference(
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
			PopochiuMigrationHelper.replace_path_reference(file_paths, old_file_name, new_file_name)
			
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


func _assign_prop_script_and_fix_scene_ref() -> bool:
	var room_scene_paths := PopochiuResources.get_section_keys("rooms").map(
		func (room_name: String) -> PopochiuRoom:
			var scene_path := _room_scene_path_template.replace("%s", room_name.to_snake_case())
			return (load(scene_path) as PackedScene).instantiate()
	)
	
	return room_scene_paths.all(_update_room)


func _update_room(popochiu_room: PopochiuRoom) -> bool:
	# Update PopochiuWalkableArea's Perimeter [agent_radius] to 0
	for wa: PopochiuWalkableArea in popochiu_room.get_node("WalkableAreas").get_children():
		(wa.get_child(0) as NavigationRegion2D).navigation_polygon.agent_radius = 0.0
	
	# Assign script to all PopochiuProps and fix scene ref issues
	var props_to_add := []
	for prop: PopochiuProp in popochiu_room.get_node("Props").get_children():
		prints("@@@", prop.script_name)
		var prop_file_path := (_prop_file_template % 
			popochiu_room.scene_file_path.get_base_dir()
		).replace("&p", prop.script_name.to_snake_case())
		var prop_scene_path := prop_file_path + ".tscn"
		var new_prop: PopochiuProp = (load(prop_scene_path) as PackedScene).instantiate()
		
		if prop.clickable:
			prints(">>>>>>>>", prop.get_child(0))
			new_prop.interaction_polygon = prop.get_child(0).polygon
		else:
			var prop_script: Script = load(
				"res://addons/popochiu/engine/templates/prop_template.gd"
			).duplicate()
			var prop_script_path := prop_file_path + ".gd"
			
			if ResourceSaver.save(prop_script, prop_script_path) != OK:
				PopochiuUtils.print_error("Could not create [b]%s[/b] script: %s" % [
					new_prop.script_name, prop_script_path
				])
				return false
			
			new_prop.set_script(load(prop_script_path))
		
		if prop.script_name.to_lower() in ["bg", "background"]:
			new_prop.z_index = -1
		
		new_prop.name = prop.name
		new_prop.texture = prop.texture
		new_prop.frames = prop.frames
		new_prop.v_frames = prop.v_frames
		new_prop.link_to_item = prop.link_to_item
		new_prop.position = prop.position
		props_to_add.append(new_prop)
		
		prop.free()
	
	prints("---")
	for new_prop: PopochiuProp in props_to_add:
		popochiu_room.get_node("Props").add_child(new_prop)
		new_prop.owner = popochiu_room
	
	if PopochiuEditorHelper.pack_scene(popochiu_room) != OK:
		PopochiuUtils.print_error(
			"Migration 1: Couldn't update [b]%s[/b]." % popochiu_room.script_name
		)
		return false
	
	popochiu_room.free()
	return true


#endregion
