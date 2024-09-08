extends BoxContainer


#region Public #####################################################################################
func press_command(command: int) -> void:
	var btn: BaseButton = find_child(E.get_command_name(command).to_pascal_case())
	
	if btn:
		btn.button_pressed = true


func unpress_commands() -> void:
	for btn in find_children("*", "BaseButton") as Array[BaseButton]:
		btn.set_pressed_no_signal(false)
		
		if btn.has_focus():
			btn.release_focus()


func highlight_command(command: int, highlighted := true) -> void:
	var btn: BaseButton = find_child(E.get_command_name(command).to_pascal_case())
	
	if btn:
		btn.grab_focus() if highlighted else btn.release_focus()


#endregion
