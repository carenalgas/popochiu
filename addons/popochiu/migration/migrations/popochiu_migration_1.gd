@tool
class_name PopochiuMigration1
extends PopochiuMigration
## Migrates projects from Alpha to Beta.

const VERSION = 1
const DESCRIPTION = "Migrate project structure from alpha-x to beta"
const STEPS = [
	"Delete [b]res://popochiu/autoloads/[/b].",
	"Move folders in [b]res://popochiu/[/b] to [b]res://game/[/b]. (pre [i]beta 1[/i])",
	"Rename folders and files to snake_case. (pre [i]alpha 2[/i])",
	#"Select the default GUI template. (pre [i]beta 1[/i])",
	"Update paths in [b]res://game/popochiu_data.cfg[/b]. (pre [i]beta 1[/i])",
	"Rename [b]res://popochiu/[/b] references to [b]res://game/[/b]. (pre [i]beta 1[/i])",
	"Rename [b]item_xxx[/b] to [b]inventory_item_xxx[/b] for inventory items. (pre [i]beta 1[/i])",
	"Update [b]PopochiuCharacter[/b]s. (pre [i]beta 1[/i])",
	"Replace deprecated method calls. (pre [i]beta 1[/i])",
]
const DEFAULT_GUI_TEMPLATE = "SimpleClick"
const PopochiuGuiTemplatesHelper = preload(
	"res://addons/popochiu/editor/helpers/popochiu_gui_templates_helper.gd"
)

var _snake_renamed := []


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
			_rename_files_and_folders_to_snake_case,
			#_select_gui_template,
			_rebuild_popochiu_data_file,
			_rename_game_folder_references,
			_update_inventory_items,
			_update_characters,
			_replace_deprecated_method_calls,
		]
	)


#endregion

#region Public #####################################################################################
func is_migration_needed() -> bool:
	return super() and !_ignore_popochiu_folder_step()


#endregion

#region Private ####################################################################################
## Checks if the folder where the game is stored is the one used since Beta 1. This means the
## [code]res://popochiu/[/code] folder doesn't exists in the project
func _ignore_popochiu_folder_step() -> bool:
	return PopochiuMigrationHelper.get_game_path() == PopochiuResources.GAME_PATH


## Delete the [constant PopochiuMigrationHelper.POPOCHIU_PATH] autoloads directory if it exists.
func _delete_popochiu_folder_autoloads() -> Completion:
	if _ignore_popochiu_folder_step():
		return Completion.IGNORED
	
	# No need to move the autoloads directory as Popochiu 2 creates them automatically. This will
	# also fix the issue related with using [preload()] in old [A] autoload.
	var all_done := false
	var autoloads_path := PopochiuMigrationHelper.POPOCHIU_PATH.path_join("Autoloads")
	
	if DirAccess.dir_exists_absolute(autoloads_path):
		all_done = PopochiuEditorHelper.remove_recursive(autoloads_path)
	elif DirAccess.dir_exists_absolute(autoloads_path.to_lower()):
		all_done = PopochiuEditorHelper.remove_recursive(autoloads_path.to_lower())
	
	_reload_needed = true
	return Completion.DONE if all_done else Completion.FAILED


## Moves game data from [constant PopochiuMigrationHelper.POPOCHIU_PATH] to
## [constant PopochiuResources.GAME_PATH].
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
	_reload_needed = true
	return (
		Completion.DONE if DirAccess.remove_absolute(PopochiuMigrationHelper.POPOCHIU_PATH) == OK
		else Completion.FAILED
	)


