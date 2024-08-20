extends Button

@export var command: NineVerbCommands.Commands = NineVerbCommands.Commands.WALK_TO


#region Godot ######################################################################################
func _ready() -> void:
	pressed.connect(_on_pressed)


#endregion

#region Private ####################################################################################
func _on_pressed() -> void:
	E.current_command = command
	G.show_hover_text()


#endregion
