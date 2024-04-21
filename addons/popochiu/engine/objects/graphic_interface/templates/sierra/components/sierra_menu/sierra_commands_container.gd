extends HBoxContainer


#region Godot ######################################################################################
func _ready() -> void:
	E.command_selected.connect(_on_command_selected)


#endregion

#region Public #####################################################################################
func _on_command_selected() -> void:
	for b in get_children():
		(b as TextureButton).set_pressed_no_signal(false)
	
	(get_child(E.current_command) as TextureButton).set_pressed_no_signal(true)
	Cursor.show_cursor(E.get_current_command_name().to_snake_case())


#endregion
