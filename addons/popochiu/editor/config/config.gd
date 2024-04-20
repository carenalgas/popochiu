@tool
class_name PopochiuConfig
extends RefCounted

enum DialogStyle {
	ABOVE_CHARACTER,
	PORTRAIT,
	CAPTION,
	PORTRAIT_ABOVE_CHARACTER,
	BUBBLE_ABOVE_CHARACTER,
}

# Thanks to @drbloop for providing the bases of the new approach for moving the popochiu settings to
# Godot's ProjectSettings instead of using a Resource file.
# ---- GUI -----------------------------------------------------------------------------------------
const SCALE_GUI = "popochiu/gui/experimental_scale_gui"
const FADE_COLOR = "popochiu/gui/fade_color"
const SKIP_CUTSCENE_TIME = "popochiu/gui/skip_cutscene_time"
const DIALOG_STYLE = "popochiu/gui/dialog_style"

# ---- Dialogs -------------------------------------------------------------------------------------
const TEXT_SPEED = "popochiu/dialogs/text_speed"
const AUTO_CONTINUE_TEXT = "popochiu/dialogs/auto_continue_text"
const USE_TRANSLATIONS = "popochiu/dialogs/use_translations"

# ---- Inventory -----------------------------------------------------------------------------------
const INVENTORY_LIMIT = "popochiu/inventory/inventory_limit"
const INVENTORY_ITEMS_ON_START = "popochiu/inventory/items_on_start"

# ---- Aseprite Importing --------------------------------------------------------------------------
const ASEPRITE_IMPORT_ANIMATION = "popochiu/aseprite_import/import_animation_by_default"
const ASEPRITE_LOOP_ANIMATION = "popochiu/aseprite_import/loop_animation_by_default"
const ASEPRITE_PROPS_VISIBLE = "popochiu/aseprite_import/new_props_visible_by_default"
const ASEPRITE_PROPS_CLICKABLE = "popochiu/aseprite_import/new_props_clickable_by_default"
const ASEPRITE_WIPE_OLD_ANIMATIONS = "popochiu/aseprite_import/wipe_old_animations"

# ---- Pixel game ----------------------------------------------------------------------------------
const PIXEL_ART_TEXTURES = "popochiu/pixel/pixel_art_textures"
const PIXEL_PERFECT = "popochiu/pixel/pixel_perfect"

# ---- DEV -----------------------------------------------------------------------------------------
const DEV_USE_ADDON_TEMPLATE = "popochiu/dev/use_addon_template"


#region Public #####################################################################################
static func initialize_project_settings():
	# ---- GUI -------------------------------------------------------------------------------------
	_initialize_project_setting(SCALE_GUI, false, TYPE_BOOL)
	_initialize_project_setting(FADE_COLOR, Color.BLACK, TYPE_COLOR)
	_initialize_project_setting(SKIP_CUTSCENE_TIME, 0.2, TYPE_FLOAT)
	
	# ---- Dialogs ---------------------------------------------------------------------------------
	_initialize_project_setting(TEXT_SPEED, 0.1, TYPE_FLOAT, PROPERTY_HINT_RANGE, "0.0,0.1")
	_initialize_project_setting(AUTO_CONTINUE_TEXT, false, TYPE_BOOL)
	_initialize_project_setting(USE_TRANSLATIONS, false, TYPE_BOOL)
	_initialize_project_setting(
		DIALOG_STYLE,
		DialogStyle.ABOVE_CHARACTER,
		TYPE_INT,
		PROPERTY_HINT_ENUM,
		# TODO: Add the other options: Portrait Above Character, Bubble Above Character
		"Above Character,Portrait,Caption"
	)
	
	# ---- Inventory -------------------------------------------------------------------------------
	_initialize_project_setting(INVENTORY_LIMIT, 0, TYPE_INT)
	_initialize_project_setting(INVENTORY_ITEMS_ON_START, [], TYPE_ARRAY,
		PROPERTY_HINT_TYPE_STRING, "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_FILE, "*tscn"]
	)
	
	# ---- Aseprite Importing ----------------------------------------------------------------------
	_initialize_project_setting(ASEPRITE_IMPORT_ANIMATION, true, TYPE_BOOL)
	_initialize_project_setting(ASEPRITE_LOOP_ANIMATION, true, TYPE_BOOL)
	_initialize_project_setting(ASEPRITE_PROPS_VISIBLE, true, TYPE_BOOL)
	_initialize_project_setting(ASEPRITE_PROPS_CLICKABLE, true, TYPE_BOOL)
	_initialize_project_setting(ASEPRITE_WIPE_OLD_ANIMATIONS, true, TYPE_BOOL)
	
	# ---- Pixel game ------------------------------------------------------------------------------
	_initialize_project_setting(PIXEL_ART_TEXTURES, false, TYPE_BOOL)
	_initialize_project_setting(PIXEL_PERFECT, false, TYPE_BOOL)
	
	# ---- DEV -------------------------------------------------------------------------------------
	_initialize_advanced_project_setting(DEV_USE_ADDON_TEMPLATE, false, TYPE_BOOL)
	
	ProjectSettings.save()


