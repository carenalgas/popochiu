tool
extends VBoxContainer
# Controla la lógica de la pestaña de configuración de Popochiu

var main_dock: Panel

onready var _fade_color: ColorPickerButton =\
find_node('FadeColor').find_node('Input')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_fade_color.connect('popup_closed', self, '_update_fade_color')


func fill_data() -> void:
	_fade_color.color = main_dock.popochiu.get_node('TransitionLayer').fade_color


func _update_fade_color() -> void:
	main_dock.popochiu.get_node('TransitionLayer').fade_color = _fade_color.color
	main_dock.save_popochiu()
