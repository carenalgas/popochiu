tool
extends VBoxContainer
# Controla la lógica de la pestaña de configuración de Popochiu

var main_dock: Panel

onready var _fade_color: ColorPickerButton =\
find_node('FadeColor').find_node('Input')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	_fade_color.connect('popup_closed', self, '_update_fade_color')


func fill_data() -> void:
	if main_dock.popochiu.get_node_or_null('TransitionLayer'):
		_fade_color.color = main_dock.popochiu.get_node('TransitionLayer').fade_color


func _update_fade_color() -> void:
	if main_dock.popochiu.get_node_or_null('TransitionLayer'):
		main_dock.popochiu.get_node('TransitionLayer').fade_color = _fade_color.color
		main_dock.save_popochiu()
