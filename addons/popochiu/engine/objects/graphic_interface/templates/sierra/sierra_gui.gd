class_name SierraGUI
extends PopochiuGraphicInterface
## Defines the behavior of the Sierra GUI.
##
## In this GUI players interact with objects based on the ative command, which can be changed with
## right click or by using the buttons in the top bar that appears when the cursor moves to the
## top of the screen. The inventory can be opened with a button in the top bar, same for the
## settings.


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	Cursor.replace_frames($Cursor)
	Cursor.show_cursor()
	
	$Cursor.hide()
	
	E.current_command = SierraCommands.Commands.WALK
	
	# Connect to child signals
	%SierraSettingsPopup.option_selected.connect(_on_settings_option_selected)


func _input(event: InputEvent) -> void:
	# TODO: This was `if D.current_dialog:`. Check if everything works as expected
	if G.is_blocked: return
	
	if event is InputEventMouseButton and event.is_pressed():
		match (event as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT:
				# NOTE: When clicking anywhere with the Left Mouse Button, block
				# the player from moving to the clicked position since the Sierra
				# GUI allows characters to move only when the WALK command is
				# active.
				if not $SierraMenu.visible and not E.hovered\
				 and E.current_command != SierraCommands.Commands.WALK:
					get_viewport().set_input_as_handled()
			MOUSE_BUTTON_RIGHT:
				get_viewport().set_input_as_handled()
				
				E.current_command = posmod(
					E.current_command + 1, SierraCommands.Commands.size()
				)


#endregion

#region Virtual ####################################################################################
## Called when the GUI is blocked. Makes the GUI to stop processing input.
func _on_blocked(props := { blocking = true }) -> void:
	set_process_input(false)


## Called when the GUI is unblocked. Makes the GUI to start processing input.
func _on_unblocked() -> void:
	set_process_input(true)


## Called when the mouse enters (hovers) [param clickable]. It displays a text with the
## [member PopochiuClickable.description] in the [HoverText] component.
func _on_mouse_entered_clickable(clickable: PopochiuClickable) -> void:
	if G.is_blocked: return
	
	if not I.active:
		G.show_hover_text(clickable.description)
	else:
		G.show_hover_text(
			'Use %s with %s' % [I.active.description, clickable.description]
		)


## Called when the mouse exits [param clickable]. Clears the text in the [HoverText] component.
func _on_mouse_exited_clickable(clickable: PopochiuClickable) -> void:
	if G.is_blocked: return
	
	G.show_hover_text()


## Called when a dialogue line starts. It shows the [code]"wait"[/code] cursor.
func _on_dialog_line_started() -> void:
	Cursor.hide()


## Called when a dialogue line finishes. It shows the [code]"normal"[/code] cursor.
func _on_dialog_line_finished() -> void:
	Cursor.show()


## Called when a [PopochiuDialog] starts. It shows the [code]"gui"[/code] cursor.
func _on_dialog_started(_dialog: PopochiuDialog) -> void:
	Cursor.show_cursor("gui")


## Called when a [PopochiuDialog] finishes. It shows the cursor of the last active command.
func _on_dialog_finished(_dialog: PopochiuDialog) -> void:
	Cursor.show_cursor(E.get_current_command_name().to_snake_case())


## Called when the active [PopochiuInventoryItem] changes. If there is one, it hides the main cursor
## to show the one that shows the [member PopochiuInventoryItem.texture], otherwise it shows the
## default cursor.
func _on_inventory_item_selected(item: PopochiuInventoryItem) -> void:
	if is_instance_valid(item):
		Cursor.set_secondary_cursor_texture(item.texture)
		Cursor.hide_main_cursor()
	else:
		Cursor.remove_secondary_cursor_texture()
		Cursor.show_cursor()


#endregion

#region Private ####################################################################################
func _on_settings_option_selected(option_name: String) -> void:
	match option_name:
		"sound":
			%SierraSoundPopup.open()
		"text":
			%SierraTextPopup.open()
		"save":
			%SaveAndLoadPopup.open_save()
		"load":
			%SaveAndLoadPopup.open_load()
		"quit":
			%QuitPopup.open()


#endregion
