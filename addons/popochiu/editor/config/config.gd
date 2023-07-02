@tool
extends RefCounted

# EDITOR SETTINGS
const _ASEPRITE_COMMAND_KEY = 'popochiu/import/aseprite/command_path'
const _REMOVE_SOURCE_FILES_KEY = 'popochiu/import/aseprite/remove_json_file'

# PROJECT SETTINGS

# Interface
const _DEFAULT_GRAPHIC_INTERFACE = 'popochiu/interface/graphic_interface'
const _DEFAULT_TRANSITION_LAYER = 'popochiu/interface/transition_layer'
const _DEFAULT_SCALE_GUI = 'popochiu/interface/scale_gui'
const _DEFAULT_INVENTORY_ALWAYS_VISIBLE = 'popochiu/interface/inventory_always_visible'
const _DEFAULT_TOOLBAR_ALWAYS_VISIBLE = 'popochiu/interface/toolbar_always_visible'
const _DEFAULT_FADE_COLOR = 'popochiu/interface/fade_color'
const _DEFAULT_SKIP_CUTSCENE_TIME = 'popochiu/interface/skip_cutscene_time'

# Text
const _DEFAULT_TEXT_SPEED = 'popochiu/text/text_speed'
const _DEFAULT_AUTO_CONTINUE_TEXT = 'popochiu/text/auto_continue_text'
const _DEFAULT_USE_TRANSLATIONS = 'popochiu/text/use_translations'
const _DEFAULT_MAX_DIALOG_OPTIONS = 'popochiu/text/max_dialog_options'

# Inventory
const _DEFAULT_INVENTORY_LIMIT = 'popochiu/inventory/inventory_limit'
const _DEFAULT_INVENTORY_ITEMS_ON_START = 'popochiu/inventory/items_on_start'

# Import
const _DEFAULT_IMPORT_ENABLED = 'popochiu/import/aseprite/import_animation_by_default'
const _DEFAULT_LOOP_ENABLED = 'popochiu/import/aseprite/loop_animation_by_default'
const _DEFAULT_WIPE_OLD_ANIMS_ENABLED = 'popochiu/import/aseprite/wipe_old_animations'


var ei: EditorInterface
var editor_settings: EditorSettings

var _plugin_icons: Dictionary


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func initialize_editor_settings():
	editor_settings = ei.get_editor_settings()
	_initialize_editor_cfg(_ASEPRITE_COMMAND_KEY, _default_command(), TYPE_STRING)
	_initialize_editor_cfg(_REMOVE_SOURCE_FILES_KEY, true, TYPE_BOOL)


func initialize_project_settings():
	_initialize_project_cfg(_DEFAULT_GRAPHIC_INTERFACE, "", TYPE_STRING, PROPERTY_HINT_FILE, "*tscn")
	_initialize_project_cfg(_DEFAULT_TRANSITION_LAYER, "", TYPE_STRING, PROPERTY_HINT_FILE, "*tscn")
	_initialize_project_cfg(_DEFAULT_SCALE_GUI, true, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_INVENTORY_ALWAYS_VISIBLE, false, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_TOOLBAR_ALWAYS_VISIBLE, false, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_FADE_COLOR, Color(0, 0, 0, 1), TYPE_COLOR)
	_initialize_project_cfg(_DEFAULT_SKIP_CUTSCENE_TIME, 0.2, TYPE_FLOAT)

	_initialize_project_cfg(_DEFAULT_TEXT_SPEED, 0.1, TYPE_FLOAT, PROPERTY_HINT_RANGE, "0.0,0.1")
	_initialize_project_cfg(_DEFAULT_AUTO_CONTINUE_TEXT, false, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_USE_TRANSLATIONS, false, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_MAX_DIALOG_OPTIONS, 3, TYPE_INT)

	_initialize_project_cfg(_DEFAULT_INVENTORY_LIMIT, 0, TYPE_INT)
	_initialize_project_cfg(_DEFAULT_INVENTORY_ITEMS_ON_START, [], TYPE_ARRAY,
		PROPERTY_HINT_TYPE_STRING, "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_FILE, "*tscn"]
	)

	_initialize_project_cfg(_DEFAULT_IMPORT_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_LOOP_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_DEFAULT_WIPE_OLD_ANIMS_ENABLED, true, TYPE_BOOL)

	_set_icons()
	ProjectSettings.save()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func get_command() -> String:
	return _get_editor_setting(_ASEPRITE_COMMAND_KEY, _default_command())


func should_remove_source_files() -> bool:
	return _get_editor_setting(_REMOVE_SOURCE_FILES_KEY, true)


func get_icon(icon_name: String) -> Texture2D:
	return _plugin_icons[icon_name]


func get_default_graphic_interface() -> PackedScene:
	return _get_project_setting(_DEFAULT_GRAPHIC_INTERFACE, "")


func get_default_transition_layer() -> PackedScene:
	return _get_project_setting(_DEFAULT_TRANSITION_LAYER, "")


func is_default_scale_gui() -> bool:
	return _get_project_setting(_DEFAULT_SCALE_GUI, true)


func is_default_inventory_always_visible() -> bool:
	return _get_project_setting(_DEFAULT_INVENTORY_ALWAYS_VISIBLE, false)


func is_default_toolbar_always_visible() -> bool:
	return _get_project_setting(_DEFAULT_TOOLBAR_ALWAYS_VISIBLE, false)


func get_default_fade_color() -> Color:
	return _get_project_setting(_DEFAULT_FADE_COLOR, Color(0, 0, 0, 1))


func get_default_skip_cutscene_time() -> float:
	return _get_project_setting(_DEFAULT_SKIP_CUTSCENE_TIME, 0.2)


func get_default_text_speed() -> float:
	return _get_project_setting(_DEFAULT_TEXT_SPEED, 0.1)


func is_default_auto_continue_text() -> bool:
	return _get_project_setting(_DEFAULT_AUTO_CONTINUE_TEXT, false)


func is_default_use_translations() -> bool:
	return _get_project_setting(_DEFAULT_USE_TRANSLATIONS, false)


func get_default_max_dialog_options() -> int:
	return _get_project_setting(_DEFAULT_MAX_DIALOG_OPTIONS, 3)


func get_default_inventory_limit() -> int:
	return _get_project_setting(_DEFAULT_INVENTORY_LIMIT, 0)


func get_default_inventory_items_on_start() -> Array[int]:
	return _get_project_setting(_DEFAULT_INVENTORY_ITEMS_ON_START, [])


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


func _initialize_editor_cfg(key: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE, hint_string: String = ""):
	if not editor_settings.has_setting(key):
		editor_settings.set_setting(key, default_value)
		editor_settings.set_initial_value(key, default_value, false)
		editor_settings.add_property_info({
			"name": key,
			"type": type,
			"hint": hint,
			"hint_string": hint_string,
		})

func _initialize_project_cfg(key: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE, hint_string: String = ""):
	if not ProjectSettings.has_setting(key):
		ProjectSettings.set_setting(key, default_value)
		ProjectSettings.set_initial_value(key, default_value)
		ProjectSettings.add_property_info({
			"name": key,
			"type": type,
			"hint": hint,
			"hint_string": hint_string,
		})


func _get_editor_setting(key: String, default_value):
	var e = editor_settings.get_setting(key)
	return e if e != null else default_value


func _get_project_setting(key: String, default_value):
	var p = ProjectSettings.get_setting(key)
	return p if p != null else default_value
