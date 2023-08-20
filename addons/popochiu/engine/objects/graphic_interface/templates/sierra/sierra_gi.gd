extends PopochiuGraphicInterface


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	
	Cursor.replace_frames($Cursor)
	Cursor.show_cursor()
	
	$Cursor.hide()
	
	E.current_command = SierraCommands.Commands.WALK
	
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
				if not $SierraTopMenu.visible and not E.hovered\
				 and E.current_command != SierraCommands.Commands.WALK:
					get_viewport().set_input_as_handled()
			MOUSE_BUTTON_RIGHT:
				get_viewport().set_input_as_handled()
				
				E.current_command = posmod(
					E.current_command + 1, SierraCommands.Commands.size()
				)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _on_blocked(props := { blocking = true }) -> void:
	set_process_input(false)


func _on_unblocked() -> void:
	set_process_input(true)


func _on_mouse_entered_clickable(clickable: PopochiuClickable) -> void:
	if G.is_blocked: return
	
	if not I.active:
		G.show_hover_text(clickable.description)
	else:
		G.show_hover_text(
			'Use %s with %s' % [I.active.description, clickable.description]
		)


func _on_mouse_exited_clickable(clickable: PopochiuClickable) -> void:
	if G.is_blocked: return
	
	G.show_hover_text()


func _on_dialog_line_started() -> void:
	Cursor.hide()


func _on_dialog_line_finished() -> void:
	Cursor.show()


func _on_dialog_started(_dialog: PopochiuDialog) -> void:
	Cursor.show_cursor("gui")


func _on_dialog_finished(_dialog: PopochiuDialog) -> void:
	Cursor.show_cursor(E.get_current_command_name().to_snake_case())


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
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
