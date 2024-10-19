@tool
class_name PopochiuConfig
extends RefCounted

enum DialogStyle {
	ABOVE_CHARACTER,
	PORTRAIT,
	CAPTION,
	#PORTRAIT_ABOVE_CHARACTER, # TODO: Create a GUI node to make this option available
	#BUBBLE_ABOVE_CHARACTER, # TODO: Create a GUI node to make this option available
}

# Thanks to @drbloop for providing the bases of the new approach for moving the popochiu settings to
# Godot's ProjectSettings instead of using a Resource file.
# ---- GUI -----------------------------------------------------------------------------------------
const SCALE_GUI = "popochiu/gui/experimental_scale_gui"
const FADE_COLOR = "popochiu/gui/fade_color"
const SKIP_CUTSCENE_TIME = "popochiu/gui/skip_cutscene_time"
const TL_FIRST_ROOM = "popochiu/gui/show_transition_layer_in_first_room"

# ---- Dialogs -------------------------------------------------------------------------------------
const TEXT_SPEED = "popochiu/dialogs/text_speed"
const AUTO_CONTINUE_TEXT = "popochiu/dialogs/auto_continue_text"
const USE_TRANSLATIONS = "popochiu/dialogs/use_translations"
const GIBBERISH_SPOKEN_TEXT = 'popochiu/dialogs/gibberish_spoken_text'
const GIBBERISH_DIALOG_OPTIONS = 'popochiu/dialogs/gibberish_dialog_options'
const DIALOG_STYLE = "popochiu/dialogs/dialog_style"

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

# ---- Audio ---------------------------------------------------------------------------------------
const PREFIX_CHARACTER = "popochiu/audio/prefix_character"
const MUSIC_PREFIXES = "popochiu/audio/music_prefixes"
const SOUND_EFFECT_PREFIXES = "popochiu/audio/sound_effect_prefixes"
const VOICE_PREFIXES = "popochiu/audio/voice_prefixes"
const UI_PREFIXES = "popochiu/audio/ui_prefixes"

# ---- DEV -----------------------------------------------------------------------------------------
const DEV_USE_ADDON_TEMPLATE = "popochiu/dev/use_addon_template"

static var defaults := {
	SCALE_GUI: false,
	FADE_COLOR: Color.BLACK,
	SKIP_CUTSCENE_TIME: 0.2,
	TL_FIRST_ROOM: false,
	TEXT_SPEED: 0.1,
	AUTO_CONTINUE_TEXT: false,
	USE_TRANSLATIONS: false,
	GIBBERISH_SPOKEN_TEXT: false,
	GIBBERISH_DIALOG_OPTIONS: false,
	DIALOG_STYLE: DialogStyle.ABOVE_CHARACTER,
	INVENTORY_LIMIT: 0,
	INVENTORY_ITEMS_ON_START: [],
	ASEPRITE_IMPORT_ANIMATION: true,
	ASEPRITE_LOOP_ANIMATION: true,
	ASEPRITE_PROPS_VISIBLE: true,
	ASEPRITE_PROPS_CLICKABLE: true,
	ASEPRITE_WIPE_OLD_ANIMATIONS: true,
	PIXEL_ART_TEXTURES: false,
	PIXEL_PERFECT: false,
	PREFIX_CHARACTER: "_",
	MUSIC_PREFIXES: "mx,",
	SOUND_EFFECT_PREFIXES: "sfx,",
	VOICE_PREFIXES: "vo,",
	UI_PREFIXES: "ui,",
	DEV_USE_ADDON_TEMPLATE: false,
}


