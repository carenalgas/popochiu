# @popochiu-docs-category game-scripts-interfaces
class_name PopochiuIGraphicInterface
extends Node
## Provides access to the in-game [PopochiuGraphicInterface] via the singleton [b]G[/b]
## (for example: [code]G.block()[/code]).
##
## Use this interface to manage the GUI.
##
## Capabilities include:
##
## - Showing messages at the center of the screen (narration or system messages).[br]
## - Displaying hover info for objects under the cursor.[br]
## - Showing, hiding, blocking or unblocking the GUI.
##
## [b]Use examples:[/b]
## [codeblock]
## # Shows an instructional tooltip
## G.show_info('Click this to open the main menu')
##
## # Displays a message box in the center of the screen
## # and wait for the player to dismiss it
## G.display('There are no actions set for this object')
##
## # Hides the interface (for example during a cutscene
## # or when showing a full-screen close-up)
## G.hide_interface()
##
## # Connect a function to a specific GUI event
## G.connect('inventory_shown', self, '_play_inventory_sfx')
## [/codeblock]

## Emitted when [method block] is called; [PopochiuGraphicInterface] (the in-game GUI)
## listens to this to block input.
signal blocked
## Emitted when [method unblock] is called; [PopochiuGraphicInterface] (the in-game GUI)
## listens to this to resume input.
signal unblocked
## Emitted when [method hide_interface] is called; [PopochiuGraphicInterface] (the in-game GUI)
## listens to this to hide the GUI.
signal hidden
## Emitted when [method show_interface] is called; [PopochiuGraphicInterface] (the in-game GUI)
## listens to this to show the GUI.
signal shown
## Emitted when the cursor enters (hovers) a [param clickable].
signal mouse_entered_clickable(clickable: PopochiuClickable)
## Emitted when the cursor exits a [param clickable].
signal mouse_exited_clickable(clickable: PopochiuClickable)
## Emitted when the cursor enters (hovers) an [param inventory_item].
signal mouse_entered_inventory_item(inventory_item: PopochiuInventoryItem)
## Emitted when the cursor exits an [param inventory_item].
signal mouse_exited_inventory_item(inventory_item: PopochiuInventoryItem)
## Emitted when a [PopochiuCharacter] begins speaking a dialog line.
signal dialog_line_started
## Emitted when a [PopochiuCharacter] finishes speaking a dialog line.
signal dialog_line_finished
## Emitted when [method show_hover_text] is called so the GUI can display [param message]
## as a hover text.
signal hover_text_shown(message: String)
## Emitted when [method show_system_text] is called so the GUI can display [param message]
## as a system text.
signal system_text_shown(message: String)
## Emitted when the system text is dismissed by a click.
signal system_text_hidden
## Emitted when a [PopochiuPopup] identified by [member PopochiuPopup.script_name] is requested.
signal popup_requested(script_name: StringName)
# NOTE: Maybe add some signals for clicking objects and items
#signal clicked_clickable(clickable: PopochiuClickable)
#signal clicked_inventory_item(inventory_item: PopochiuInventoryItem)
## Emitted when the dialog options for the running [PopochiuDialog] are shown.
signal dialog_options_shown
## Emitted after a game is loaded and the GUI has finished showing any notification.
signal load_feedback_finished

## Whether the GUI is currently blocked.
var is_blocked := false
## Identifier of the GUI template used by the game.
var template := ""
## Reference to the active [PopochiuGraphicInterface] instance for the chosen template.
var gui: PopochiuGraphicInterface


#region Godot ######################################################################################
func _init() -> void:
	Engine.register_singleton(&"G", self)


func _ready():
	template = PopochiuResources.get_data_value("ui", "template", "")


#endregion

#region Public #####################################################################################
## Displays [param msg] in a box centered on-screen (narration/instruction/warning).
## Temporarily blocks the GUI until the player clicks anywhere to dismiss the message.
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


## Displays [param msg] in a box centered on-screen (narration/instruction/warning).
## Temporarily blocks the GUI until the player clicks anywhere to dismiss the message.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_show_system_text(msg: String) -> Callable:
	return func (): await show_system_text(msg)


## Shows [param msg] as hover text for the currently hovered object. Does not block interactions.
## Can be used to inform the player what happens when clicking or right-clicking an object.
func show_hover_text(msg := '') -> void:
	hover_text_shown.emit(msg)


## Blocks the in-game GUI, preventing player interaction.
func block() -> void:
	is_blocked = true
	blocked.emit()


## Unblocks the in-game GUI.
##
## The [param wait] parameter is used for internal purposes to avoid race conditions
## in specific scenarios. Ignore it unless you know what you're doing.
func unblock(wait := false) -> void:
	is_blocked = false
	
	if wait:
		await get_tree().create_timer(0.1).timeout
		
		if is_blocked: return
	
	unblocked.emit()


## Hides the in-game GUI.
func hide_interface() -> void:
	hidden.emit()


## Hides the in-game GUI.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_hide_interface() -> Callable:
	return func(): hide_interface()

## Shows the in-game GUI.
func show_interface() -> void:
	shown.emit()


## Shows the in-game GUI.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_show_interface() -> Callable:
	return func(): show_interface()


## Returns the name of the cursor texture that the GUI requests to show.
func get_cursor_name() -> String:
	if not is_instance_valid(gui): return ""
	
	return gui.get_cursor_name()


#endregion
