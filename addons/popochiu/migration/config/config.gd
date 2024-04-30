@tool
class_name PopochiuMigrationConfig
extends Node

const _GAME_PATH = 'res://game'
const _POPOCHIU_PATH = 'res://popochiu'

# This needs to be increased when a new migration is written
static var _version = 1

## Returns the current migration version number
static func get_version() -> int:
    return _version


## Returns the game path. If this returns _POPOCHIU_PATH then the project is from Popochiu 1.x
## or Popochiu 2.0 Alpha.
static func get_game_path() -> String:
    if DirAccess.dir_exists_absolute(_GAME_PATH) and DirAccess.dir_exists_absolute(_POPOCHIU_PATH):
        return _POPOCHIU_PATH
    elif DirAccess.dir_exists_absolute(_GAME_PATH):
        return _GAME_PATH
    else: # Error cannot access the game folders
        return ''

