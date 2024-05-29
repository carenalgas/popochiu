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
		_move_game_data_to_game_folder()
		_rename_data_to_snake_case()
		PopochiuMigrationHelper.rebuild_popochiu_data_file()
		_update_game_folder_references()
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
## Change the folder used for storing the game from "res://popochiu" to "res://game". 
func _move_game_data_to_game_folder() -> void:
	# We don't need the autoloads directory as Popochiu 2.x creates it automatically. 
	# Delete the POPOCHIU_PATH autoloads directory if it exists
	_delete_autoloads()

	# Moves game data from PopochiuMigrationHelper.POPOCHIU_PATH to PopochiuResources.GAME_PATH
	_move_game_data()


## Delete the POPOCHIU_PATH autoloads directory if it exists
func _delete_autoloads() -> void:
	var autoloads_path := PopochiuMigrationHelper.POPOCHIU_PATH.path_join("Autoloads")
	
	if DirAccess.dir_exists_absolute(autoloads_path):
		PopochiuMigrationHelper.delete_folder_and_contents(autoloads_path)
	elif DirAccess.dir_exists_absolute(autoloads_path.to_lower()):
		PopochiuMigrationHelper.delete_folder_and_contents(autoloads_path.to_lower())


## Moves game data from PopochiuMigrationHelper.POPOCHIU_PATH to PopochiuResources.GAME_PATH
func _move_game_data() -> void:
	var folders := DirAccess.get_directories_at(PopochiuMigrationHelper.POPOCHIU_PATH)
	var files := DirAccess.get_files_at(PopochiuMigrationHelper.POPOCHIU_PATH)

	# Move folders from PopochiuMigrationHelper.POPOCHIU_PATH to PopochiuResources.GAME_PATH
	for folder in folders:
		var src := PopochiuMigrationHelper.POPOCHIU_PATH.path_join(folder)
		var dest := PopochiuResources.GAME_PATH.path_join(folder.to_snake_case())
		DirAccess.rename_absolute(src, dest)

	# Move files from PopochiuMigrationHelper.POPOCHIU_PATH to PopochiuResources.GAME_PATH
	for file in files:
		var src := PopochiuMigrationHelper.POPOCHIU_PATH.path_join(file)
		var dest := PopochiuResources.GAME_PATH.path_join(file.to_snake_case())
		DirAccess.rename_absolute(src, dest)

	# All files/folders moved to PopochiuResources.GAME_PATH so delete the
	# PopochiuMigrationHelper.POPOCHIU_PATH directory
	DirAccess.remove_absolute(PopochiuMigrationHelper.POPOCHIU_PATH)


## Rename PopochiuResources.GAME_PATH files and folders to snake case
func _rename_data_to_snake_case():
	for folder: String in PopochiuMigrationHelper.get_absolute_directory_paths_at(
		PopochiuResources.GAME_PATH
	):
		_rename_files_to_snake_case(folder)
		_rename_folders_to_snake_case(folder)


## Rename [param path] files to snake_case
func _rename_files_to_snake_case(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		var src := path.path_join(file)
		var dest := path.path_join(file.to_snake_case())
		DirAccess.rename_absolute(src, dest)


## Rename [param path] folders and the content in the folders recursively to snake_case
func _rename_folders_to_snake_case(path: String) -> void:
	for folder in PopochiuMigrationHelper.get_absolute_directory_paths_at(path):
		_rename_files_to_snake_case(folder)
		DirAccess.rename_absolute(folder, folder.to_snake_case())
		# recursively rename files/folders to snake_case
		_rename_folders_to_snake_case(folder.to_snake_case())


func _update_game_folder_references() -> void:
	pass


#endregion
