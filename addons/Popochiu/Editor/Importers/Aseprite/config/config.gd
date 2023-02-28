tool
extends Reference

# PROJECT SETTINGS

# general settings
const _ASEPRITE_COMMAND_KEY = 'popochiu/import/aseprite/command_path'

# animation import defaults
const _DEFAULT_IMPORT_ENABLED = 'popochiu/import/aseprite/import_animation_by_default'
const _DEFAULT_LOOP_ENABLED = 'popochiu/import/aseprite/loop_animation_by_default'
const _DEFAULT_WIPE_OLD_ANIMS_ENABLED = 'popochiu/import/aseprite/wipe_old_animations'
const _REMOVE_SOURCE_FILES_KEY = 'popochiu/import/aseprite/remove_json_file'

# INTERFACE SETTINGS
var _plugin_icons: Dictionary
var ei: EditorInterface


#######################################################
# PROJECT SETTINGS
######################################################
func default_command() -> String:
	return 'aseprite'


func get_command() -> String:
	var command = ProjectSettings.get_setting(_ASEPRITE_COMMAND_KEY) if ProjectSettings.has_setting(_ASEPRITE_COMMAND_KEY) else ""
	return command if command != "" else default_command()

func should_remove_source_files() -> bool:
	return _get_project_setting(_REMOVE_SOURCE_FILES_KEY, true)

func is_default_animation_import_enabled() -> bool:
	return _get_project_setting(_DEFAULT_IMPORT_ENABLED, true)

func is_default_animation_loop_enabled() -> bool:
	return _get_project_setting(_DEFAULT_LOOP_ENABLED, true)

func is_default_wipe_old_anims_enabled() -> bool:
	return _get_project_setting(_DEFAULT_WIPE_OLD_ANIMS_ENABLED, true)

#######################################################
# INTERFACE SETTINGS
######################################################

func _set_icons() -> void:
	_plugin_icons = {
		"collapsed": ei.get_base_control().get_icon("GuiTreeArrowRight", "EditorIcons"),
		"expanded": ei.get_base_control().get_icon("GuiTreeArrowDown", "EditorIcons"),
	}


func get_icon(icon_name: String) -> Texture:
	return _plugin_icons[icon_name]


#######################################################
# INITIALIZATION
######################################################
func initialize_project_settings():
	_initialize_project_cfg(_ASEPRITE_COMMAND_KEY, default_command(), TYPE_STRING)
	_initialize_project_cfg(_DEFAULT_IMPORT_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_LOOP_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_WIPE_OLD_ANIMS_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_REMOVE_SOURCE_FILES_KEY, true, TYPE_BOOL)

	_set_icons()
	
	ProjectSettings.save()


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
