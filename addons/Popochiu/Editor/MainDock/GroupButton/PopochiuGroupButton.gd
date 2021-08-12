tool
class_name PopochiuGroupButton,\
'res://addons/Popochiu/Editor/MainDock/GroupButton/popochiu_group_button.svg'
extends PanelContainer

export var open_icon: Texture
export var closed_icon: Texture
export var icon: Texture setget _set_icon
export var target_group: NodePath
export var is_open := true setget _set_is_open
export var color: Color = Color.white setget _set_color
export var title := 'Group' setget _set_title


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _init() -> void:
	# Hay que crear una copia única del StyleBox del panel para que no se
	# sobreescriba cuando se cambien las propiedades de las instancias.
	add_stylebox_override('panel', get_stylebox('panel').duplicate())


func _ready() -> void:
	$HBoxContainer/Arrow.texture = open_icon

	connect('gui_input', self, '_on_input')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func clear_list() -> void:
	var list: VBoxContainer = get_node_or_null(target_group)
	
	if list:
		for c in list.get_children():
			if c is Button:
				continue

			c.queue_free()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
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
	(get_stylebox('panel') as StyleBoxFlat).bg_color = value


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