#region Public #####################################################################################
static func initialize_project_settings():
	# ---- GUI -------------------------------------------------------------------------------------
	_initialize_project_setting(SCALE_GUI, TYPE_BOOL)
	_initialize_project_setting(FADE_COLOR, TYPE_COLOR)
	_initialize_project_setting(SKIP_CUTSCENE_TIME, TYPE_FLOAT)
	_initialize_project_setting(TL_FIRST_ROOM, TYPE_BOOL)
	
	# ---- Dialogs ---------------------------------------------------------------------------------
	_initialize_project_setting(TEXT_SPEED, TYPE_FLOAT, PROPERTY_HINT_RANGE, "0.0,0.1")
	_initialize_project_setting(AUTO_CONTINUE_TEXT, TYPE_BOOL)
	#_initialize_project_setting(USE_TRANSLATIONS, TYPE_BOOL)
	#_initialize_project_setting(
		#DIALOG_STYLE,
		#TYPE_INT,
		#PROPERTY_HINT_ENUM,
		## TODO: Add other options: Portrait Above Character, Bubble Above Character
		#"Above Character,Portrait,Caption"
	#)
	_initialize_project_setting(GIBBERISH_SPOKEN_TEXT, TYPE_BOOL)
	_initialize_project_setting(GIBBERISH_DIALOG_OPTIONS, TYPE_BOOL)
	
	# ---- Inventory -------------------------------------------------------------------------------
	_initialize_project_setting(INVENTORY_LIMIT, TYPE_INT)
	_initialize_project_setting(
		INVENTORY_ITEMS_ON_START,
		TYPE_ARRAY,
		PROPERTY_HINT_TYPE_STRING,
		"%d:" % [TYPE_STRING]
	)
	
	# ---- Aseprite Importing ----------------------------------------------------------------------
	_initialize_project_setting(ASEPRITE_IMPORT_ANIMATION, TYPE_BOOL)
	_initialize_project_setting(ASEPRITE_LOOP_ANIMATION, TYPE_BOOL)
	_initialize_project_setting(ASEPRITE_PROPS_VISIBLE, TYPE_BOOL)
	_initialize_project_setting(ASEPRITE_PROPS_CLICKABLE, TYPE_BOOL)
	_initialize_project_setting(ASEPRITE_WIPE_OLD_ANIMATIONS, TYPE_BOOL)
	
	# ---- Pixel game ------------------------------------------------------------------------------
	_initialize_project_setting(PIXEL_ART_TEXTURES, TYPE_BOOL)
	_initialize_project_setting(PIXEL_PERFECT, TYPE_BOOL)

	# ---- Audio -----------------------------------------------------------------------------------
	_initialize_project_setting(PREFIX_CHARACTER, TYPE_STRING)
	_initialize_project_setting(MUSIC_PREFIXES, TYPE_STRING)
	_initialize_project_setting(SOUND_EFFECT_PREFIXES, TYPE_STRING)
	_initialize_project_setting(VOICE_PREFIXES, TYPE_STRING)
	_initialize_project_setting(UI_PREFIXES, TYPE_STRING)
	
	# ---- DEV -------------------------------------------------------------------------------------
	_initialize_advanced_project_setting(DEV_USE_ADDON_TEMPLATE, TYPE_BOOL)
	
	ProjectSettings.save()


static func set_project_setting(key: String, value) -> void:
	ProjectSettings.set_setting(key, value)
	ProjectSettings.save()


# ---- GUI -----------------------------------------------------------------------------------------
static func is_scale_gui() -> bool:
	return _get_project_setting(SCALE_GUI)


static func get_fade_color() -> Color:
	return _get_project_setting(FADE_COLOR)


static func get_skip_cutscene_time() -> float:
	return _get_project_setting(SKIP_CUTSCENE_TIME)

static func should_show_tl_in_first_room() -> bool:
	return _get_project_setting(TL_FIRST_ROOM)


# ---- Dialogs -------------------------------------------------------------------------------------
static func get_text_speed() -> float:
	return _get_project_setting(TEXT_SPEED)


static func is_auto_continue_text() -> bool:
	return _get_project_setting(AUTO_CONTINUE_TEXT)


