@tool
class_name PopochiuMigrationHelper
extends Node
## Helper class to assist migrating Popochiu Projects to newer versions

const POPOCHIU_PATH = "res://popochiu/"

# Needs to be increased when a new migration is written
static var version := 1


#region Public #####################################################################################
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
		return -1
	
	if get_game_path() == POPOCHIU_PATH:
		# The project is older than Popochiu 2.0.0-Beta1. Return 0 so the project structure
		# migration gets done
		return 0
	elif PopochiuResources.has_data_value("migration", "version"):
		# Return the migration version in the popochiu_data.cfg file
		return PopochiuResources.get_data_value("migration", "version", 1)
	else:
		# Assume user is running Popochiu 2.0. No project structure migration is needed, so set user
		# migration version to 1.
		PopochiuResources.set_data_value("migration", "version", 1)
		PopochiuUtils.print_normal("Set migration version to 1 for existing Popochiu 2.0 project")
		return 1
	
	# no valid versions found
	return -1


## Returns [true] if the current Popochiu migration version is newer than the user's migration
## version, which means a migration is needed.
static func is_migration_needed() -> bool:
	return version > get_user_migration_version()


## Updates [code]res://game/popochiu_data.cfg[/code] migration version to [param version].
static func update_user_migration_version(new_version: int) -> void:
	if PopochiuResources.set_data_value("migration", "version", new_version) != OK:
		PopochiuUtils.print_error(
			"Couldn't update the Migration version from [b]%d[/b] to [b]%d[/b] in Data file." % [
				version, new_version
			]
		)


static func execute_migration_steps(migration: PopochiuMigration, steps: Array) -> bool:
	var idx := 0
	for step: Callable in steps:
		migration.start(idx)
		if await step.call():
			await migration.complete(idx)
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
static func get_absolute_directory_paths_at(folder_path: String) -> PackedStringArray:
	var dir_array : PackedStringArray = []
	
	if DirAccess.dir_exists_absolute(folder_path):
		for folder in DirAccess.get_directories_at(folder_path):
			dir_array.append(folder_path.path_join(folder))
	
	return dir_array


## Helper function to get the absolute file paths for all files under [param folder_path].
static func get_absolute_file_paths_at(folder_path: String) -> PackedStringArray:
	var file_array : PackedStringArray = []
	
	if DirAccess.dir_exists_absolute(folder_path):
		for file in DirAccess.get_files_at(folder_path): 
			file_array.append(folder_path.path_join(file))
	
	return file_array


## Helper function to recursively scan the directory in [param path] and return an [Array] of absolute
## file paths with the specified extension.
static func get_absolute_file_paths_for_file_extensions(
	path: String, file_extensions: Array[String], folders_to_ignore: Array[String] = []
) -> PackedStringArray:
	var file_paths: PackedStringArray = []
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


## Look in the text of each file in [param file_paths] for coincidencies to [param from] and
## replace them by [param to].
static func replace_text_in_files(file_paths: Array, from: String, to: String) -> void:
	for file_path: String in file_paths:
		var file_read := FileAccess.open(file_path, FileAccess.READ)
		var text := file_read.get_as_text()
		file_read.close()
		
		if not from in text:
			continue
		
		var file_write := FileAccess.open(file_path, FileAccess.WRITE)
		text = text.replace(from, to)
		file_write.store_string(text)
		file_write.close()


static func is_pixel_art_game() -> bool:
	var is_pixel_art := PopochiuConfig.is_pixel_art_textures()
	var old_settings_file := PopochiuResources.GAME_PATH.path_join("popochiu_settings.tres")
	
	if FileAccess.file_exists(old_settings_file):
		var old_settings := load(old_settings_file)
		if old_settings.get("is_pixel_art_game") != null:
			is_pixel_art = old_settings.is_pixel_art_game
	
	return is_pixel_art


#endregion