## Rename [constant PopochiuResources.GAME_PATH] files and folders to snake case.
func _rename_files_and_folders_to_snake_case() -> Completion:
	var any_renamed := PopochiuUtils.any_exhaustive(
		PopochiuEditorHelper.get_absolute_directory_paths_at(PopochiuResources.GAME_PATH),
		func (folder: String) -> bool:
			var any_file_renamed := _rename_files_to_snake_case(folder)
			var any_folder_renamed := _rename_folders_to_snake_case(folder)
			
			return any_file_renamed or any_folder_renamed
	)
	
	if any_renamed:
		# Go over .gd, .tscn, .tres, and .cfg files to update their references to snake renamed
		# files and folders
		var files := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
			PopochiuResources.GAME_PATH, ["gd", "tscn", "tres", "cfg"], ["autoloads"]
		)
		for names_pair: Dictionary in _snake_renamed:
			PopochiuMigrationHelper.replace_text_in_files(names_pair.old, names_pair.new, files)
	
	_reload_needed = true
	return Completion.DONE if any_renamed else Completion.IGNORED


## Renames all the folders and files in [param folder_path] to snake_case.
func _rename_files_to_snake_case(folder_path: String) -> bool:
	return PopochiuUtils.any_exhaustive(
		Array(DirAccess.get_files_at(folder_path)),
		func (file: String) -> bool:
			var src := folder_path.path_join(file)
			var dest := folder_path.path_join(file.to_snake_case())
			
			if src != dest:
				_snake_renamed.append({
					old = src.get_file(),
					new = dest.get_file()
				})
				
				DirAccess.rename_absolute(src, dest)
				return true
			return false
	)


## Rename [param path] folders and the content in the folders recursively to snake_case
func _rename_folders_to_snake_case(path: String) -> bool:
	return PopochiuUtils.any_exhaustive(
		PopochiuEditorHelper.get_absolute_directory_paths_at(path),
		func (sub_folder: String) -> bool:
			# recursively rename files/folders to snake_case
			var any_subfolder_renamed = _rename_folders_to_snake_case(sub_folder)
			var any_file_renamed := _rename_files_to_snake_case(sub_folder)
			var snake_case_name := sub_folder.to_snake_case()
			var folder_renamed := sub_folder != snake_case_name
			
			if folder_renamed:
				_snake_renamed.append({
					old = sub_folder.replace(PopochiuResources.GAME_PATH, ""),
					new = snake_case_name.replace(PopochiuResources.GAME_PATH, ""),
				})
				
				DirAccess.rename_absolute(sub_folder, snake_case_name)
				folder_renamed = true
			
			return any_subfolder_renamed or any_file_renamed or folder_renamed
	)


## Copies the 2-click Context-sensitive GUI to [code]res://game/gui/[/code] if there
## is no GUI template selected.
func _select_gui_template() -> Completion:
	if PopochiuResources.get_data_value("ui", "template", "").is_empty():
		# Assume the project is from Popochiu 1.x or Popochiu 2 - Alpha X and assign the SimpleClick
		# GUI template
		await PopochiuGuiTemplatesHelper.copy_gui_template(
			DEFAULT_GUI_TEMPLATE,
			func (_progress: int, _msg: String) -> void: return,
			func () -> void: return,
		)
		return Completion.DONE
	else:
		await PopochiuEditorHelper.frame_processed()
		return Completion.IGNORED


## Updates the paths to rooms, characters, inventory items and dialogs so they point to
## [code]res://game/[/code] (for cases where the project still used [code]res://popochiu/[/code]).
func _rebuild_popochiu_data_file() -> bool:
	if PopochiuMigrationHelper.is_text_in_file(
		PopochiuMigrationHelper.POPOCHIU_PATH, PopochiuResources.DATA
	):
		_rebuild_popochiu_data_section(PopochiuResources.GAME_PATH, "rooms")
		_rebuild_popochiu_data_section(PopochiuResources.GAME_PATH, "characters")
		_rebuild_popochiu_data_section(PopochiuResources.GAME_PATH, "inventory_items")
		_rebuild_popochiu_data_section(PopochiuResources.GAME_PATH, "dialogs")
		
		return (
			Completion.DONE if PopochiuResources.set_data_value("setup", "done", true) == OK
			else Completion.FAILED
		)
	
	return Completion.IGNORED


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


## Renames uses of [b]res://popochiu/[/b] to [b]res://game/[/b] in [code].tscn[/code],
## [code].tres[/code], and [code].gd[/code] files.
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
		PopochiuMigrationHelper.POPOCHIU_PATH, PopochiuResources.GAME_PATH, files
	):
		changes_done = true
	
	_reload_needed = changes_done
	return Completion.DONE if changes_done else Completion.IGNORED


