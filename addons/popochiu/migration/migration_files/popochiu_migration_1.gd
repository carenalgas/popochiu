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
	"Select the default GUI template.",
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
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_delete_popochiu_folder_autoloads,
			_move_game_data,
			_rename_data_to_snake_case,
			_select_gui_template,
			_rebuild_popochiu_data_file,
			_rename_game_folder_references,
			_update_inventory_items,
			_update_characters,
			_update_external_scenes_and_missing_scripts,
			_replace_deprecated_method_calls,
		]
	)


#endregion

#region Private ####################################################################################
## Checks if the folder where the game is stored is the one used since Beta 1. This means the
## [code]res://popochiu/[/code] folder doesn't exists in the project
func _ignore_popochiu_folder_step() -> bool:
	return PopochiuMigrationHelper.get_game_path() == PopochiuResources.GAME_PATH


## Delete the POPOCHIU_PATH autoloads directory if it exists
func _delete_popochiu_folder_autoloads() -> Completion:
	if _ignore_popochiu_folder_step():
		return Completion.IGNORED
	
	# No need to move the autoloads directory as Popochiu 2 creates them automatically. This will
	# also fix the issue related with using [preload()] in old [A] autoload.
	var all_done := false
	var autoloads_path := PopochiuMigrationHelper.POPOCHIU_PATH.path_join("Autoloads")
	
	if DirAccess.dir_exists_absolute(autoloads_path):
		all_done = PopochiuMigrationHelper.delete_folder_and_contents(autoloads_path)
	elif DirAccess.dir_exists_absolute(autoloads_path.to_lower()):
		all_done = PopochiuMigrationHelper.delete_folder_and_contents(autoloads_path.to_lower())
	
	return Completion.DONE if all_done else Completion.FAILED


## Moves game data from PopochiuMigrationHelper.POPOCHIU_PATH to PopochiuResources.GAME_PATH
func _move_game_data() -> Completion:
	if _ignore_popochiu_folder_step():
		return Completion.IGNORED
	
	var folders := DirAccess.get_directories_at(PopochiuMigrationHelper.POPOCHIU_PATH)
	var files := DirAccess.get_files_at(PopochiuMigrationHelper.POPOCHIU_PATH)
	
	# Move files from PopochiuMigrationHelper.POPOCHIU_PATH to PopochiuResources.GAME_PATH
	for file in files:
		var src := PopochiuMigrationHelper.POPOCHIU_PATH.path_join(file)
		var dest := PopochiuResources.GAME_PATH.path_join(file.to_snake_case())
		
		var err := DirAccess.rename_absolute(src, dest)
		if err != OK:
			PopochiuUtils.print_error("Couldn't move %s to %s: %d" % [src, dest, err])
			return Completion.FAILED
	
	# Move folders from PopochiuMigrationHelper.POPOCHIU_PATH to PopochiuResources.GAME_PATH
	for folder in folders:
		var src := PopochiuMigrationHelper.POPOCHIU_PATH.path_join(folder)
		var dest := PopochiuResources.GAME_PATH.path_join(folder.to_snake_case())
		
		DirAccess.remove_absolute(dest)
		
		var err := DirAccess.rename_absolute(src, dest)
		if err != OK:
			PopochiuUtils.print_error("Couldn't move %s to %s: %d" % [src, dest, err])
			return Completion.FAILED
	
	# All files/folders moved to PopochiuResources.GAME_PATH so delete the
	# PopochiuMigrationHelper.POPOCHIU_PATH directory
	return (
		Completion.DONE if DirAccess.remove_absolute(PopochiuMigrationHelper.POPOCHIU_PATH) == OK
		else Completion.FAILED
	)


