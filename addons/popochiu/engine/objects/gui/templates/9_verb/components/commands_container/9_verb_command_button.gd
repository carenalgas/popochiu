extends Button

@export var command: NineVerbCommands.Commands = NineVerbCommands.Commands.WALK_TO


#region Godot ######################################################################################
func _ready() -> void:
	pressed.connect(_on_pressed)


#endregion

#region Private ####################################################################################
func _on_pressed() -> void:
	PopochiuUtils.e.current_command = command
	PopochiuUtils.g.show_hover_text()


#endregion
