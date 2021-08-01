tool
extends PanelContainer

export var open_icon: Texture
export var closed_icon: Texture
export var icon: Texture setget _set_icon
export var target_group: NodePath
export var is_open := true setget _set_is_open
export var color: Color = Color.white setget _set_color
export var title := 'Group' setget _set_title


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	connect('gui_input', self, '_on_input')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _on_input(event: InputEvent) -> void:
	var mouse_event: = event as InputEventMouseButton
	if mouse_event and mouse_event.button_index == BUTTON_LEFT \
		and mouse_event.pressed:
			is_open = !is_open
			_toggled(is_open)


func _toggled(button_pressed: bool) -> void:
	$HBoxContainer/Arrow.texture = open_icon if button_pressed else closed_icon
	
	if get_node_or_null(target_group):
		if button_pressed: get_node(target_group).show()
		else: get_node(target_group).hide()


func _set_color(value: Color) -> void:
	color = value
	if get_node_or_null('HBoxContainer/Label'):
		$Bg.color = value
	#	(get_stylebox('panel') as StyleBoxFlat).bg_color = value
		property_list_changed_notify()


func _set_title(value: String) -> void:
	title = value
	if get_node_or_null('HBoxContainer/Label'):
		$HBoxContainer/Label.text = value
		property_list_changed_notify()


func _set_is_open(value: bool) -> void:
	is_open = value
	_toggled(value)


func _set_icon(value: Texture) -> void:
	icon = value
	$HBoxContainer/Icon.texture = value