## Rename PopochiuResources.GAME_PATH files and folders to snake case
func _rename_data_to_snake_case() -> Completion:
	var any_renamed := Array(
		PopochiuMigrationHelper.get_absolute_directory_paths_at(PopochiuResources.GAME_PATH)
	).any(
		func (folder: String) -> bool:
			var any_file_renamed := _rename_files_to_snake_case(folder)
			var any_folder_renamed := _rename_folders_to_snake_case(folder)
			
			return any_file_renamed or any_folder_renamed
	)
	
	return Completion.DONE if any_renamed else Completion.IGNORED


## Rename [param folder_path] files to snake_case
func _rename_files_to_snake_case(folder_path: String) -> bool:
	return Array(DirAccess.get_files_at(folder_path)).any(
		func (file: String) -> bool:
			var src := folder_path.path_join(file)
			var dest := folder_path.path_join(file.to_snake_case())
			
			if src != dest:
				DirAccess.rename_absolute(src, dest)
				return true
			return false
	)


## Rename [param path] folders and the content in the folders recursively to snake_case
func _rename_folders_to_snake_case(path: String) -> bool:
	return Array(PopochiuMigrationHelper.get_absolute_directory_paths_at(path)).any(
		func (sub_folder: String) -> bool:
			var any_file_renamed := _rename_files_to_snake_case(sub_folder)
			var snake_case_name := sub_folder.to_snake_case()
			var folder_renamed := sub_folder != snake_case_name
			
			if folder_renamed:
				DirAccess.rename_absolute(sub_folder, snake_case_name)
				# recursively rename files/folders to snake_case
				_rename_folders_to_snake_case(snake_case_name)
				folder_renamed = true
			
			return any_file_renamed or folder_renamed
	)


## Copies the 2-click Context-sensitive GUI to [code]res://game/graphic_interface/[/code] if there
## is no GUI template selected.
func _select_gui_template() -> Completion:
	if PopochiuResources.get_data_value("ui", "template", "").is_empty():
		# Assume the project is from Popochiu 1.x or Popochiu 2 - Alpha X and assign the SimpleCick
		# GUI template
		await PopochiuGuiTemplatesHelper.copy_gui_template(
			"SimpleClick",
			func (_progress: int, _msg: String) -> void: return,
			func () -> void: return,
		)
		return Completion.DONE
	else:
		await PopochiuEditorHelper.wait_process_frame()
		return Completion.IGNORED


## Updates the paths to rooms, characters, inventory items and dialogs so they point to
## [code]res://game/[/code] (for cases where the project still used [code]res://popochiu/[/code]).
func _rebuild_popochiu_data_file() -> bool:
	if PopochiuMigrationHelper.is_text_in_file(
		PopochiuMigrationHelper.POPOCHIU_PATH, PopochiuResources.DATA
	) == false:
		return Completion.IGNORED
	
	_rebuild_popochiu_data_section(PopochiuResources.GAME_PATH, "rooms")
	_rebuild_popochiu_data_section(PopochiuResources.GAME_PATH, "characters")
	_rebuild_popochiu_data_section(PopochiuResources.GAME_PATH, "inventory_items")
	_rebuild_popochiu_data_section(PopochiuResources.GAME_PATH, "dialogs")
	
	return (
		Completion.DONE if PopochiuResources.set_data_value("setup", "done", true) == OK
		else Completion.FAILED
	)


## Updates the path to [param game_path] for each value in the [param data_section] in the
## [code]popochiu_data.cfg[/code] ([ConfigFile]) file.
func _rebuild_popochiu_data_section(game_path: String, data_section: String) -> void:
	var data_path := game_path.path_join(data_section)
	var section_name := data_section
	
	# Make sure the section name does not have an "s" character at the end
	if section_name.length() > 0 and section_name[-1] == "s":
		section_name = section_name.rstrip("s")
	
	# Add the keys and tres files for each directory in the data section
	for folder: String in DirAccess.get_directories_at(data_path):
		var key_name := folder.to_pascal_case()
		var tres_file := "%s_%s.tres" % [section_name, folder]
		var key_value := game_path.path_join("%s/%s/%s" % [data_section, folder, tres_file])
		
		PopochiuResources.set_data_value(data_section, key_name, key_value)


