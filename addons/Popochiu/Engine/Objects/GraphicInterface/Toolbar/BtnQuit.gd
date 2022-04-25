extends 'res://addons/Popochiu/Engine/Objects/GraphicInterface/Toolbar/ToolbarButton.gd'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_pressed() -> void:
	get_tree().quit()
