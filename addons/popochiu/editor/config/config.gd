@tool
extends RefCounted

enum DialogStyle {
	ABOVE_CHARACTER,
	PORTRAIT,
	CAPTION,
	PORTRAIT_ABOVE_CHARACTER,
	BUBBLE_ABOVE_CHARACTER,
}

# EDITOR SETTINGS ----------------------------------------------------------------------------------
const ASEPRITE_IMPORTER_ENABLED = "popochiu/import/aseprite/enable_aseprite_importer"
const ASEPRITE_COMMAND_PATH = "popochiu/import/aseprite/command_path"
const ASEPRITE_REMOVE_JSON_FILE = "popochiu/import/aseprite/remove_json_file"

# PROJECT SETTINGS ---------------------------------------------------------------------------------
# Thanks to @drbloop for providing the bases of the new approach for moving the popochiu settings to
# Godot's ProjectSettings instead of using a Resource file.
# ---- GUI -----------------------------------------------------------------------------------------
const SCALE_GUI = "popochiu/gui/scale_gui"
const INVENTORY_ALWAYS_VISIBLE = "popochiu/gui/inventory_always_visible"
const TOOLBAR_ALWAYS_VISIBLE = "popochiu/gui/toolbar_always_visible"
const FADE_COLOR = "popochiu/gui/fade_color"
const SKIP_CUTSCENE_TIME = "popochiu/gui/skip_cutscene_time"
const DIALOG_STYLE = "popochiu/gui/dialog_style"

# ---- Dialogs -------------------------------------------------------------------------------------
const TEXT_SPEED = "popochiu/dialogs/text_speed"
const AUTO_CONTINUE_TEXT = "popochiu/dialogs/auto_continue_text"
const USE_TRANSLATIONS = "popochiu/dialogs/use_translations"
const MAX_DIALOG_OPTIONS = "popochiu/dialogs/max_dialog_options"

# ---- Inventory -----------------------------------------------------------------------------------
const INVENTORY_LIMIT = "popochiu/inventory/inventory_limit"
const INVENTORY_ITEMS_ON_START = "popochiu/inventory/items_on_start"

# ---- Aseprite Importing --------------------------------------------------------------------------
const ASEPRITE_IMPORT_ANIMATION = "popochiu/import/aseprite/import_animation_by_default"
const ASEPRITE_LOOP_ANIMATION = "popochiu/import/aseprite/loop_animation_by_default"
const ASEPRITE_PROPS_VISIBLE = "popochiu/import/aseprite/new_props_visible_by_default"
const ASEPRITE_PROPS_CLICKABLE = "popochiu/import/aseprite/new_props_clickable_by_default"
const ASEPRITE_WIPE_OLD_ANIMATIONS = "popochiu/import/aseprite/wipe_old_animations"

# ---- Pixel game ----------------------------------------------------------------------------------
const PIXEL_ART_TEXTURES = "popochiu/pixel/pixel_art_textures"
const PIXEL_PERFECT = "popochiu/pixel/pixel_perfect"

var editor_settings: EditorSettings

var _plugin_icons: Dictionary


#region Public #####################################################################################
func initialize_editor_settings():
	editor_settings = EditorInterface.get_editor_settings()
	
	_initialize_editor_cfg(ASEPRITE_IMPORTER_ENABLED, false, TYPE_BOOL)
	_initialize_editor_cfg(ASEPRITE_COMMAND_PATH, _default_command(), TYPE_STRING)
	_initialize_editor_cfg(ASEPRITE_REMOVE_JSON_FILE, true, TYPE_BOOL)


func initialize_project_settings():
	# ---- GUI -------------------------------------------------------------------------------------
	_initialize_project_cfg(SCALE_GUI, false, TYPE_BOOL)
	# TODO: Move this to the properties of the 2-click Context-sensitive template or its InventoryBar
	# 		component
	_initialize_project_cfg(INVENTORY_ALWAYS_VISIBLE, false, TYPE_BOOL)
	# TODO: Move this to the properties of the 2-click Context-sensitive template or its SettingsBar
	# 		component
	_initialize_project_cfg(TOOLBAR_ALWAYS_VISIBLE, false, TYPE_BOOL)
	_initialize_project_cfg(FADE_COLOR, Color.BLACK, TYPE_COLOR)
	_initialize_project_cfg(SKIP_CUTSCENE_TIME, 0.2, TYPE_FLOAT)
	# ---- Dialogs ---------------------------------------------------------------------------------
	_initialize_project_cfg(TEXT_SPEED, 0.1, TYPE_FLOAT, PROPERTY_HINT_RANGE, "0.0,0.1")
	_initialize_project_cfg(AUTO_CONTINUE_TEXT, false, TYPE_BOOL)
	_initialize_project_cfg(USE_TRANSLATIONS, false, TYPE_BOOL)
	_initialize_project_cfg(MAX_DIALOG_OPTIONS, 3, TYPE_INT)
	_initialize_project_cfg(
		DIALOG_STYLE,
		DialogStyle.ABOVE_CHARACTER,
		TYPE_INT,
		PROPERTY_HINT_ENUM,
		# TODO: Add the other options: Portrait Above Character, Bubble Above Character
		"Above Character,Portrait,Caption"
	)
	# ---- Inventory -------------------------------------------------------------------------------
	_initialize_project_cfg(INVENTORY_LIMIT, 0, TYPE_INT)
	_initialize_project_cfg(INVENTORY_ITEMS_ON_START, [], TYPE_ARRAY,
		PROPERTY_HINT_TYPE_STRING, "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_FILE, "*tscn"]
	)
	# ---- Aseprite Importing ----------------------------------------------------------------------
	_initialize_project_cfg(ASEPRITE_IMPORT_ANIMATION, true, TYPE_BOOL)
	_initialize_project_cfg(ASEPRITE_LOOP_ANIMATION, true, TYPE_BOOL)
	_initialize_project_cfg(ASEPRITE_PROPS_VISIBLE, true, TYPE_BOOL)
	_initialize_project_cfg(ASEPRITE_PROPS_CLICKABLE, true, TYPE_BOOL)
	_initialize_project_cfg(ASEPRITE_WIPE_OLD_ANIMATIONS, true, TYPE_BOOL)
	# ---- Pixel game ------------------------------------------------------------------------------
	_initialize_project_cfg(PIXEL_ART_TEXTURES, false, TYPE_BOOL)
	_initialize_project_cfg(PIXEL_PERFECT, false, TYPE_BOOL)

	_set_icons()
	ProjectSettings.save()