## Renames uses of [b]res://popochiu/[/b] to [b]res://game/[/b] in .tscn, .tres, and .gd files.
func _rename_game_folder_references() -> Completion:
	var changes_done := false
	
	# Update the path to the main scene in Project Settings
	var main_scene_path := ProjectSettings.get_setting(PopochiuResources.MAIN_SCENE, "")
	
	if PopochiuMigrationHelper.POPOCHIU_PATH in main_scene_path:
		changes_done = true
		ProjectSettings.set_setting(PopochiuResources.MAIN_SCENE, main_scene_path.replace(
			PopochiuMigrationHelper.POPOCHIU_PATH, PopochiuResources.GAME_PATH
		))
		ProjectSettings.save()
	
	# Go over gd, tscn, and tres files to update their references to res://popochiu/ by res://game/
	var files := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.GAME_PATH, ["gd", "tscn", "tres", "cfg"], ["autoloads"]
	)
	
	if PopochiuMigrationHelper.replace_text_in_files(
		Array(files), PopochiuMigrationHelper.POPOCHIU_PATH, PopochiuResources.GAME_PATH
	):
		changes_done = true
	
	return Completion.DONE if changes_done else Completion.IGNORED


## Updates all inventory items in the project so:[br]
## - Their file names (.tscn, .gd, and .tres) match the namig defined since beta-1 (inventory_item_*.*).
## - All the paths inside those files point to the new file.
## - Fixes a naming issue from alpha-1 where the root node name was set wrong. And also applies the
## [constant CanvasItem.TEXTURE_FILTER_NEAREST] to each node in case the project is marked as
## Pixel-art game.
func _update_inventory_items() -> Completion:
	var inventory_item_files := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.INVENTORY_ITEMS_PATH,
		["tscn", "gd", "tres"]
	)
	
	# Get all the inventory item file paths that were previously called item_*.*
	var scene_files := []
	var files_to_update := Array(inventory_item_files).filter(
		func (file_path: String) -> bool:
			if file_path.get_extension() == "tscn":
				scene_files.append(file_path)
			
			return "/item_" in file_path
	)
	
	if files_to_update.is_empty():
		return Completion.IGNORED
	
	return Completion.DONE if (
		scene_files.all(_update_root_name_and_texture_filter)
		and files_to_update.all(_rename_inventory_item_filenames)
	) else Completion.FAILED


## Loads the [PopochiuInventoryItem] in [param scene_file_path] and updates its root node name
## and makes its [member CanvasItem.texture_filter] to [constant CanvasItem.TEXTURE_FILTER_NEAREST]
## if this is a Pixel-art game.
func _update_root_name_and_texture_filter(scene_file_path: String) -> bool:
	# Update root node name to PascalCase
	var scene: PopochiuInventoryItem = (load(scene_file_path) as PackedScene).instantiate()
	scene.name = "Item%s" % scene.script_name.to_pascal_case()
	
	# Update the texture_filter if needed
	if PopochiuMigrationHelper.is_pixel_art_game():
		scene.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if PopochiuEditorHelper.pack_scene(scene, scene_file_path) != OK:
		PopochiuUtils.print_error(
			"Couldn't update root node name for inventory item: [b]%s[/b]" % scene.script_name
		)
		return false
	return true


## For each [PopochiuInventoryItem] in [param files_paths], updates the root node name to PascalCase,
## renames the files to inventory_item_*.*, and updates the internal paths to match the new path.
func _rename_inventory_item_filenames(file_path: String) -> bool:
	var old_file_name := file_path.get_file().get_basename()
	var new_file_name := old_file_name.replace("item_", "inventory_item_")
	PopochiuMigrationHelper.replace_text_in_files([file_path], old_file_name, new_file_name)
	DirAccess.rename_absolute(file_path, file_path.replace("/item_", "/inventory_item_"))
	return true


