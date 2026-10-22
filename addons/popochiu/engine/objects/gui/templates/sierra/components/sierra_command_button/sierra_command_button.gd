# @popochiu-docs-ignore-class
extends TextureButton

@export var command: SierraCommands.Commands = SierraCommands.Commands.WALK


#region Godot ######################################################################################
func _ready() -> void:
	toggled.connect(on_toggled)


#endregion

#region Public #####################################################################################
func on_toggled(is_pressed: bool) -> void:
	if is_pressed:
		PopochiuUtils.e.current_command = command


#endregion
