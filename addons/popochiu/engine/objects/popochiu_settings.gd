@tool
class_name PopochiuSettings
extends Resource
## Defines properties as settings for the game.

## @deprecated
const ImporterDefaults := preload("res://addons/popochiu/engine/others/importer_defaults.gd")

# ---- GUI -----------------------------------------------------------------------------------------
#const GRAPHIC_INTERFACE = "popochiu/gui/graphic_interface"
#const TRANSITION_LAYER = "popochiu/gui/transition_layer"
const SCALE_GUI = "popochiu/gui/scale_gui"
const INVENTORY_ALWAYS_VISIBLE = "popochiu/gui/inventory_always_visible"
const TOOLBAR_ALWAYS_VISIBLE = "popochiu/gui/toolbar_always_visible"
const FADE_COLOR = "popochiu/gui/fade_color"
const SKIP_CUTSCENE_TIME = "popochiu/gui/skip_cutscene_time"

# ---- Dialogs -------------------------------------------------------------------------------------
const TEXT_SPEED = "popochiu/dialogs/text_speed"
const AUTO_CONTINUE_TEXT = "popochiu/dialogs/auto_continue_text"
const USE_TRANSLATIONS = "popochiu/dialogs/use_translations"
const MAX_DIALOG_OPTIONS = "popochiu/dialogs/max_dialog_options"

# ---- Inventory -----------------------------------------------------------------------------------
const INVENTORY_LIMIT = "popochiu/inventory/inventory_limit"
const INVENTORY_ITEMS_ON_START = "popochiu/inventory/items_on_start"

# ---- Aseprite Importing --------------------------------------------------------------------------
const IMPORT_ENABLED = "popochiu/aseprite/import_animation_by_default"
const LOOP_ENABLED = "popochiu/aseprite/loop_animation_by_default"
const WIPE_OLD_ANIMS_ENABLED = "popochiu/aseprite/wipe_old_animations"

# TODO: Deprecate this property. There is no need for this anymore since we have to GUI templates,
# 		and a tab dedicated to the GUI.
## A reference to the scene used as the GUI for the game.
## This will be [color=bf5a50]deprecated[/color].
@export var graphic_interface: PackedScene = null
# TODO: Deprecate this property. The TransitionLayer could be also part of the GUI tab. And we need
# 		a cleaner way to give devs tools to customize this. Maybe we can take a look to the
# 		SceneManager (https://github.com/glass-brick/Scene-Manager) plugin to see how it handles
# 		transitions.
## A reference to the scene used as to handle transition animations between rooms and other game
## events.
## This will be [color=bf5a50]deprecated[/color].
@export var transition_layer: PackedScene = null
## The time, in seconds, that will take the game to skip a cutscene.
@export var skip_cutscene_time := 0.2
## The text speed options that will be available in the game. In the ContextSensitive GUI you can
## loop between them usin the text speed button in the SettingsBar.
@export var text_speeds := [0.1, 0.01, 0.0]
## The index of the default text speed value in [member text_speeds].
@export var default_text_speed := 0
## If [code]true[/code], then dialog lines should auto continue once the animation that shows them
## finishes. Otherwise, players will have to click the screen in order to continue.
@export var auto_continue_text := false
## When [code]true[/code] the game will call [method Object.tr] when getting the texts to show in
## the game.
@export var use_translations := false
## An array with the [code]script_name[/code] of the inventory items that will be added to the
## inventory when the game starts. You can use the context menu in front of each inventory item in
## Popochiu's Main tab to add or remove items from start with the
## [img]res://addons/popochiu/icons/inventory_item_start.png[/img] [b]Start with it[/b] option.
@export var items_on_start := []
## The max number of items players will be able to put in the inventory.
@export var inventory_limit := 0
## Whether the inventory will be always visible, or players will have to do something to make it
## appear. [b]This is specific to the ContextSensitive GUI[/b].
@export var inventory_always_visible := false
## Whether the toolbar (SettingsBar) will be always visible, or players will have to do something to
## make it appear. [b]This is specific to the ContextSensitive GUI[/b].
@export var toolbar_always_visible := false
## The color the screen changes to it plays a transition (e.g. move between rooms, skip a cutscene).
@export var fade_color: Color = Color.BLACK
## Whether the GUI should scale to match the native game resolution. The default GUI has a 320x180
## resolution.
@export var scale_gui := true
## The number of dialog options to show before showing a scroll bar to render those that exceed this
## limit.
@export var max_dialog_options := 3
## If [code]true[/code], the [member CanvasItem.texture_filter] of [PopochiuClickable]
## and [PopochiuInventoryItem] will be set to
## [enum CanvasItem.TextureFilter].TEXTURE_FILTER_NEAREST when those objects are created.
@export var is_pixel_art_game := false
## Whether the cursor should move in whole pixels or not.
@export var is_pixel_perfect := false
## The style to use in dialog lines:[br][br]
## - [b]Above Character[/b]. Makes the text appear in top of each character. You can define
## the position of if using the [b]DialoPos[/b] node in the character's scene.[br]
## - [b]Portrait[/b]. Texts will appear in a panel located in the center of the game window
## accompanied by the avatar of the character who is speaking. You can define an avatar for each
## emotion with the [member PopochiuCharacter.avatars] property.[br]
## - [b]Caption[/b]. The texts will appear at the bottom of the game window (as if they were
## subtitles).
@export_enum("Above Character", "Portrait", "Caption") var dialog_style := 0