## For each [PopochiuCharacter] updates the way its voices are set to the structure defined in
## alpha-3. It also adds new required nodes like an [AnimationPlayer] and a [CollisionPolygon2D] for
## the [code]ScalingPolygon[/code].
func _update_characters() -> Completion:
	# Get the characters' .tscn files
	var file_paths := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.CHARACTERS_PATH,
		["tscn"]
	)
	var any_character_updated := Array(file_paths).any(_update_character)
	return Completion.DONE if any_character_updated else Completion.IGNORED


## Loads the [PopochiuCharacter] in [param scene_path] and:[br]
## - Updates its [member PopochiuCharacter.voices] so they match the structure defined in alpha-3.
## - Makes its [member CanvasItem.texture_filter] to [constant CanvasItem.TEXTURE_FILTER_NEAREST] if
## this is a Pixel-art game.
## - Adds [AnimationPlayer] and [CollisionPolygon2D] nodes if necessary.
func _update_character(scene_path: String) -> bool:
	var popochiu_character: PopochiuCharacter = (load(scene_path) as PackedScene).instantiate()
	var was_scene_updated := false
	
	# ---- Check if updating the voices [Dictionary] is needed -------------------------------------
	if not popochiu_character.voices.is_empty() and popochiu_character.voices[0].has("cue"):
		was_scene_updated = true
		var voices: Array = PopochiuResources.get_data_value("audio", "vo_cues", [])
		popochiu_character.voices = popochiu_character.voices.map(_map_voices.bind(voices))
	
	# ---- Update the texture_filter if needed -----------------------------------------------------
	if PopochiuMigrationHelper.is_pixel_art_game():
		was_scene_updated = true
		popochiu_character.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# ---- Add an [AnimationPlayer] node if needed -------------------------------------------------
	if not popochiu_character.has_node("AnimationPlayer"):
		was_scene_updated = true
		var animation_player := AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		popochiu_character.add_child(animation_player)
		animation_player.owner = popochiu_character
	
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
	
	if was_scene_updated and PopochiuEditorHelper.pack_scene(popochiu_character, scene_path) != OK:
		PopochiuUtils.print_error(
			"Couldn't update [b]%s[/b] with new voices array." % popochiu_character.script_name
		)
	
	return was_scene_updated


## Maps the data [param emotion_dic] to a new [Dictionary] with the new format defined for
## [member PopochiuCharacter.voices]. The [param voices] array is used to get the path to the
## [PopochiuAudioCue] file that should be used in each voice variation.
func _map_voices(emotion_dic: Dictionary, voices: Array) -> Dictionary:
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


## Update external prop scenes and assign missing scripts for each prop, hotspot, region, and
## walkable area that didn't exist prior [i]beta 1[/i].
func _update_external_scenes_and_missing_scripts() -> Completion:
	var room_scene_paths := PopochiuResources.get_section_keys("rooms").map(
		func (room_name: String) -> PopochiuRoom:
			var scene_path := _room_scene_path_template.replace("%s", room_name.to_snake_case())
			return (load(scene_path) as PackedScene).instantiate()
	)
	return Completion.DONE if room_scene_paths.any(_update_room) else Completion.IGNORED


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
	
	if room_objects_to_add.is_empty():
		# No need to update the room
		return false
	
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
		if (
			(obj is PopochiuProp or obj is PopochiuHotspot)
			and (obj.has_node("InteractionPolygon") or obj.has_node("InteractionPolygon2"))
		):
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
func _replace_deprecated_method_calls() -> Completion:
	var scripts_paths := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.GAME_PATH, ["gd"]
	)
	
	var replaced_matches := 0
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
		replaced_matches += 1 if PopochiuMigrationHelper.replace_text_in_files(
			Array(scripts_paths), dic.from, dic.to
		) else 0
	
	return Completion.DONE if replaced_matches > 0 else Completion.IGNORED


#endregion
