@tool
@icon('res://addons/popochiu/editor/main_dock/popochiu_group/popochiu_group.svg')
class_name PopochiuGroup
extends PanelContainer

signal create_clicked

const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const PopochiuObjectRow :=\
preload('res://addons/popochiu/editor/main_dock/object_row/popochiu_object_row.gd')

@export var icon: Texture2D : set = _set_icon
@export var is_open := true : set = _set_is_open
@export var color: Color = Color('999999') : set = _set_color
@export var title := 'Group' : set = _set_title
@export var can_create := true
@export var create_text := ''
@export var target_list: NodePath = ''

var _external_list: VBoxContainer = null

@onready var _header: PanelContainer = find_child('Header')
@onready var _arrow: TextureRect = find_child('Arrow')
@onready var _icon: TextureRect = find_child('Icon')
@onready var _lbl_title: Label = find_child('Title')
@onready var _body: Container = find_child('Body')
@onready var _list: VBoxContainer = find_child('List')
@onready var _btn_create: Button = find_child('BtnCreate')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	# Establecer estado inicial
	add_theme_stylebox_override(
		'panel', get_theme_stylebox('panel').duplicate()
	)
	(get_theme_stylebox('panel') as StyleBoxFlat).border_color = color
	_icon.texture = icon
	_lbl_title.text = title
	_btn_create.icon = get_theme_icon('Add', 'EditorIcons')
	_btn_create.text = create_text
	self.is_open = _list.get_child_count() > 0
	
	if not can_create:
		_btn_create.hide()
	
	_header.gui_input.connect(_on_input)
	_list.resized.connect(_update_child_count)
	_btn_create.pressed.connect(emit_signal.bind('create_clicked'))
	
	if target_list:
		_external_list = get_node(target_list) as VBoxContainer
		self.is_open = _external_list.get_child_count() > 0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func clear_list() -> void:
	for c in _list.get_children():
		c.queue_free()


func add(node: Node, sort := false) -> void:
	if sort:
		node.ready.connect(_order_list.bind(node))
	
	_list.add_child(node)
	
	_btn_create.disabled = false
	
	if not is_open:
		self.is_open = true


func clear_favs() -> void:
	for por in _list.get_children():
		if (por as PopochiuObjectRow).type == Constants.Types.ROOM:
			(por as PopochiuObjectRow).is_main = false
		
		if (por as PopochiuObjectRow).type == Constants.Types.CHARACTER:
			(por as PopochiuObjectRow).is_pc = false


func disable_create() -> void:
	_btn_create.disabled = true


func enable_create() -> void:
	_btn_create.disabled = false


func get_elements() -> Array:
	return _list.get_children()


func remove_by_name(node_name: String) -> void:
	if _list.has_node(node_name):
		var node: HBoxContainer = _list.get_node(node_name)
		
		_list.remove_child(node)
		node.queue_free()


func add_header_button(btn: Button) -> void:
	_btn_create.add_sibling(btn)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _on_input(event: InputEvent) -> void:
	var mouse_event: = event as InputEventMouseButton
	if mouse_event and mouse_event.button_index == MOUSE_BUTTON_LEFT \
		and mouse_event.pressed:
			is_open = !is_open
			_toggled(is_open)


func _toggled(button_pressed: bool) -> void:
	if is_instance_valid(_arrow):
		_arrow.texture = get_theme_icon('GuiTreeArrowDown', 'EditorIcons')\
			if button_pressed\
			else get_theme_icon('GuiTreeArrowRight', 'EditorIcons')
	
	if is_instance_valid(_body):
		if button_pressed: _body.show()
		else: _body.hide()
	
	if is_instance_valid(_external_list):
		_external_list.visible = button_pressed


func _set_color(value: Color) -> void:
	color = value
	
	if is_instance_valid(_header):
		(get_theme_stylebox('panel') as StyleBoxFlat).border_color = value


func _set_title(value: String) -> void:
	title = value
	
	if is_instance_valid(_lbl_title):
		_lbl_title.text = value
		notify_property_list_changed()


func _set_is_open(value: bool) -> void:
	is_open = value
	
	_toggled(value)


func _set_icon(value: Texture2D) -> void:
	icon = value
	
	if is_instance_valid(_icon):
		_icon.texture = value
		notify_property_list_changed()


func _update_child_count() -> void:
	if is_instance_valid(_lbl_title):
		var childs := _list.get_child_count()
		_lbl_title.text = title + (' (%d)' % childs) if childs > 1 else title


func _order_list(node: Node) -> void:
	node.ready.disconnect(_order_list)
	
	# Place the new row in its place alphabetically
	var place_before: Node = null
	for row in _list.get_children():
		if str(node.name) < str(row.name):
			place_before = row
			break
	
	if not place_before: return
	
	_list.move_child(node, place_before.get_index())
