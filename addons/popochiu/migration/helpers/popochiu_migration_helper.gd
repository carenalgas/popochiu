@tool
class_name PopochiuMigrationHelper
extends Node
## Helper functions to assist migrating Popochiu Projects to newer versions

## Returns the user project migration version from the 'res://game/popochiu_data.cfg' file.
## If the Popochiu Migration Version is greater than the user project migration version
## then a migration needs to be done.
## If -1 gets returned then an error has occured.
static func get_user_migration_version() -> int:
	var config_file := PopochiuMigrationConfig.get_game_path() + '/' + 'popochiu_data.cfg'
	var config := ConfigFile.new()
	var error := config.load(config_file)
	
	# Version is older then Popochiu 2.0 Beta 1 so return version 0 so that the
	# version 1 project structure migration gets done.
	if PopochiuMigrationConfig.get_game_path() == 'res://popochiu':
		return 0

	# popochiu_data.cfg config file could not be loaded, return error
	if error != OK:
		return -1
	
	# return the migration version in the popochiu_data.cfg file
	if config.has_section_key('migration', 'version'):
		return config.get_value('migration', 'version')
	else: # Assume user is running Popochiu 2.0 Beta 1 to Beta 3, no project structure 
		  # migration needed
		  # set user migration version to 1 (Assume correct project structure exists)
		config.set_value('migration', 'version', 1)
		config.save(config_file)
		PopochiuUtils.print_normal('Popochiu Migration: Set Migration Version to 1 for existing ' +
			'Popochiu 2.0 project')
		return 1

	# no valid versions found
	return -1


## Updates the 'res://game/popochiu_data.cfg' migration version.
## [param version] is an integer value for the new migration version.
static func update_user_migration_version(version: int) -> void:
	var config_file := PopochiuMigrationConfig.get_game_path() + '/' + 'popochiu_data.cfg'
	var config := ConfigFile.new()
	var error := config.load(config_file)

	# popochiu_data.cfg config file could not be loaded, return error
	if error != OK:
		return
	
	config.set_value('migration', 'version', version)
	config.save(config_file)


## Gets the popochiu migration version from the PopochiuMigrationConfig.
## If the Popochiu Migration Version is greater than the user project migration version
## then a migration needs to be done.
static func get_popochiu_migration_version() -> void:
	return PopochiuMigrationConfig.get_version()


## Helper function to delete a folder and all its contents recursively
## [param folder_name] is a string that should be in the format of 'res://path_to/folder_name'
static func delete_folder_and_contents(folder_name: String) -> void:
	if DirAccess.dir_exists_absolute(folder_name):
		# delete folders and their contents recursively in folder_name
		for folder_path in get_absolute_directory_paths_at(folder_name):
			# run this to delete files/folders recursively at folder_path
			delete_folder_and_contents(folder_path)
			# all files/folders deleted in folder_path so remove folder_path folder
			DirAccess.remove_absolute(folder_path)
		
		# delete all files in folder_name
		for file_path in get_absolute_file_paths_at(folder_name):
			# delete file_path file 
			DirAccess.remove_absolute(file_path)
		
		# all files/folders deleted in folder_name so remove the folder_name folder
		DirAccess.remove_absolute(folder_name)

## Helper function to get the absolute directory paths for all folders under [param folder_name].
## [param folder_name] is the path to get absolute directory paths from.
static func get_absolute_directory_paths_at(folder_name: String) -> PackedStringArray:
	var dir_array : PackedStringArray = []
	
	if DirAccess.dir_exists_absolute(folder_name):
		# delete folders and their contents recursively in folder_name
		for folder in DirAccess.get_directories_at(folder_name):
			dir_array.append(folder_name + '/' + folder)
	
	return dir_array


## Helper function to get the absolute file paths for all files under [param folder_name].
## [param folder_name] is the path to get the absolute file paths from.
static func get_absolute_file_paths_at(folder_name: String) -> PackedStringArray:
	var file_array : PackedStringArray = []
	
	if DirAccess.dir_exists_absolute(folder_name):
		for file in DirAccess.get_files_at(folder_name): 
			file_array.append(folder_name + '/' + file)
	
	return file_array


# Helper function to recursively scan the directory and return an array of file paths with the 
# specified extension.
# [param path] is a String for the absolute path to scan.
# [param file_extension] is a String for the file extension e.g. '.tres'
# This returns an array with an absolute path to the files with the [param file_extension]
static func get_absolute_file_paths_for_file_extension(path: String, file_extension: String) \
		-> PackedStringArray:
	var result: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(path)

	if dir.dir_exists(path):
		dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		while true:
			var file: String = dir.get_next()
			if file.is_empty():
				break
			var file_path: String = path + '/' + file
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
	var game_path := PopochiuMigrationConfig.get_game_path()
	var commands_file := game_path + '/graphic_interface/commands.gd'

	# project specific things to store before rebuilding the file
	var pc := ''
	var template := ''
	var commands := ''
	var migration := 0

	# variables for working with the config file
	var config_file := game_path + '/' + 'popochiu_data.cfg'
	var config := ConfigFile.new()
	var error := config.load(config_file)

	# popochiu_data.cfg config file can be loaded so try to get some project specific values
	if error == OK:
		# get the player character
		if config.has_section('setup'):
			pc = config.get_value('setup', 'pc', '') # default to blank string if not found
		
		# get the migration version
		if config.has_section('migration'):
			migration = config.get_value('migration', 'version', 0) # default to 0 if not found
		
		# get ui values
		if config.has_section('ui'):
			template = config.get_value('ui', 'template', 'SimpleClick') # default to SimpleClick
			commands = config.get_value('ui', 'commands', '') # default to blank string if not found
	
	if template == '':
		template = 'SimpleClick'

	if commands == '':
		if FileAccess.file_exists(commands_file):
			commands = commands_file
	
	# Build new config file
	config = ConfigFile.new()

	# Set project specific values from original popochiu_data.cfg file
	config.set_value('setup', 'done', false)
	config.set_value('setup', 'pc', pc)
	config.set_value('migration', 'version', migration)
	config.set_value('ui', 'template', template)
	if commands != '':
		config.set_value('ui', 'commands', commands)
	
	_rebuild_popochiu_data_section(config, game_path, 'rooms')
	_rebuild_popochiu_data_section(config, game_path, 'characters')
	_rebuild_popochiu_data_section(config, game_path, 'dialogs')
	_rebuild_popochiu_data_section(config, game_path, 'inventory_items')

	config.set_value('setup', 'done', true)
	config.save(config_file)
	

static func _rebuild_popochiu_data_section(config_file: ConfigFile, game_path: String, \
		data_section: String) -> void:
	var data_path := game_path + '/' + data_section
	var section_name := data_section
	
	# Make sure the section name does not have an 's' character at the end
	if section_name.length() > 0 and section_name[-1] == 's':
		section_name = section_name.erase(section_name.length() - 1)

	# add the keys and tres files for each directory in the data section
	for folder in DirAccess.get_directories_at(data_path):
		var key_name := folder.to_pascal_case()
		var tres_file := section_name + '_' + folder + '.tres'
		var key_value := game_path + '/' + data_section + '/' + folder + '/' + tres_file

		if not FileAccess.file_exists(key_value):
			if section_name == 'inventory_item':
				section_name = 'inventory'
				tres_file = section_name + '_' + folder + '.tres'
				key_value = game_path + '/' + data_section + '/' + folder + '/' + tres_file

		config_file.set_value(data_section, key_name, key_value)

