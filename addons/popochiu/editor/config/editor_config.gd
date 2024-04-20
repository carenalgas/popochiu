@tool
class_name PopochiuEditorConfig
extends RefCounted

enum Icons { COLLAPSED, EXPANDED }

# ASEPRITE IMPORTER --------------------------------------------------------------------------------
const ASEPRITE_IMPORTER_ENABLED = "popochiu/import/aseprite/enable_aseprite_importer"
const ASEPRITE_COMMAND_PATH = "popochiu/import/aseprite/command_path"
const ASEPRITE_REMOVE_JSON_FILE = "popochiu/import/aseprite/remove_json_file"

static var editor_settings: EditorSettings


#region Public #####################################################################################
static func initialize_editor_settings():
	editor_settings = EditorInterface.get_editor_settings()
	
	_initialize_editor_setting(ASEPRITE_IMPORTER_ENABLED, false, TYPE_BOOL)
	_initialize_editor_setting(ASEPRITE_COMMAND_PATH, _default_command(), TYPE_STRING)
	_initialize_editor_setting(ASEPRITE_REMOVE_JSON_FILE, true, TYPE_BOOL)


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
	return _get_editor_setting(ASEPRITE_IMPORTER_ENABLED, false)


static func get_command() -> String:
	return _get_editor_setting(ASEPRITE_COMMAND_PATH, _default_command())


static func should_remove_source_files() -> bool:
	return _get_editor_setting(ASEPRITE_REMOVE_JSON_FILE, true)


#endregion

#region Private ####################################################################################
static func _default_command() -> String:
	return 'aseprite'


static func _initialize_editor_setting(
	key: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE
) -> void:
	if editor_settings.has_setting(key): return
	
	editor_settings.set_setting(key, default_value)
	editor_settings.set_initial_value(key, default_value, false)
	editor_settings.add_property_info({
		"name": key,
		"type": type,
		"hint": hint,
	})


static func _get_editor_setting(key: String, default_value):
	var e = editor_settings.get_setting(key)
	return e if e != null else default_value


#endregion
