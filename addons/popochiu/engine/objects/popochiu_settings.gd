@tool
class_name PopochiuSettings
extends Resource
## Defines properties as settings for the game.

## The time, in seconds, that will take the game to skip a cutscene.
var skip_cutscene_time := 0.0
## The text speed options that will be available in the game. In the ContextSensitive GUI you can
## loop between them usin the text speed button in the SettingsBar.
var text_speeds := [0.1, 0.01, 0.0]
## The index of the default text speed value in [member text_speeds].
var default_text_speed_idx := 0
## If [code]true[/code], then dialog lines should auto continue once the animation that shows them
## finishes. Otherwise, players will have to click the screen in order to continue.
var auto_continue_text := false
## When [code]true[/code] the game will call [method Object.tr] when getting the texts to show in
## the game.
var use_translations := false
## An array with the [code]script_name[/code] of the inventory items that will be added to the
## inventory when the game starts. You can use the context menu in front of each inventory item in
## Popochiu's Main tab to add or remove items from start with the
## [img]res://addons/popochiu/icons/inventory_item_start.png[/img] [b]Start with it[/b] option.
var items_on_start := []
## The max number of items players will be able to put in the inventory.
var inventory_limit := 0
## Whether the inventory will be always visible, or players will have to do something to make it
## appear. [b]This is specific to the ContextSensitive GUI[/b].
var inventory_always_visible := false
## Whether the toolbar (SettingsBar) will be always visible, or players will have to do something to
## make it appear. [b]This is specific to the ContextSensitive GUI[/b].
var toolbar_always_visible := false
## The color the screen changes to it plays a transition (e.g. move between rooms, skip a cutscene).
var fade_color: Color
## Whether the GUI should scale to match the native game resolution. The default GUI has a 320x180
## resolution.
var scale_gui := false
## The number of dialog options to show before showing a scroll bar to render those that exceed this
## limit.
var max_dialog_options := 0
## If [code]true[/code], the [member CanvasItem.texture_filter] of [PopochiuClickable]
## and [PopochiuInventoryItem] will be set to
## [enum CanvasItem.TextureFilter].TEXTURE_FILTER_NEAREST when those objects are created.
var is_pixel_art_game := false
## Whether the cursor should move in whole pixels or not.
var is_pixel_perfect := false
## The style to use in dialog lines:[br][br]
## - [b]Above Character[/b]. Makes the text appear in top of each character. You can define
## the position of if using the [b]DialoPos[/b] node in the character's scene.[br]
## - [b]Portrait[/b]. Texts will appear in a panel located in the center of the game window
## accompanied by the avatar of the character who is speaking. You can define an avatar for each
## emotion with the [member PopochiuCharacter.avatars] property.[br]
## - [b]Caption[/b]. The texts will appear at the bottom of the game window (as if they were
## subtitles).
var dialog_style := 0


#region Godot ######################################################################################
func _init() -> void:
	skip_cutscene_time = PopochiuResources.get_config().get_skip_cutscene_time()
	auto_continue_text = PopochiuResources.get_config().is_auto_continue_text()
	use_translations = PopochiuResources.get_config().is_use_translations()
	items_on_start = PopochiuResources.get_config().get_inventory_items_on_start()
	inventory_limit = PopochiuResources.get_config().get_inventory_limit()
	inventory_always_visible = PopochiuResources.get_config().is_inventory_always_visible()
	toolbar_always_visible = PopochiuResources.get_config().is_toolbar_always_visible()
	fade_color = PopochiuResources.get_config().get_fade_color()
	scale_gui = PopochiuResources.get_config().is_scale_gui()
	max_dialog_options = PopochiuResources.get_config().get_max_dialog_options()
	is_pixel_art_game = PopochiuResources.get_config().is_pixel_art_textures()
	is_pixel_perfect = PopochiuResources.get_config().is_pixel_perfect()
	dialog_style = PopochiuResources.get_config().get_dialog_style()


#endregion

#region Public #####################################################################################
#endregion

#region Private ####################################################################################
#endregion
