@tool
extends RefCounted

# PROJECT SETTINGS
# general settings
const ASEPRITE_COMMAND_KEY = 'popochiu/import/aseprite/command_path'

# animation import defaults
const DEFAULT_IMPORT_ENABLED = 'popochiu/import/aseprite/import_animation_by_default'
const DEFAULT_LOOP_ENABLED = 'popochiu/import/aseprite/loop_animation_by_default'
const DEFAULT_WIPE_OLD_ANIMS_ENABLED = 'popochiu/import/aseprite/wipe_old_animations'
const REMOVE_SOURCE_FILES_KEY = 'popochiu/import/aseprite/remove_json_file'


var ei: EditorInterface

var _plugin_icons: Dictionary


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func initialize_project_settings():
	_initialize_project_cfg(ASEPRITE_COMMAND_KEY, _default_command(), TYPE_STRING)
	_initialize_project_cfg(DEFAULT_IMPORT_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(DEFAULT_LOOP_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(DEFAULT_WIPE_OLD_ANIMS_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(REMOVE_SOURCE_FILES_KEY, true, TYPE_BOOL)

	_set_icons()
	
	ProjectSettings.save()


# TODO: this is never used, go and check if we need it
func clear_project_settings():
	var _all_settings = [
		DEFAULT_IMPORT_ENABLED,
		DEFAULT_LOOP_ENABLED,
		DEFAULT_WIPE_OLD_ANIMS_ENABLED,
		REMOVE_SOURCE_FILES_KEY,
	]
	for key in _all_settings:
		ProjectSettings.clear(key)
	ProjectSettings.save()



# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func is_command_or_control_pressed() -> String:
	var command = ProjectSettings.get_setting(ASEPRITE_COMMAND_KEY) if ProjectSettings.has_setting(ASEPRITE_COMMAND_KEY) else ""
	return command if command != "" else _default_command()


func get_icon(icon_name: String) -> Texture2D:
	return _plugin_icons[icon_name]


func should_remove_source_files() -> bool:
	return _get_project_setting(REMOVE_SOURCE_FILES_KEY, true)


func is_default_animation_import_enabled() -> bool:
	return _get_project_setting(DEFAULT_IMPORT_ENABLED, true)


func is_default_animation_loop_enabled() -> bool:
	return _get_project_setting(DEFAULT_LOOP_ENABLED, true)


func is_default_wipe_old_anims_enabled() -> bool:
	return _get_project_setting(DEFAULT_WIPE_OLD_ANIMS_ENABLED, true)


	
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _default_command() -> String:
	return 'aseprite'


func _set_icons() -> void:
	_plugin_icons = {
		"collapsed": ei.get_base_control().get_icon("GuiTreeArrowRight", "EditorIcons"),
		"expanded": ei.get_base_control().get_icon("GuiTreeArrowDown", "EditorIcons"),
	}


func _initialize_project_cfg(key: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE):
	if not ProjectSettings.has_setting(key):
		ProjectSettings.set(key, default_value)
		ProjectSettings.set_initial_value(key, default_value)
		ProjectSettings.add_property_info({
			"name": key,
			"type": type,
			"hint": hint,
		})
		ProjectSettings.save()


func _get_project_setting(key: String, default_value):
	var p = ProjectSettings.get(key)
	return p if p != null else default_value
