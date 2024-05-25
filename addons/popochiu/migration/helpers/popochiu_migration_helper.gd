@tool
class_name PopochiuMigrationHelper
extends Node
## Helper class to assist migrating Popochiu Projects to newer versions

const POPOCHIU_PATH = "res://popochiu/"

static var is_reload_required := false
static var old_settings_file := PopochiuResources.GAME_PATH.path_join("popochiu_settings.tres")

static var _room_scene_path_template := PopochiuResources.ROOMS_PATH.path_join("%s/room_%s.tscn")


#region Public #####################################################################################
static func get_migrations_count() -> int:
	return DirAccess.get_files_at("res://addons/popochiu/migration/migration_files/").size()


## Returns the game folder path. If this returns [member POPOCHIU_PATH], then the project is from
## Popochiu 1.x or Popochiu 2.0.0-AlphaX.
static func get_game_path() -> String:
	if (
		DirAccess.dir_exists_absolute(PopochiuResources.GAME_PATH)
		and DirAccess.dir_exists_absolute(POPOCHIU_PATH)
	):
		return POPOCHIU_PATH
	elif DirAccess.dir_exists_absolute(PopochiuResources.GAME_PATH):
		return PopochiuResources.GAME_PATH
	else: # Error cannot access the game folders
		return ""


## Returns the user project migration version from the "res://game/popochiu_data.cfg" file.
## If the Popochiu Migration Version is greater than the user project migration version
## then a migration needs to be done.
## If -1 gets returned then an error has occured.
static func get_user_migration_version() -> int:
	# popochiu_data.cfg config file could not be loaded, return error
	if PopochiuResources.get_data_cfg() == null:
		PopochiuUtils.print_error("Can't load [code]popochiu_data.cfg[/code] file.")
		return -1
	
	if PopochiuResources.has_data_value("migration", "version"):
		# Return the migration version in the popochiu_data.cfg file
		return PopochiuResources.get_data_value("migration", "version", 1)
	else:
		# Run Migration 1 and so on
		return 0


## Returns [code]true[/code] if this is an empty project: no rooms, no characters, no inventory
## items, no dialogues, and no audio files.
static func is_empty_project() -> bool:
	if (
		get_game_path() == PopochiuResources.GAME_PATH
		and PopochiuResources.get_section_keys("rooms").is_empty()
		and PopochiuResources.get_section_keys("characters").is_empty()
		and PopochiuResources.get_section_keys("inventory_items").is_empty()
		and PopochiuResources.get_section_keys("dialogs").is_empty()
		and PopochiuResources.get_section_keys("audio").is_empty()
	):
		return true
	
	return false


## Returns [true] if the current Popochiu migration version is newer than the user's migration
## version, which means a migration is needed.
static func is_migration_needed() -> bool:
	return get_migrations_count() > get_user_migration_version()


## Updates [code]res://game/popochiu_data.cfg[/code] migration version to [param version].
static func update_user_migration_version(new_version: int) -> void:
	if PopochiuResources.set_data_value("migration", "version", new_version) != OK:
		PopochiuUtils.print_error(
			"Couldn't update the Migration version from [b]%d[/b] to [b]%d[/b] in Data file." % [
				get_migrations_count(), new_version
			]
		)


## Executes the [param steps] in [param migration] one by one and returns [code]true[/code] if
## all finished without failing. It stops execution if a step fails.
static func execute_migration_steps(migration: PopochiuMigration, steps: Array) -> bool:
	if steps.is_empty():
		PopochiuUtils.print_error(
			"No steps to execute for Migration %d" % migration.get_version()
		)
		await PopochiuEditorHelper.wait_process_frame()
		return false
	
	var idx := 0
	for step: Callable in steps:
		migration.start_step(idx)
		var completion_type: PopochiuMigration.Completion = await step.call()
		if completion_type in [
			PopochiuMigration.Completion.DONE, PopochiuMigration.Completion.IGNORED
		]:
			await migration.step_finished(idx, completion_type)
		else:
			return false
		
		idx += 1
	
	return true


## Helper function to delete a folders and files inside [param folder_path].
static func delete_folder_and_contents(folder_path: String) -> bool:
	if DirAccess.dir_exists_absolute(folder_path):
		# Delete subfolders and their contents recursively in folder_path
		for subfolder_path: String in get_absolute_directory_paths_at(folder_path):
			delete_folder_and_contents(subfolder_path)
		
		# Delete all files in folder_path
		for file_path: String in get_absolute_file_paths_at(folder_path):
			if DirAccess.remove_absolute(file_path) != OK:
				return false
		
		# Once all files are deleted in folder_path, remove folder_path
		if DirAccess.remove_absolute(folder_path) != OK:
			return false
	return true


