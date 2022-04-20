tool
class_name PopochiuGroup,\
'res://addons/Popochiu/Editor/MainDock/PopochiuGroup/popochiu_group.svg'
extends PanelContainer

signal create_clicked

const PopochiuObjectRow := preload('res://addons/Popochiu/Editor/MainDock/ObjectRow/PopochiuObjectRow.gd')

export var icon: Texture setget _set_icon
export var is_open := true setget _set_is_open
export var color: Color = Color('999999') setget _set_color
export var title := 'Group' setget _set_title
export var can_create := true
export var create_text := ''
export var target_list: NodePath = ''

var _external_list: VBoxContainer = null

onready var _header: PanelContainer = find_node('Header')
onready var _arrow: TextureRect = find_node('Arrow')
onready var _icon: TextureRect = find_node('Icon')
onready var _lbl_title: Label = find_node('Title')
onready var _body: Container = find_node('Body')
onready var _list: VBoxContainer = find_node('List')
onready var _btn_create: Button = find_node('BtnCreate')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	# Establecer estado inicial
	_header.add_stylebox_override('panel', _header.get_stylebox('panel').duplicate())
	(_header.get_stylebox('panel') as StyleBoxFlat).bg_color = color
	_icon.texture = icon
	_lbl_title.text = title
	_btn_create.icon = get_icon('Add', 'EditorIcons')
	_btn_create.text = create_text
	self.is_open = _list.get_child_count() > 0
	
	if not can_create:
		_btn_create.hide()

	_header.connect('gui_input', self, '_on_input')
	_list.connect('resized', self, '_update_child_count')
	_btn_create.connect('pressed', self, 'emit_signal', ['create_clicked'])
	
	if target_list:
		_external_list = get_node(target_list) as VBoxContainer
		self.is_open = _external_list.get_child_count() > 0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func clear_list() -> void:
	for c in _list.get_children():
		c.queue_free()


func add(node: Node) -> void:
	_list.add_child(node)
	
	_btn_create.disabled = false
	
	if not is_open:
		self.is_open = true


func clear_favs() -> void:
	for por in _list.get_children():
		(por as PopochiuObjectRow).is_main = false


func disable_create() -> void:
	_btn_create.disabled = true


func enable_create() -> void:
	_btn_create.disabled = false


func get_elements() -> Array:
	return _list.get_children()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _on_input(event: InputEvent) -> void:
	var mouse_event: = event as InputEventMouseButton
	if mouse_event and mouse_event.button_index == BUTTON_LEFT \
		and mouse_event.pressed:
			is_open = !is_open
			_toggled(is_open)


func _toggled(button_pressed: bool) -> void:
	if is_instance_valid(_arrow):
#		_arrow.texture = open_icon if button_pressed else closed_icon
		_arrow.texture = get_icon('GuiTreeArrowDown', 'EditorIcons')\
			if button_pressed else get_icon('GuiTreeArrowRight', 'EditorIcons')
	
	if is_instance_valid(_body):
		if button_pressed: _body.show()
		else: _body.hide()
	
	if is_instance_valid(_external_list):
		_external_list.visible = button_pressed


func _set_color(value: Color) -> void:
	color = value
	
	if is_instance_valid(_header):
		(_header.get_stylebox('panel') as StyleBoxFlat).bg_color = value


func _set_title(value: String) -> void:
	title = value
	
	if is_instance_valid(_lbl_title):
		_lbl_title.text = value
		property_list_changed_notify()


func _set_is_open(value: bool) -> void:
	is_open = value
	
	_toggled(value)


func _set_icon(value: Texture) -> void:
	icon = value
	
	if is_instance_valid(_icon):
		_icon.texture = value
		property_list_changed_notify()


func _update_child_count() -> void:
	if is_instance_valid(_lbl_title):
		var childs := _list.get_child_count()
		_lbl_title.text = title + (' (%d)' % childs) if childs > 1 else title
