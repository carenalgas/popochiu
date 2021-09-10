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
export var can_create := true


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _init() -> void:
	# Hay que crear una copia única del StyleBox del panel para que no se
	# sobreescriba cuando se cambien las propiedades de las instancias.
	add_stylebox_override('panel', get_stylebox('panel').duplicate())


func _ready() -> void:
	$HBoxContainer/Arrow.texture = open_icon

	connect('gui_input', self, '_on_input')
	(get_node(target_group) as Control).connect('resized', self, '_update_child_count')
	
	if get_node(target_group).get_child_count() == 0:
		self.is_open = false


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


func _update_child_count() -> void:
	if get_node_or_null('HBoxContainer/Label'):
		var childs := (
			get_node(target_group).get_child_count() - (1 if can_create else 0)
		)
		if childs > 1:
			$HBoxContainer/Label.text = title + (' (%d)' % childs)
		else:
			$HBoxContainer/Label.text = title
