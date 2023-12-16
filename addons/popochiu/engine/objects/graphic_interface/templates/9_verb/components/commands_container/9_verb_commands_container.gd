extends GridContainer


func unpress_commands() -> void:
	for btn in get_children() as Array[BaseButton]:
		btn.set_pressed_no_signal(false)
		
		if btn.has_focus():
			btn.release_focus()


func highlight_command(command: int, highlighted := true) -> void:
	var btn: BaseButton = find_child(E.get_command_name(command).to_pascal_case())
	
	if btn:
		btn.grab_focus() if highlighted else btn.release_focus()
		#btn.set_pressed_no_signal(highlighted)


func press_command(command: int) -> void:
	var btn: BaseButton = find_child(E.get_command_name(command).to_pascal_case())
	
	if btn:
		btn.button_pressed = true
