@tool
class_name PopochiuSettings
extends Resource
## Defines properties as settings for the game.

## The time, in seconds, that will take the game to skip a cutscene.
var skip_cutscene_time := 0.0
## A flag telling if the transition layer should be shown when the game starts.
var show_tl_in_first_room := false
## @deprecated
## The text speed options that will be available in the game. In the ContextSensitive GUI you can
## loop between them using the text speed button in the SettingsBar.
var text_speeds := [0.1, 0.01, 0.0]
## @deprecated
## The index of the default text speed value in [member text_speeds].
var default_text_speed := 0
## The speed at which characters are displayed when a character speaks and the text is being
## animated
var text_speed := 0.0
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
## @deprecated
## [b]NOTE[/b] This option is now a property in the InventoryBar component.
## Whether the inventory will be always visible, or players will have to do something to make it
## appear. [b]This is specific to the ContextSensitive GUI[/b].
var inventory_always_visible := false
## @deprecated
## [b]NOTE[/b] This option is now a property in the SettingsBar component.
## Whether the toolbar (SettingsBar) will be always visible, or players will have to do something to
## make it appear. [b]This is specific to the ContextSensitive GUI[/b].
var toolbar_always_visible := false
## The color the screen changes to it plays a transition (e.g. move between rooms, skip a cutscene).
var fade_color: Color
## Whether the GUI should scale to match the native game resolution. The default GUI has a 356x200
## resolution.
var scale_gui := false
## @deprecated
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
## the position of if using the [b]DialogPos[/b] node in the character's scene.[br]
## - [b]Portrait[/b]. Texts will appear in a panel located in the center of the game window
## accompanied by the avatar of the character who is speaking. You can define an avatar for each
## emotion with the [member PopochiuCharacter.avatars] property.[br]
## - [b]Caption[/b]. The texts will appear at the bottom of the game window (as if they were
## subtitles).
var dialog_style := 0
## Setting intended for development of the plugin. It makes the game to use the original files of
## the selected template to make testing changes on it easier. This is a workaround while we find
## how to make the scenes moved to [code]res://game/gui[/code] inherit from the
## source ones.
var dev_use_addon_template := false


#region Godot ######################################################################################
func _init() -> void:
	# ---- GUI -------------------------------------------------------------------------------------
	scale_gui = PopochiuConfig.is_scale_gui()
	fade_color = PopochiuConfig.get_fade_color()
	skip_cutscene_time = PopochiuConfig.get_skip_cutscene_time()
	show_tl_in_first_room = PopochiuConfig.should_show_tl_in_first_room()
	
	# ---- Dialogs ---------------------------------------------------------------------------------
	text_speed = PopochiuConfig.get_text_speed()
	auto_continue_text = PopochiuConfig.is_auto_continue_text()
	use_translations = PopochiuConfig.is_use_translations()
	dialog_style = PopochiuConfig.get_dialog_style()
	
	# ---- Inventory -------------------------------------------------------------------------------
	inventory_limit = PopochiuConfig.get_inventory_limit()
	items_on_start = PopochiuConfig.get_inventory_items_on_start()
	
	# ---- Pixel game ------------------------------------------------------------------------------
	is_pixel_art_game = PopochiuConfig.is_pixel_art_textures()
	is_pixel_perfect = PopochiuConfig.is_pixel_perfect()
	
	# ---- DEV -------------------------------------------------------------------------------------
	dev_use_addon_template = PopochiuConfig.is_use_addon_template()


#endregion

#region Public #####################################################################################
#endregion

#region Private ####################################################################################
#endregion