## Helper function to get the absolute directory paths for all folders under [param folder_path].
static func get_absolute_directory_paths_at(folder_path: String) -> Array:
	var dir_array : PackedStringArray = []
	
	if DirAccess.dir_exists_absolute(folder_path):
		for folder in DirAccess.get_directories_at(folder_path):
			dir_array.append(folder_path.path_join(folder))
	
	return Array(dir_array)


## Helper function to get the absolute file paths for all files under [param folder_path].
static func get_absolute_file_paths_at(folder_path: String) -> PackedStringArray:
	var file_array : PackedStringArray = []
	
	if DirAccess.dir_exists_absolute(folder_path):
		for file in DirAccess.get_files_at(folder_path): 
			file_array.append(folder_path.path_join(file))
	
	return file_array


## Helper function to recursively scan the directory in [param path] and return an [Array] of
## absolute file paths with the specified extension.
static func get_absolute_file_paths_for_file_extensions(
	path: String, file_extensions: Array[String], folders_to_ignore: Array[String] = []
) -> Array:
	var file_paths := []
	var dir: DirAccess = DirAccess.open(path)

	if not dir.dir_exists(path):
		return file_paths
	
	dir.list_dir_begin()
	var element_name = dir.get_next()
	while not element_name.is_empty():
		var file_path := path.path_join(element_name)
		if dir.current_is_dir():
			if element_name in folders_to_ignore:
				element_name = dir.get_next()
				continue
			
			# Recurse into subdirectories
			file_paths += get_absolute_file_paths_for_file_extensions(
				file_path, file_extensions, folders_to_ignore
			)
		elif file_extensions.is_empty() or file_path.get_extension() in file_extensions:
			# Add files with the specified extension to the [file_paths] array
			file_paths.append(file_path)
		
		element_name = dir.get_next()
	dir.list_dir_end()

	return file_paths


## Looks in the text of each file in [param file_paths] for coincidencies of [param from], and
## replace them by [param to]. If any replacement was done, returns [code]true[/code].
static func replace_text_in_files(from: String, to: String, file_paths: Array) -> bool:
	return PopochiuUtils.any(
		file_paths,
		func (file_path: String) -> bool:
			if not FileAccess.file_exists(file_path):
				return true
			
			var file_read := FileAccess.open(file_path, FileAccess.READ)
			var text := file_read.get_as_text()
			file_read.close()
			
			if not from in text:
				return false
			
			var file_write := FileAccess.open(file_path, FileAccess.WRITE)
			text = text.replace(from, to)
			file_write.store_string(text)
			file_write.close()
			return true
	)


## Returns [true] if the game is checked as pixel-art based on the value in
## [code]popochiu/pixel/pixel_art_textures[/code] or in the old [code]popochiu_settings.tres[/code]
## file in versions prior to [i]2.0.0-beta3[/i].
static func is_pixel_art_game() -> bool:
	var is_pixel_art := PopochiuConfig.is_pixel_art_textures()
	
	if FileAccess.file_exists(old_settings_file):
		var old_settings := load(old_settings_file)
		if old_settings.get("is_pixel_art_game") != null:
			is_pixel_art = old_settings.is_pixel_art_game
	
	return is_pixel_art


## Checks if [param text] exists in the text of the file at [param file_path].
static func is_text_in_file(text: String, file_path: String) -> bool:
	var file_read := FileAccess.open(file_path, FileAccess.READ)
	var file_text := file_read.get_as_text()
	file_read.close()
	
	return text in file_text


## TODO: Document this function.
static func replace_in_scripts(replacements: Array[Dictionary]) -> bool:
	var scripts_paths := get_absolute_file_paths_for_file_extensions(
		PopochiuResources.GAME_PATH, ["gd"]
	)
	
	var replaced_matches := 0
	for dic: Dictionary in replacements:
		replaced_matches += 1 if replace_text_in_files(dic.from, dic.to, scripts_paths) else 0
	
	return replaced_matches > 0


## TODO: Document this function.
static func get_rooms() -> Array[PopochiuRoom]:
	var rooms: Array[PopochiuRoom] = []
	rooms.assign(PopochiuResources.get_section_keys("rooms").map(
		func (room_name: String) -> PopochiuRoom:
			var scene_path := _room_scene_path_template.replace("%s", room_name.to_snake_case())
			return (load(scene_path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	))
	return rooms


#endregion
