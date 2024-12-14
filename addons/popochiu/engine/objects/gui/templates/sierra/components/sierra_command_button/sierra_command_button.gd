extends TextureButton

@export var command: SierraCommands.Commands = 0


#region Godot ######################################################################################
func _ready() -> void:
	toggled.connect(on_toggled)


#endregion

#region Public #####################################################################################
func on_toggled(is_pressed: bool) -> void:
	if is_pressed:
		PopochiuUtils.e.current_command = command


#endregion
