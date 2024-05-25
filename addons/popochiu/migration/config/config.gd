@tool
class_name PopochiuMigrationConfig
extends Node

const POPOCHIU_PATH = "res://popochiu"

# This needs to be increased when a new migration is written
static var _version = 1


#region Public #####################################################################################
## Returns the current migration version number
static func get_version() -> int:
	return _version


## Returns the game path. If this returns POPOCHIU_PATH then the project is from Popochiu 1.x
## or Popochiu 2.0 Alpha.
static func get_game_path() -> String:
	if (
		DirAccess.dir_exists_absolute(PopochiuResources.BASE_DIR)
		and DirAccess.dir_exists_absolute(POPOCHIU_PATH)
	):
		return POPOCHIU_PATH
	elif DirAccess.dir_exists_absolute(PopochiuResources.BASE_DIR):
		return PopochiuResources.BASE_DIR
	else: # Error cannot access the game folders
		return ""


#endregion
