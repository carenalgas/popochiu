extends 'res://addons/Popochiu/Engine/Objects/GraphicInterface/Toolbar/ToolbarButton.gd'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_pressed() -> void:
	get_tree().quit()