func get_icon(icon_name: String) -> Texture2D:
	return _plugin_icons[icon_name]


# EDITOR -------------------------------------------------------------------------------------------
func aseprite_importer_enabled() -> bool:
	return _get_editor_setting(ASEPRITE_IMPORTER_ENABLED, false)


func get_command() -> String:
	return _get_editor_setting(ASEPRITE_COMMAND_PATH, _default_command())


func should_remove_source_files() -> bool:
	return _get_editor_setting(ASEPRITE_REMOVE_JSON_FILE, true)


# PROJECT ------------------------------------------------------------------------------------------
# ---- GUI -----------------------------------------------------------------------------------------
func is_scale_gui() -> bool:
	return _get_project_setting(SCALE_GUI, false)


# TODO: Move this to the properties of the 2-click Context-sensitive template or its InventoryBar
# 		component
func is_inventory_always_visible() -> bool:
	return _get_project_setting(INVENTORY_ALWAYS_VISIBLE, false)


# TODO: Move this to the properties of the 2-click Context-sensitive template or its SettingsBar
# 		component
func is_toolbar_always_visible() -> bool:
	return _get_project_setting(TOOLBAR_ALWAYS_VISIBLE, false)


func get_fade_color() -> Color:
	return _get_project_setting(FADE_COLOR, Color.BLACK)


func get_skip_cutscene_time() -> float:
	return _get_project_setting(SKIP_CUTSCENE_TIME, 0.2)


# ---- Dialogs -------------------------------------------------------------------------------------
func get_text_speed() -> float:
	return _get_project_setting(TEXT_SPEED, 0.1)


func is_auto_continue_text() -> bool:
	return _get_project_setting(AUTO_CONTINUE_TEXT, false)


func is_use_translations() -> bool:
	return _get_project_setting(USE_TRANSLATIONS, false)


func get_max_dialog_options() -> int:
	return _get_project_setting(MAX_DIALOG_OPTIONS, 3)


func get_dialog_style() -> int:
	return _get_project_setting(DIALOG_STYLE, DialogStyle.ABOVE_CHARACTER)


# ---- Inventory -----------------------------------------------------------------------------------
func get_inventory_limit() -> int:
	return _get_project_setting(INVENTORY_LIMIT, 0)


func get_inventory_items_on_start() -> Array:
	return _get_project_setting(INVENTORY_ITEMS_ON_START, [])


# ---- Aseprite Importing --------------------------------------------------------------------------
func is_default_animation_import_enabled() -> bool:
	return _get_project_setting(ASEPRITE_IMPORT_ANIMATION, true)


func is_default_animation_loop_enabled() -> bool:
	return _get_project_setting(ASEPRITE_LOOP_ANIMATION, true)


func is_default_animation_prop_visible() -> bool:
	return _get_project_setting(ASEPRITE_PROPS_VISIBLE, true)


func is_default_animation_prop_clickable() -> bool:
	return _get_project_setting(ASEPRITE_PROPS_CLICKABLE, true)


func is_default_wipe_old_anims_enabled() -> bool:
	return _get_project_setting(ASEPRITE_WIPE_OLD_ANIMATIONS, true)


# ---- Pixel game ----------------------------------------------------------------------------------
func is_pixel_art_textures() -> bool:
	return _get_project_setting(PIXEL_ART_TEXTURES, false)


func is_pixel_perfect() -> bool:
	return _get_project_setting(PIXEL_PERFECT, false)


#endregion

#region Private ####################################################################################
func _default_command() -> String:
	return 'aseprite'


func _set_icons() -> void:
	_plugin_icons = {
		"collapsed": EditorInterface.get_base_control().get_theme_icon(
			"GuiTreeArrowRight", "EditorIcons"
		),
		"expanded": EditorInterface.get_base_control().get_theme_icon(
			"GuiTreeArrowDown", "EditorIcons"
		),
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


func _initialize_project_cfg(
	key: String, default_value, type: int, hint := PROPERTY_HINT_NONE, hint_string := ""
):
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


#endregion