## Updates all inventory items in the project so:[br]
## - Their files (.tscn, .gd, and .tres) match the naming defined since beta-1 (inventory_item_*.*).
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
	var files_to_update := inventory_item_files.filter(
		func (file_path: String) -> bool:
			if file_path.get_extension() == "tscn":
				scene_files.append(file_path)
			return "/item_" in file_path
	)
	
	if files_to_update.is_empty():
		return Completion.IGNORED
	
	var update_done := scene_files.all(_update_root_name_and_texture_filter)
	if update_done:
		update_done = files_to_update.all(_rename_inventory_item_files_name)
	
	if update_done and PopochiuMigrationHelper.is_text_in_file("/item_", PopochiuResources.I_SNGL):
		update_done = PopochiuMigrationHelper.replace_text_in_files(
			"/item_", "/inventory_item_", [PopochiuResources.I_SNGL]
		)
	
	_reload_needed = update_done
	return Completion.DONE if update_done else Completion.FAILED


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
func _rename_inventory_item_files_name(file_path: String) -> bool:
	var old_file_name := file_path.get_file().get_basename()
	var new_file_name := old_file_name.replace("item_", "inventory_item_")
	PopochiuMigrationHelper.replace_text_in_files(old_file_name, new_file_name, [file_path])
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
	var any_character_updated := PopochiuUtils.any_exhaustive(file_paths, _update_character)
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
	
	if not popochiu_character.has_node("AnimationPlayer"):
		# ---- Add an [AnimationPlayer] node if needed ---------------------------------------------
		was_scene_updated = true
		var animation_player := AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		popochiu_character.add_child(animation_player)
		animation_player.owner = popochiu_character
	else:
		# ---- Or remove the texture track if it exists (prior Beta 1)------------------------------
		var animation_player: AnimationPlayer = popochiu_character.get_node("AnimationPlayer")
		for anim_name: String in animation_player.get_animation_list():
			var animation: Animation = animation_player.get_animation(anim_name)
			var texture_path: String = "%s:%s" % [
				popochiu_character.get_path_to(popochiu_character.get_node("Sprite2D")),
				"texture"
			]
			var texture_track: int = animation.find_track(texture_path, Animation.TYPE_VALUE)
			if texture_track > -1:
				animation.remove_track(texture_track)
				was_scene_updated = true
	
	if was_scene_updated and PopochiuEditorHelper.pack_scene(popochiu_character, scene_path) != OK:
		PopochiuUtils.print_error("Couldn't update [b]%s[/b]." % popochiu_character.script_name)
	
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


## Replace calls to old methods ignoring the [code]res://game/gui/[/code] folder:
## - [code]R.get_point[/code] by [code]R.get_marker[/code].
## - [code]G.display[/code] to [code]G.show_system_text[/code].
## - Methods with [code]_now[/code] suffix.
## - [code]super.on_click() | super.on_right_click() | super.on_item_used(item)[/code] by
## [code]E.command_fallback()[/code]
## - [code]super(item)[/code] to [code]E.command_fallback()[/code].
func _replace_deprecated_method_calls() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = "R.get_point", to = "R.get_marker"},
		{from = "G.display", to = "G.show_system_text"},
		{from = "disable_now()", to = "disable()"},
		{from = "enable_now()", to = "enable()"},
		{from = "change_frame_now(", to = "change_frame("},
		{from = "super.on_click()", to = "E.command_fallback()"},
		{from = "super.on_right_click()", to = "E.command_fallback()"},
		{from = "super.on_item_used(item)", to = "E.command_fallback()"},
		{from = "super(item)", to = "E.command_fallback()"},
		# TODO: Include the following replacement. But for this one, the change should only be done
		# in scripts which have the default method implementation.
		#{from = "func _on_item_used(item", to = "func _on_item_used(_item"},
	], ["gui"]) else Completion.IGNORED


#endregion