# ---- GUI -----------------------------------------------------------------------------------------
static func is_scale_gui() -> bool:
	return _get_project_setting(SCALE_GUI, false)


static func get_fade_color() -> Color:
	return _get_project_setting(FADE_COLOR, Color.BLACK)


static func get_skip_cutscene_time() -> float:
	return _get_project_setting(SKIP_CUTSCENE_TIME, 0.2)


# ---- Dialogs -------------------------------------------------------------------------------------
static func get_text_speed() -> float:
	return _get_project_setting(TEXT_SPEED, 0.1)


static func is_auto_continue_text() -> bool:
	return _get_project_setting(AUTO_CONTINUE_TEXT, false)


static func is_use_translations() -> bool:
	return _get_project_setting(USE_TRANSLATIONS, false)


static func get_dialog_style() -> int:
	return _get_project_setting(DIALOG_STYLE, DialogStyle.ABOVE_CHARACTER)


# ---- Inventory -----------------------------------------------------------------------------------
static func get_inventory_limit() -> int:
	return _get_project_setting(INVENTORY_LIMIT, 0)


static func set_inventory_items_on_start(items: Array) -> void:
	_set_project_setting(INVENTORY_ITEMS_ON_START, items)


static func get_inventory_items_on_start() -> Array:
	return _get_project_setting(INVENTORY_ITEMS_ON_START, [])


# ---- Aseprite Importing --------------------------------------------------------------------------
static func is_default_animation_import_enabled() -> bool:
	return _get_project_setting(ASEPRITE_IMPORT_ANIMATION, true)


static func is_default_animation_loop_enabled() -> bool:
	return _get_project_setting(ASEPRITE_LOOP_ANIMATION, true)


static func is_default_animation_prop_visible() -> bool:
	return _get_project_setting(ASEPRITE_PROPS_VISIBLE, true)


static func is_default_animation_prop_clickable() -> bool:
	return _get_project_setting(ASEPRITE_PROPS_CLICKABLE, true)


static func is_default_wipe_old_anims_enabled() -> bool:
	return _get_project_setting(ASEPRITE_WIPE_OLD_ANIMATIONS, true)


# ---- Pixel game ----------------------------------------------------------------------------------
static func set_pixel_art_textures(use_pixel_art_textures: bool) -> void:
	_set_project_setting(PIXEL_ART_TEXTURES, use_pixel_art_textures)


static func is_pixel_art_textures() -> bool:
	return _get_project_setting(PIXEL_ART_TEXTURES, false)


static func is_pixel_perfect() -> bool:
	return _get_project_setting(PIXEL_PERFECT, false)


# ---- DEV -----------------------------------------------------------------------------------------
static func is_use_addon_template() -> bool:
	return _get_project_setting(DEV_USE_ADDON_TEMPLATE, false)


#endregion

#region Private ####################################################################################
static func _initialize_project_setting(
	key: String, default_value, type: int, hint := PROPERTY_HINT_NONE, hint_string := ""
) -> void:
	if ProjectSettings.has_setting(key): return
	
	_create_setting(key, default_value, type, hint)
	ProjectSettings.set_as_basic(key, true)


static func _initialize_advanced_project_setting(
	key: String, default_value, type: int, hint := PROPERTY_HINT_NONE, hint_string := ""
) -> void:
	_create_setting(key, default_value, type, hint)


static func _create_setting(
	key: String, default_value, type: int, hint := PROPERTY_HINT_NONE, hint_string := ""
) -> void:
	ProjectSettings.set_setting(key, default_value)
	ProjectSettings.set_initial_value(key, default_value)
	ProjectSettings.add_property_info({
		"name": key,
		"type": type,
		"hint": hint,
		"hint_string": hint_string,
	})


static func _get_project_setting(key: String, default_value):
	var p = ProjectSettings.get_setting(key)
	return p if p != null else default_value


static func _set_project_setting(key: String, value) -> void:
	ProjectSettings.set_setting(key, value)
	ProjectSettings.save()


#endregion
