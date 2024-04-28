@tool
extends RefCounted
class_name ResultCodes

enum {
	## Base codes
	FAILURE, # generic failure state
	SUCCESS, # generic success state
	## Aseprite importer errors
	ERR_ASEPRITE_CMD_NOT_FULL_PATH,
	ERR_ASEPRITE_CMD_NOT_FOUND,
	ERR_SOURCE_FILE_NOT_FOUND,
	ERR_OUTPUT_FOLDER_NOT_FOUND,
	ERR_ASEPRITE_EXPORT_FAILED,
	ERR_UNKNOWN_EXPORT_MODE,
	ERR_NO_VALID_LAYERS_FOUND,
	ERR_INVALID_ASEPRITE_SPRITESHEET,
	ERR_NO_ANIMATION_PLAYER_FOUND,
	ERR_NO_SPRITE_FOUND,
	ERR_UNNAMED_TAG_DETECTED,
	ERR_TAGS_OPTIONS_ARRAY_EMPTY,
	## Popochiu Object factories errors
	ERR_CANT_CREATE_OBJ_FOLDER,
	ERR_CANT_CREATE_OBJ_STATE,
	ERR_CANT_OPEN_OBJ_SCRIPT_TEMPLATE,
	ERR_CANT_CREATE_OBJ_SCRIPT,
	ERR_CANT_SAVE_OBJ_SCENE,
	ERR_CANT_SAVE_OBJ_RESOURCE,
}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
static func get_error_message(code: int):
	## TODO: these messages are a bit dull, having params would be better.
	## Maybe add a param argument
	match code:
		# Aseprite importers error messages
		ERR_ASEPRITE_CMD_NOT_FULL_PATH:
			return "Aseprite command not found at given path. Please check \"Editor Settings > Popochiu > Import > Command Path\" to hold the FULL path to a valid Aseprite executable."
		ERR_ASEPRITE_CMD_NOT_FOUND:
			return "Aseprite command failed. Please, check if the right command is in your PATH or configured through \"Editor Settings > Popochiu > Import > Command Path\"."
		ERR_SOURCE_FILE_NOT_FOUND:
			return "Source file does not exist"
		ERR_OUTPUT_FOLDER_NOT_FOUND:
			return "Output location does not exist"
		ERR_ASEPRITE_EXPORT_FAILED:
			return "Unable to import file"
		ERR_INVALID_ASEPRITE_SPRITESHEET:
			return "Aseprite generated invalid data file"
		ERR_NO_VALID_LAYERS_FOUND:
			return "No valid layers found"
		ERR_NO_ANIMATION_PLAYER_FOUND:
			return "No AnimationPlayer found in target node"
		ERR_NO_SPRITE_FOUND:
			return "No sprite found in target node"
		ERR_UNNAMED_TAG_DETECTED:
			return "Unnamed tag detected"
		ERR_TAGS_OPTIONS_ARRAY_EMPTY:
			return "Tags options array is empty"
		# Popochiu object factories error messages
		ERR_CANT_CREATE_OBJ_FOLDER:
			return "Can't create folder to host new Popochiu object"
		ERR_CANT_CREATE_OBJ_STATE:
			return "Can't create new Popochiu object's state resource (_state.tres, _state.gd)"
		ERR_CANT_OPEN_OBJ_SCRIPT_TEMPLATE:
			return "Can't open script template for new Popochiu object"
		ERR_CANT_CREATE_OBJ_SCRIPT:
			return "Can't create new Popochiu object's script file (.gd)"
		ERR_CANT_SAVE_OBJ_SCENE:
			return "Can't create new Popochiu object's scene (.tscn)"
		ERR_CANT_SAVE_OBJ_RESOURCE:
			return "Can't create new Popochiu object's resource (.tres)"
		# Generic error message
		_:
			return "Import failed with code %d" % code
