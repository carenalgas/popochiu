@tool
class_name PopochiuMigration1
extends PopochiuMigration
## PopochiuMigration1 migrates the popochiu 1.x project structure to the popochiu 2.x 
## project structure that changed in popochiu 2.0 beta 1.
## This migration does the following:
## - move files/folders from 'res://popochiu' to 'res://game'
## - rename files/folders to snake case
## - update the 'res://game/popochiu_data.cfg' file references
## - update the *.tres file references
## - update the godot project file to have correct reference for the default scene
## - add the [migration] section and version key to the 'res://game/popochiu_data.cfg' file

const _VERSION := 1
const _DESCRIPTION := 'Migrate project structure to Popochiu 2.0 format'
const _POPOCHIU_PATH := 'res://popochiu'
const _GAME_PATH := 'res://game'

## This is code specific for this migration.
## This should return true if the migration is successful.
## This is called from do_migration() which checks to make sure the migration should be done 
## before calling this.
func _do_migration() -> bool:
    # Only perform conversion if both the _POPOCHIU_PATH and _GAME_PATH directories exist
    if DirAccess.dir_exists_absolute(_POPOCHIU_PATH) and DirAccess.dir_exists_absolute(_GAME_PATH):
        _move_game_data_to_game_folder()
        _rename_data_to_snake_case()
        PopochiuMigrationHelper.rebuild_popochiu_data_file()
        _update_game_folder_references()
        return true
    else:
        PopochiuUtils.print_error('Both the ' + _POPOCHIU_PATH + ' and ' + _GAME_PATH + 
            ' folders must exist.')
        PopochiuUtils.print_error('Make sure that the Popochiu plugin is enabled and that ' + 
            'there is Popochiu 1.x data to convert.')
        return false


## Change the folder used for storing the game from 'res://popochiu' to 'res://game'. 
func _move_game_data_to_game_folder() -> void:
    # We don't need the autoloads directory as Popochiu 2.x creates it automatically. 
    # Delete the POPOCHIU_PATH autoloads directory if it exists
    _delete_autoloads()

    # Moves game data from _POPOCHIU_PATH to _GAME_PATH
    _move_game_data()


## We don't need the autoloads directory as Popochiu 2.x creates it automatically. 
## Delete the POPOCHIU_PATH autoloads directory if it exists
func _delete_autoloads() -> void:
    if DirAccess.dir_exists_absolute(_POPOCHIU_PATH + '/' + 'autoloads'):
        PopochiuMigrationHelper.delete_folder_and_contents(_POPOCHIU_PATH + '/' + 'autoloads')
    elif DirAccess.dir_exists_absolute(_POPOCHIU_PATH + '/' + 'Autoloads'):
        PopochiuMigrationHelper.delete_folder_and_contents(_POPOCHIU_PATH + '/' + 'Autoloads')


## Moves game data from _POPOCHIU_PATH to _GAME_PATH
func _move_game_data() -> void:
    var folders := DirAccess.get_directories_at(_POPOCHIU_PATH)
    var files := DirAccess.get_files_at(_POPOCHIU_PATH)

    # Move folders from _POPOCHIU_PATH to _GAME_PATH
    for folder in folders:
        var src := _POPOCHIU_PATH + '/' + folder
        var dest := _GAME_PATH + '/' + folder.to_snake_case()
        DirAccess.rename_absolute(src, dest)

    # Move files from _POPOCHIU_PATH to _GAME_PATH
    for file in files:
        var src := _POPOCHIU_PATH + '/' + file
        var dest := _GAME_PATH + '/' + file.to_snake_case()
        DirAccess.rename_absolute(src, dest)

    # All files/folders moved to _GAME_PATH so delete the _POPOCHIU_PATH directory
    DirAccess.remove_absolute(_POPOCHIU_PATH)


## Rename _GAME_PATH files and folders to snake case
func _rename_data_to_snake_case():
    for folder in PopochiuMigrationHelper.get_absolute_directory_paths_at(_GAME_PATH):
        _rename_files_to_snake_case(folder)
        _rename_folders_to_snake_case(folder)


## Rename [param path] files to snake_case
func _rename_files_to_snake_case(path: String) -> void:
    for file in DirAccess.get_files_at(path):
        var src := path + '/' + file
        var dest := path + '/' + file.to_snake_case()
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


# Code below this point should not need to be changed and is templated to be consistent
# between migrations.

## Attempts to do the migration
## Returns true if successful.
func do_migration() -> bool:
    set_migration_version(_VERSION)

    # make sure the user migration version is less then this migration version
    if not can_do_migration():
        return false
    
    PopochiuUtils.print_normal('Performing Migration ' + str(_VERSION) + ': ' + _DESCRIPTION)

    return _do_migration()