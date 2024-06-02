@tool
class_name PopochiuMigrationHelper
extends Node
## Helper class to assist migrating Popochiu Projects to newer versions

const POPOCHIU_PATH = "res://popochiu/"

# Needs to be increased when a new migration is written
static var version := 1


#region Public #####################################################################################
## Returns the game folder path. If this returns POPOCHIU_PATH then the project is from Popochiu 1.x
## or Popochiu 2.0 Alpha.
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
	
	if PopochiuResources.has_data_value("migration", "version"):
		# Return the migration version in the popochiu_data.cfg file
		return PopochiuResources.get_data_value("migration", "version", 1)
	elif get_game_path() == POPOCHIU_PATH:
		# The project is older than Popochiu 2.0 Beta 1, so return 0 so that the version 1 project
		# structure migration gets done
		return 0
	else:
		# Assume user is running Popochiu 2.0, no project structure migration needed, so set user
		# migration version to 1 (assume correct project structure exists)
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
static func update_user_migration_version(version: int) -> void:
	if PopochiuResources.set_data_value("migration", "version", version) != OK:
		PopochiuUtils.print_error("Couldn't update the Migration version in Data file.")


## Returns the migration version. If the Popochiu Migration Version is greater than the user project
## migration version then a migration needs to be done.
static func get_popochiu_migration_version() -> int:
	return version


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


static func rebuild_popochiu_data_file() -> void:
	_rebuild_popochiu_data_section(PopochiuResources.GAME_PATH, "rooms")
	_rebuild_popochiu_data_section(PopochiuResources.GAME_PATH, "characters")
	_rebuild_popochiu_data_section(PopochiuResources.GAME_PATH, "dialogs")
	_rebuild_popochiu_data_section(PopochiuResources.GAME_PATH, "inventory_items")
	
	PopochiuResources.set_data_value("setup", "done", true)


static func _rebuild_popochiu_data_section(game_path: String, data_section: String) -> void:
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


## Look in the text of each file in [param file_paths] for coincidencies to [param from] and
## replace them by [param to].
static func replace_path_reference(file_paths: Array, from: String, to: String) -> void:
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


#endregion
