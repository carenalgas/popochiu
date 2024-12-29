extends HBoxContainer


#region Godot ######################################################################################
func _ready() -> void:
	PopochiuUtils.e.command_selected.connect(_on_command_selected)


#endregion

#region Public #####################################################################################
func _on_command_selected() -> void:
	for b in get_children():
		(b as TextureButton).set_pressed_no_signal(false)
	
	(get_child(PopochiuUtils.e.current_command) as TextureButton).set_pressed_no_signal(true)
	PopochiuUtils.cursor.show_cursor(PopochiuUtils.e.get_current_command_name().to_snake_case())


#endregion
