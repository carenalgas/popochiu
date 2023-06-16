@tool
extends RefCounted


const SUCCESS = 0
const ERR_ASEPRITE_CMD_NOT_FULL_PATH = 1
const ERR_ASEPRITE_CMD_NOT_FOUND = 2
const ERR_SOURCE_FILE_NOT_FOUND = 3
const ERR_OUTPUT_FOLDER_NOT_FOUND = 4
const ERR_ASEPRITE_EXPORT_FAILED = 5
const ERR_UNKNOWN_EXPORT_MODE = 6
const ERR_NO_VALID_LAYERS_FOUND = 7
const ERR_INVALID_ASEPRITE_SPRITESHEET = 8
const ERR_NO_ANIMATION_PLAYER_FOUND = 9
const ERR_NO_SPRITE_FOUND = 10
const ERR_UNNAMED_TAG_DETECTED = 11
const ERR_TAGS_OPTIONS_ARRAY_EMPTY = 12



# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
static func get_error_message(code: int):
	## TODO: these messages are a bit dull, having params would be better.
	## Maybe add a param argument
	match code:
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
		_:
			return "Import failed with code %d" % code
