tool
extends Reference

# PROJECT SETTINGS

# general settings
#const _CONFIG_SECTION_KEY = 'aseprite'
const _ASEPRITE_COMMAND_KEY = 'popochiu/import/aseprite/command_path'

# animation import defaults
const _DEFAULT_EXCLUSION_PATTERN_KEY = 'popochiu/import/aseprite/layers_exclusion_pattern'
const _DEFAULT_LOOP_EX_PREFIX = '_'
## TODO: change the logic of this option: nail a behavior and exclude with a prefix
const _LOOP_ENABLED = 'popochiu/import/aseprite/loop_enabled'
const _LOOP_EXCEPTION_PREFIX = 'popochiu/import/aseprite/loop_exception_prefix'
## TODO: evalutate if this has to be an option or if we'd better ALWAYS use metadata + remove them at build
const _REMOVE_SOURCE_FILES_KEY = 'popochiu/import/aseprite/remove_json_file'
## TODO: ALWAYS use (end remove) metadata
# const _USE_METADATA = 'popochiu/import/aseprite/use_metadata'
# const _REMOVE_METADATA_ON_EXPORT_KEY = 'popochiu/import/aseprite/remove_metadata_on_export'

# INTERFACE SETTINGS
var _plugin_icons: Dictionary


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


func is_default_animation_loop_enabled() -> bool:
	return _get_project_setting(_LOOP_ENABLED, true)


func get_animation_loop_exception_prefix() -> String:
	return _get_project_setting(_LOOP_EXCEPTION_PREFIX, _DEFAULT_LOOP_EX_PREFIX)
	
# func is_use_metadata_enabled() -> bool:
# 	return _get_project_setting(_USE_METADATA, true)

## TODO: decide if testing this on export or separating the export plugin and register it
## only if necessary
# func is_remove_metadata_on_export() -> bool:
# 	return _get_project_setting(_REMOVE_METADATA_ON_EXPORT_KEY, true)


func get_default_exclusion_pattern() -> String:
	return _get_project_setting(_DEFAULT_EXCLUSION_PATTERN_KEY, "")



#######################################################
# INTERFACE SETTINGS
######################################################

func set_icons(plugin_icons: Dictionary) -> void:
	_plugin_icons = plugin_icons


func get_icon(icon_name: String) -> Texture:
	return _plugin_icons[icon_name]


#######################################################
# INITIALIZATION
######################################################
func initialize_project_settings():
	_initialize_project_cfg(_ASEPRITE_COMMAND_KEY, default_command(), TYPE_STRING)
	_initialize_project_cfg(_DEFAULT_EXCLUSION_PATTERN_KEY, "", TYPE_STRING)
	_initialize_project_cfg(_LOOP_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_LOOP_EXCEPTION_PREFIX, _DEFAULT_LOOP_EX_PREFIX, TYPE_STRING)
	_initialize_project_cfg(_REMOVE_SOURCE_FILES_KEY, true, TYPE_BOOL)
	
	# _initialize_project_cfg(_USE_METADATA, true, TYPE_BOOL)
	# _initialize_project_cfg(_EXPORTER_ENABLE_KEY, true, TYPE_BOOL)

	ProjectSettings.save()



func clear_project_settings():
	var _all_settings = [
		_DEFAULT_EXCLUSION_PATTERN_KEY,
		_LOOP_ENABLED,
		_LOOP_EXCEPTION_PREFIX,
		_REMOVE_SOURCE_FILES_KEY,
		# _USE_METADATA,
		# _EXPORTER_ENABLE_KEY,
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
	return p if p else default_value