#var _plugin_icons := {}


#region Public #####################################################################################
# Thanks to @drbloop for providing the bases of this function
func initialize_project_settings() -> PopochiuSettings:
	_initialize_project_cfg(SCALE_GUI, true, TYPE_BOOL)
	_initialize_project_cfg(INVENTORY_ALWAYS_VISIBLE, false, TYPE_BOOL)
	_initialize_project_cfg(TOOLBAR_ALWAYS_VISIBLE, false, TYPE_BOOL)
	_initialize_project_cfg(FADE_COLOR, Color(0, 0, 0, 1), TYPE_COLOR)
	_initialize_project_cfg(SKIP_CUTSCENE_TIME, 0.2, TYPE_FLOAT)

	_initialize_project_cfg(TEXT_SPEED, 0.1, TYPE_FLOAT, PROPERTY_HINT_RANGE, "0.0,0.1")
	_initialize_project_cfg(AUTO_CONTINUE_TEXT, false, TYPE_BOOL)
	_initialize_project_cfg(USE_TRANSLATIONS, false, TYPE_BOOL)
	_initialize_project_cfg(MAX_DIALOG_OPTIONS, 3, TYPE_INT)

	_initialize_project_cfg(INVENTORY_LIMIT, 0, TYPE_INT)
	_initialize_project_cfg(INVENTORY_ITEMS_ON_START, [], TYPE_ARRAY,
		PROPERTY_HINT_TYPE_STRING, "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_FILE, "*tscn"]
	)

	_initialize_project_cfg(IMPORT_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(LOOP_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(WIPE_OLD_ANIMS_ENABLED, true, TYPE_BOOL)

	#_set_icons()
	ProjectSettings.save()
	return self


#endregion

#region Private ####################################################################################
func _initialize_project_cfg(
	key: String, default_value, type: int, hint := PROPERTY_HINT_NONE, hint_string := ""
) -> void:
	if not ProjectSettings.has_setting(key):
		ProjectSettings.set_setting(key, default_value)
		ProjectSettings.set_initial_value(key, default_value)
		ProjectSettings.add_property_info({
			"name": key,
			"type": type,
			"hint": hint,
			"hint_string": hint_string,
		})


#func _set_icons() -> void:
	#_plugin_icons = {
		#"collapsed": EditorInterface.get_editor_theme().get_icon("GuiTreeArrowRight", "EditorIcons"),
		#"expanded": EditorInterface.get_editor_theme().get_icon("GuiTreeArrowDown", "EditorIcons"),
	#}


#endregion
