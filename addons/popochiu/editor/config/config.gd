@tool
extends RefCounted

# PROJECT SETTINGS
# general settings
const _ASEPRITE_COMMAND_KEY = 'popochiu/import/aseprite/command_path'

# animation import defaults
const _DEFAULT_IMPORT_ENABLED = 'popochiu/import/aseprite/import_animation_by_default'
const _DEFAULT_LOOP_ENABLED = 'popochiu/import/aseprite/loop_animation_by_default'
const _DEFAULT_WIPE_OLD_ANIMS_ENABLED = 'popochiu/import/aseprite/wipe_old_animations'
const _REMOVE_SOURCE_FILES_KEY = 'popochiu/import/aseprite/remove_json_file'


var ei: EditorInterface

var _plugin_icons: Dictionary


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func initialize_project_settings():
	_initialize_project_cfg(_ASEPRITE_COMMAND_KEY, _default_command(), TYPE_STRING)
	_initialize_project_cfg(_DEFAULT_IMPORT_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_LOOP_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_WIPE_OLD_ANIMS_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_REMOVE_SOURCE_FILES_KEY, true, TYPE_BOOL)

	_set_icons()
	ProjectSettings.save()


# TODO: this is never used, go and check if we need it
func clear_project_settings():
	var _all_settings = [
		_DEFAULT_IMPORT_ENABLED,
		_DEFAULT_LOOP_ENABLED,
		_DEFAULT_WIPE_OLD_ANIMS_ENABLED,
		_REMOVE_SOURCE_FILES_KEY,
	]
	for key in _all_settings:
		ProjectSettings.clear(key)
	ProjectSettings.save()



# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func get_command() -> String:
	var command = ProjectSettings.get_setting(_ASEPRITE_COMMAND_KEY) if ProjectSettings.has_setting(_ASEPRITE_COMMAND_KEY) else ""
	return command if command != "" else _default_command()


func get_icon(icon_name: String) -> Texture2D:
	return _plugin_icons[icon_name]


func should_remove_source_files() -> bool:
	return _get_project_setting(_REMOVE_SOURCE_FILES_KEY, true)


func is_default_animation_import_enabled() -> bool:
	return _get_project_setting(_DEFAULT_IMPORT_ENABLED, true)


func is_default_animation_loop_enabled() -> bool:
	return _get_project_setting(_DEFAULT_LOOP_ENABLED, true)


func is_default_wipe_old_anims_enabled() -> bool:
	return _get_project_setting(_DEFAULT_WIPE_OLD_ANIMS_ENABLED, true)


	
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _default_command() -> String:
	return 'aseprite'


func _set_icons() -> void:
	_plugin_icons = {
		"collapsed": ei.get_base_control().get_theme_icon("GuiTreeArrowRight", "EditorIcons"),
		"expanded": ei.get_base_control().get_theme_icon("GuiTreeArrowDown", "EditorIcons"),
	}


func _initialize_project_cfg(key: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE):
	if not ProjectSettings.has_setting(key):
		ProjectSettings.set_setting(key, default_value)
		ProjectSettings.set_initial_value(key, default_value)
		ProjectSettings.add_property_info({
			"name": key,
			"type": type,
			"hint": hint,
		})


func _get_project_setting(key: String, default_value):
	var p = ProjectSettings.get_setting(key)
	return p if p != null else default_value
