@tool
class_name PopochiuEditorConfig
extends RefCounted

enum Icons { COLLAPSED, EXPANDED }

# ASEPRITE IMPORTER --------------------------------------------------------------------------------
const ASEPRITE_IMPORTER_ENABLED = "popochiu/import/aseprite/enable_aseprite_importer"
const ASEPRITE_COMMAND_PATH = "popochiu/import/aseprite/command_path"
const ASEPRITE_REMOVE_JSON_FILE = "popochiu/import/aseprite/remove_json_file"

# GIZMOS -------------------------------------------------------------------------------------------
const GIZMOS_FONT_SIZE = "popochiu/gizmos/font_size"
const GIZMOS_BASELINE_COLOR = "popochiu/gizmos/baseline_color"
const GIZMOS_WALK_TO_POINT_COLOR = "popochiu/gizmos/walk_to_point_color"
const GIZMOS_LOOK_AT_POINT_COLOR = "popochiu/gizmos/look_at_point_color"
const GIZMOS_HANDLER_SIZE = "popochiu/gizmos/handler_size"
const GIZMOS_SHOW_CONNECTORS = "popochiu/gizmos/show_connectors"
const GIZMOS_SHOW_OUTLINE = "popochiu/gizmos/show_handler_outline"
const GIZMOS_SHOW_NODE_NAME = "popochiu/gizmos/show_node_name"

# Settings default values
static var defaults := {
	ASEPRITE_IMPORTER_ENABLED: false,
	ASEPRITE_COMMAND_PATH: _default_command(),
	ASEPRITE_REMOVE_JSON_FILE: true,
	GIZMOS_FONT_SIZE: EditorInterface.get_editor_theme().default_font_size,
	GIZMOS_BASELINE_COLOR: Color.CYAN,
	GIZMOS_WALK_TO_POINT_COLOR: Color.GREEN,
	GIZMOS_LOOK_AT_POINT_COLOR: Color.RED,
	GIZMOS_HANDLER_SIZE: 32,
	GIZMOS_SHOW_CONNECTORS: true,
	GIZMOS_SHOW_OUTLINE: true,
	GIZMOS_SHOW_NODE_NAME: true,
}

static var editor_settings: EditorSettings


#region Public #####################################################################################
static func initialize_editor_settings():
	editor_settings = EditorInterface.get_editor_settings()

	# Aseprite importer
	_initialize_editor_setting(ASEPRITE_IMPORTER_ENABLED, TYPE_BOOL)
	_initialize_editor_setting(ASEPRITE_COMMAND_PATH, TYPE_STRING)
	_initialize_editor_setting(ASEPRITE_REMOVE_JSON_FILE, TYPE_BOOL)
	# Gizmos
	_initialize_editor_setting(GIZMOS_BASELINE_COLOR, TYPE_COLOR)
	_initialize_editor_setting(GIZMOS_WALK_TO_POINT_COLOR, TYPE_COLOR)
	_initialize_editor_setting(GIZMOS_LOOK_AT_POINT_COLOR, TYPE_COLOR)
	_initialize_editor_setting(GIZMOS_HANDLER_SIZE, TYPE_INT, PROPERTY_HINT_RANGE, "4,64")
	_initialize_editor_setting(GIZMOS_FONT_SIZE, TYPE_INT, PROPERTY_HINT_RANGE, "4,64")
	_initialize_editor_setting(GIZMOS_SHOW_CONNECTORS, TYPE_BOOL)
	_initialize_editor_setting(GIZMOS_SHOW_OUTLINE, TYPE_BOOL)
	_initialize_editor_setting(GIZMOS_SHOW_NODE_NAME, TYPE_BOOL)


static func get_icon(icon: Icons) -> Texture2D:
	match icon:
		Icons.COLLAPSED:
			return EditorInterface.get_base_control().get_theme_icon(
				"GuiTreeArrowRight", "EditorIcons"
			)
		Icons.EXPANDED:
			return EditorInterface.get_base_control().get_theme_icon(
				"GuiTreeArrowDown", "EditorIcons"
			)
	
	return null


# ASEPRITE IMPORTER --------------------------------------------------------------------------------
static func aseprite_importer_enabled() -> bool:
	return _get_editor_setting(ASEPRITE_IMPORTER_ENABLED)


static func get_command() -> String:
	return _get_editor_setting(ASEPRITE_COMMAND_PATH)


static func should_remove_source_files() -> bool:
	return _get_editor_setting(ASEPRITE_REMOVE_JSON_FILE)

#endregion


#region Private ####################################################################################
static func _default_command() -> String:
	return 'aseprite'


static func _initialize_editor_setting(
	key: String, type: int, hint: int = PROPERTY_HINT_NONE, hint_string : String = ""
) -> void:
	if editor_settings.has_setting(key): return
	
	editor_settings.set_setting(key, defaults[key])
	editor_settings.set_initial_value(key, defaults[key], false)
	editor_settings.add_property_info({
		"name": key,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	})


static func _get_editor_setting(key: String):
	var e = editor_settings.get_setting(key)
	return e if e != null else defaults[e]


#endregion
