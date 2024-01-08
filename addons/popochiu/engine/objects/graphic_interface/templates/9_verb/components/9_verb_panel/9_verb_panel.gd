extends PanelContainer

@onready var hover_text_centered: RichTextLabel = %HoverTextCentered
@onready var commands_container: GridContainer = %CommandsContainer


#region Godot ######################################################################################
func _ready() -> void:
	hover_text_centered.hide()


#endregion

#region Public #####################################################################################
func unpress_commands() -> void:
	commands_container.unpress_commands()


func highlight_command(command_id: int, highlighted := true) -> void:
	commands_container.highlight_command(command_id, highlighted)


#endregion
