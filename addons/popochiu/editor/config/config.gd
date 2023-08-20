@tool
extends RefCounted

# EDITOR SETTINGS
const _ASEPRITE_IMPORTER_ENABLED_KEY = 'popochiu/import/aseprite/enable_aseprite_importer'
const _ASEPRITE_COMMAND_KEY = 'popochiu/import/aseprite/command_path'
const _REMOVE_SOURCE_FILES_KEY = 'popochiu/import/aseprite/remove_json_file'

# PROJECT SETTINGS
const _DEFAULT_IMPORT_ENABLED = 'popochiu/import/aseprite/import_animation_by_default'
const _DEFAULT_LOOP_ENABLED = 'popochiu/import/aseprite/loop_animation_by_default'
const _DEFAULT_PROP_VISIBLE_ENABLED = 'popochiu/import/aseprite/new_props_visible_by_default'
const _DEFAULT_PROP_CLICKABLE_ENABLED = 'popochiu/import/aseprite/new_props_clickable_by_default'
const _DEFAULT_WIPE_OLD_ANIMS_ENABLED = 'popochiu/import/aseprite/wipe_old_animations'


var ei := EditorInterface
var editor_settings: EditorSettings = ei.get_editor_settings()

var _plugin_icons: Dictionary


#region Public #####################################################################################
func initialize_editor_settings():
	_initialize_editor_cfg(_ASEPRITE_IMPORTER_ENABLED_KEY, false, TYPE_BOOL)
	_initialize_editor_cfg(_ASEPRITE_COMMAND_KEY, _default_command(), TYPE_STRING)
	_initialize_editor_cfg(_REMOVE_SOURCE_FILES_KEY, true, TYPE_BOOL)


func initialize_project_settings():
	_initialize_project_cfg(_DEFAULT_IMPORT_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_LOOP_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_PROP_VISIBLE_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_PROP_CLICKABLE_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_WIPE_OLD_ANIMS_ENABLED, true, TYPE_BOOL)

	_set_icons()
	ProjectSettings.save()


#endregion

#region SetGet #####################################################################################
func aseprite_importer_enabled() -> bool:
	return _get_editor_setting(_ASEPRITE_IMPORTER_ENABLED_KEY, false)


func get_command() -> String:
	return _get_editor_setting(_ASEPRITE_COMMAND_KEY, _default_command())


func should_remove_source_files() -> bool:
	return _get_editor_setting(_REMOVE_SOURCE_FILES_KEY, true)


func get_icon(icon_name: String) -> Texture2D:
	return _plugin_icons[icon_name]


func is_default_animation_import_enabled() -> bool:
	return _get_project_setting(_DEFAULT_IMPORT_ENABLED, true)


func is_default_animation_loop_enabled() -> bool:
	return _get_project_setting(_DEFAULT_LOOP_ENABLED, true)


func is_default_animation_prop_visible() -> bool:
	return _get_project_setting(_DEFAULT_PROP_VISIBLE_ENABLED, true)


func is_default_animation_prop_clickable() -> bool:
	return _get_project_setting(_DEFAULT_PROP_CLICKABLE_ENABLED, true)


func is_default_wipe_old_anims_enabled() -> bool:
	return _get_project_setting(_DEFAULT_WIPE_OLD_ANIMS_ENABLED, true)



#endregion

#region Private ####################################################################################
func _default_command() -> String:
	return 'aseprite'


func _set_icons() -> void:
	_plugin_icons = {
		"collapsed": ei.get_base_control().get_theme_icon("GuiTreeArrowRight", "EditorIcons"),
		"expanded": ei.get_base_control().get_theme_icon("GuiTreeArrowDown", "EditorIcons"),
	}


func _initialize_editor_cfg(key: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE):
	if not editor_settings.has_setting(key):
		editor_settings.set_setting(key, default_value)
		editor_settings.set_initial_value(key, default_value, false)
		editor_settings.add_property_info({
			"name": key,
			"type": type,
			"hint": hint,
		})


func _initialize_project_cfg(key: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE):
	if not ProjectSettings.has_setting(key):
		ProjectSettings.set_setting(key, default_value)
		ProjectSettings.set_initial_value(key, default_value)
		ProjectSettings.add_property_info({
			"name": key,
			"type": type,
			"hint": hint,
		})


func _get_editor_setting(key: String, default_value):
	var e = editor_settings.get_setting(key)
	return e if e != null else default_value


func _get_project_setting(key: String, default_value):
	var p = ProjectSettings.get_setting(key)
	return p if p != null else default_value


#endregion
