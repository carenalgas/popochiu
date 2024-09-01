extends TextureButton

@export var command: SierraCommands.Commands = 0


#region Godot ######################################################################################
func _ready() -> void:
	toggled.connect(on_toggled)


#endregion

#region Public #####################################################################################
func on_toggled(button_pressed: bool) -> void:
	if button_pressed:
		E.current_command = command


#endregion