static func is_use_translations() -> bool:
	return _get_project_setting(USE_TRANSLATIONS)


static func get_dialog_style() -> int:
	return _get_project_setting(DIALOG_STYLE)


static func should_talk_gibberish() -> bool:
	return _get_project_setting(GIBBERISH_SPOKEN_TEXT)


static func should_dialog_options_be_gibberish() -> bool:
	return _get_project_setting(GIBBERISH_DIALOG_OPTIONS)


# ---- Inventory -----------------------------------------------------------------------------------
static func get_inventory_limit() -> int:
	return _get_project_setting(INVENTORY_LIMIT)


static func set_inventory_items_on_start(items: Array) -> void:
	set_project_setting(INVENTORY_ITEMS_ON_START, items)


static func get_inventory_items_on_start() -> Array:
	return _get_project_setting(INVENTORY_ITEMS_ON_START)


# ---- Aseprite Importing --------------------------------------------------------------------------
static func is_default_animation_import_enabled() -> bool:
	return _get_project_setting(ASEPRITE_IMPORT_ANIMATION)


static func is_default_animation_loop_enabled() -> bool:
	return _get_project_setting(ASEPRITE_LOOP_ANIMATION)


static func is_default_animation_prop_visible() -> bool:
	return _get_project_setting(ASEPRITE_PROPS_VISIBLE)


static func is_default_animation_prop_clickable() -> bool:
	return _get_project_setting(ASEPRITE_PROPS_CLICKABLE)


static func is_default_wipe_old_anims_enabled() -> bool:
	return _get_project_setting(ASEPRITE_WIPE_OLD_ANIMATIONS)


# ---- Pixel game ----------------------------------------------------------------------------------
static func set_pixel_art_textures(use_pixel_art_textures: bool) -> void:
	set_project_setting(PIXEL_ART_TEXTURES, use_pixel_art_textures)


static func is_pixel_art_textures() -> bool:
	return _get_project_setting(PIXEL_ART_TEXTURES)


static func is_pixel_perfect() -> bool:
	return _get_project_setting(PIXEL_PERFECT)


# ---- Audio ---------------------------------------------------------------------------------------
static func get_prefix_character() -> String:
	return _get_project_setting(PREFIX_CHARACTER)


static func get_music_prefixes() -> String:
	return _get_project_setting(MUSIC_PREFIXES)


static func get_sound_effect_prefixes() -> String:
	return _get_project_setting(SOUND_EFFECT_PREFIXES)


static func get_voice_prefixes() -> String:
	return _get_project_setting(VOICE_PREFIXES)


static func get_ui_prefixes() -> String:
	return _get_project_setting(UI_PREFIXES)


# ---- DEV -----------------------------------------------------------------------------------------
static func is_use_addon_template() -> bool:
	return _get_project_setting(DEV_USE_ADDON_TEMPLATE)


#endregion

#region Private ####################################################################################
static func _initialize_project_setting(
	key: String, type: int, hint := PROPERTY_HINT_NONE, hint_string := ""
) -> void:
	_create_setting(key, type, hint, hint_string)
	ProjectSettings.set_as_basic(key, true)


static func _initialize_advanced_project_setting(
	key: String, type: int, hint := PROPERTY_HINT_NONE, hint_string := ""
) -> void:
	_create_setting(key, type, hint, hint_string)


static func _create_setting(
	key: String, type: int, hint := PROPERTY_HINT_NONE, hint_string := ""
) -> void:
	ProjectSettings.set_setting(key, ProjectSettings.get_setting(key, defaults[key]))
	ProjectSettings.set_initial_value(key, defaults[key])
	ProjectSettings.add_property_info({
		"name": key,
		"type": type,
		"hint": hint,
		"hint_string": hint_string,
	})


static func _get_project_setting(key: String):
	var p = ProjectSettings.get_setting(key)
	return p if p != null else defaults[key]


#endregion
