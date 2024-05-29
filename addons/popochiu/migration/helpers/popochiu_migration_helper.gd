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
	# The project is older than Popochiu 2.0 Beta 1, so return 0 so that the version 1 project
	# structure migration gets done
	if get_game_path() in POPOCHIU_PATH:
		return 0

	# popochiu_data.cfg config file could not be loaded, return error
	if PopochiuResources.get_data_cfg() == null:
		return -1
	
	if PopochiuResources.has_data_value("migration", "version"):
		# Return the migration version in the popochiu_data.cfg file
		return PopochiuResources.get_data_value("migration", "version", 1)
	else:
		# Assume user is running Popochiu 2.0, no project structure migration needed, so set user
		# migration version to 1 (assume correct project structure exists)
		PopochiuResources.set_data_value("migration", "version", 1)
		PopochiuUtils.print_normal("Set migration version to 1 for existing Popochiu 2.0 project")
		return 1
	
	# no valid versions found
	return -1


## Updates [code]res://game/popochiu_data.cfg[/code] migration version to [param version].
static func update_user_migration_version(version: int) -> void:
	if PopochiuResources.set_data_value("migration", "version", version) != OK:
		PopochiuUtils.print_error("Couldn't update the Migration version in Data file.")


## Returns the migration version. If the Popochiu Migration Version is greater than the user project
## migration version then a migration needs to be done.
static func get_popochiu_migration_version() -> int:
	return version


## Helper function to delete a folders and files inside [param folder_path].
static func delete_folder_and_contents(folder_path: String) -> void:
	if DirAccess.dir_exists_absolute(folder_path):
		# Delete subfolders and their contents recursively in folder_path
		for subfolder_path: String in get_absolute_directory_paths_at(folder_path):
			delete_folder_and_contents(subfolder_path)
		
		# Delete all files in folder_path
		for file_path: String in get_absolute_file_paths_at(folder_path):
			DirAccess.remove_absolute(file_path)
		
		# Once all files are deleted in folder_path, remove folder_path
		DirAccess.remove_absolute(folder_path)


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


# Helper function to recursively scan the directory and return an array of file paths with the 
# specified extension.
# [param path] is a String for the absolute path to scan.
# [param file_extension] is a String for the file extension e.g. ".tres"
# This returns an array with an absolute path to the files with the [param file_extension]
static func get_absolute_file_paths_for_file_extension(
	path: String, file_extension: String
) -> PackedStringArray:
	var result: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(path)

	if dir.dir_exists(path):
		# TODO Converter3To4 fill missing arguments (https://github.com/godotengine/godot/pull/40547)
		dir.list_dir_begin()
		while true:
			var file: String = dir.get_next()
			if file.is_empty():
				break
			var file_path: String = path + "/" + file
			if dir.current_is_dir():
				# Recurse into subdirectories
				result += get_absolute_file_paths_for_file_extension(file_path, file_extension)
			elif file_path.ends_with(file_extension):
				# Add files with the specified extension to the result array
				result.append(file_path)
		dir.list_dir_end()
		dir.close()

	return result


static func rebuild_popochiu_data_file() -> void:
	var game_path := get_game_path()
	var commands_file := game_path.path_join("graphic_interface/commands.gd")

	# Project specific things to store before rebuilding the file
	var pc := ""
	var template := ""
	var commands := ""
	var migration := 0
	
	# popochiu_data.cfg config file can be loaded so try to get some project specific values
	if PopochiuResources.get_data_cfg():
		# get the player character
		pc = PopochiuResources.get_data_value("setup", "pc", "")
		
		# get the migration version
		migration = PopochiuResources.get_data_value("migration", "version", 0)
		
		# get ui values
		template = PopochiuResources.get_data_value("ui", "template", "SimpleClick")
		commands = PopochiuResources.get_data_value("ui", "commands", "")
	
	if template.is_empty():
		template = "SimpleClick"
	
	if commands.is_empty():
		if FileAccess.file_exists(commands_file):
			commands = commands_file
	
	# Set project specific values from original popochiu_data.cfg file
	PopochiuResources.set_data_value("setup", "done", false)
	PopochiuResources.set_data_value("setup", "pc", pc)
	PopochiuResources.set_data_value("migration", "version", migration)
	PopochiuResources.set_data_value("ui", "template", template)
	PopochiuResources.set_data_value("ui", "commands", commands)
	
	_rebuild_popochiu_data_section(game_path, "rooms")
	_rebuild_popochiu_data_section(game_path, "characters")
	_rebuild_popochiu_data_section(game_path, "dialogs")
	_rebuild_popochiu_data_section(game_path, "inventory_items")
	
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
		var tres_file := section_name + "_" + folder + ".tres"
		var key_value := game_path + "/" + data_section + "/" + folder + "/" + tres_file
	
		if not FileAccess.file_exists(key_value):
			if section_name == "inventory_item":
				section_name = "inventory"
				tres_file = section_name + "_" + folder + ".tres"
				key_value = game_path + "/" + data_section + "/" + folder + "/" + tres_file
		
		PopochiuResources.set_data_value(data_section, key_name, key_value)


#endregion
