class_name PopochiuIGraphicInterface
extends Node
## Provides access to the in-game [PopochiuGraphicInterface] (GUI). Access with [b]G[/b] (e.g.
## [code]G.block()[/code]).[br][br]
##
## Use it to manage the GUI. Its script is [b]i_graphic_interface.gd[/b].[br][br]
##
## Some things you can do with it:[br][br]
## 
## [b]•[/b] Show messages in the middle of the screen (like a narrator or a game message).[br]
## [b]•[/b] Show info about hovered objects in the game.[br]
## [b]•[/b] Show, hide, block or unblock the GUI.[br][br]
## 
## Examples:
## [codeblock]
## G.show_info('Click this to open the main menu')
## G.display('There are no actions set for this object')
## G.hide_interface()
## G.connect('inventory_shown', self, '_play_inventory_sfx')
## [/codeblock]

## Emitted when [method block] is called. [PopochiuGraphicInterface] connects to this signal in
## order to block the GUI.
signal blocked
## Emitted when [method unblock] is called. [PopochiuGraphicInterface] connects to this signal in
## order to unblock the GUI.
signal unblocked
## Emitted when [method hide_interface] is called. [PopochiuGraphicInterface] connects to this
## signal in order to hide the GUI.
signal hidden
## Emitted when [method show_interface] is called. [PopochiuGraphicInterface] connects to this
## signal in order to show the GUI.
signal shown
## Emitted when the cursor enters (hover) a [param clickable].
signal mouse_entered_clickable(clickable: PopochiuClickable)
## Emitted when the cursor exits a [param clickable].
signal mouse_exited_clickable(clickable: PopochiuClickable)
## Emitted when the cursor enters (hover) a [param inventory_item].
signal mouse_entered_inventory_item(inventory_item: PopochiuInventoryItem)
## Emitted when the cursor exits a [param inventory_item].
signal mouse_exited_inventory_item(inventory_item: PopochiuInventoryItem)
## Emitted when a [PopochiuCharacter] begins to say a dialogue line.
signal dialog_line_started
## Emitted when a [PopochiuCharacter] finishes saying a dialogue line.
signal dialog_line_finished
## Emitted when [method show_hover_text] so the GUI can show [param message] in the hover text.
## I.e. when a [PopochiuClickable] is hovered.
signal hover_text_shown(message: String)
## Emitted when [method show_system_text] so the GUI can show [param message] as a system text.
signal system_text_shown(message: String)
## Emitted when the system text disappears after a click on the screen.
signal system_text_hidden
## Emitted when the [PopochiuPopup] identified by [member PopochiuPopup.script_name] is opened.
signal popup_requested(script_name: StringName)
# NOTE: Maybe add some signals for clicking objects and items
#signal clicked_clickable(clickable: PopochiuClickable)
#signal clicked_inventory_item(inventory_item: PopochiuInventoryItem)
## Emitted when the dialog options of the running [PopochiuDialog] are shown.
signal dialog_options_shown
## Emitted when a game is loaded and the GUI has shown (or not shown) a notification to the player.
signal load_feedback_finished

## Whether the GUI is blocked or not.
var is_blocked := false
## Provides access to the identifier of the GUI template used by the game.
var template := ""
## Provides access to the [PopochiuGraphicInterface] of  the GUI template used by the game.
var gui: PopochiuGraphicInterface


#region Godot ######################################################################################
func _init() -> void:
	Engine.register_singleton(&"G", self)


func _ready():
	template = PopochiuResources.get_data_value("ui", "template", "")


#endregion

#region Public #####################################################################################
## Displays [param msg] at the center of the screen, useful for narration, instructions, or warnings
## to players. Temporarily blocks the GUI until players click anywhere on the game window, causing
## the text to disappear.
func show_system_text(msg: String) -> void:
	# NOTE: Not sure if this logic should happen here. Perhaps it could trigger a signal to which
	# the in-game graphic interface connects, allowing it to handle the logic.
	if not PopochiuUtils.e.playing_queue and gui.popups_stack.is_empty():
		block()
	
	if PopochiuUtils.e.cutscene_skipped:
		await get_tree().process_frame
		
		return
	
	system_text_shown.emit(PopochiuUtils.e.get_text(msg))
	await system_text_hidden
	
	if not PopochiuUtils.e.playing_queue and gui.popups_stack.is_empty():
		unblock()


## Displays [param msg] at the center of the screen, useful for narration, instructions, or warnings
## to players. Temporarily blocks the GUI until players click anywhere on the game window, causing
## the text to disappear.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_show_system_text(msg: String) -> Callable:
	return func (): await show_system_text(msg)


## Displays [param msg] in the game window without blocking interactions. Used to show players the
## name of objects where the cursor is positioned (i.e., a [PopochiuClickable]). It could also be
## used to show players what will happen if they use the left click or right click.
func show_hover_text(msg := '') -> void:
	hover_text_shown.emit(msg)


## Causes the in-game graphic interface (GUI) to be blocked. This prevents players from interacting
## with the game elements.
func block() -> void:
	is_blocked = true
	blocked.emit()


## Causes the in-game graphic interface (GUI) to be unblocked.
func unblock(wait := false) -> void:
	is_blocked = false
	
	if wait:
		await get_tree().create_timer(0.1).timeout
		
		if is_blocked: return
	
	unblocked.emit()


## Makes the in-game graphic interface (GUI) to hide.
func hide_interface() -> void:
	hidden.emit()


## Makes the in-game graphic interface (GUI) to hide.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_hide_interface() -> Callable:
	return func(): hide_interface()


## Makes the in-game graphic interface (GUI) to show.
func show_interface() -> void:
	shown.emit()


## Makes the in-game graphic interface (GUI) to show.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_show_interface() -> Callable:
	return func(): show_interface()


## Returns the name of the cursor texture to show.
func get_cursor_name() -> String:
	if not is_instance_valid(gui): return ""
	
	return gui.get_cursor_name()


#endregion
