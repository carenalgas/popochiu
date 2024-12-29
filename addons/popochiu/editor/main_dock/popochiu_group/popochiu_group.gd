@tool
@icon("res://addons/popochiu/editor/main_dock/popochiu_group/images/popochiu_group.svg")
class_name PopochiuGroup
extends PanelContainer

signal create_clicked

const PopochiuRow := preload("res://addons/popochiu/editor/main_dock/popochiu_row/popochiu_row.gd")

@export var icon: Texture2D : set = set_icon
@export var is_open := true : set = set_is_open
@export var color: Color = Color("999999") : set = set_color
@export var title := "Group" : set = set_title
@export var can_create := true
@export var create_text := ""
@export var target_list: NodePath = ""
@export var custom_title_count := false

var _external_list: VBoxContainer = null

@onready var header: PanelContainer = %Header
@onready var arrow: TextureRect = %Arrow
@onready var trt_icon: TextureRect = %Icon
@onready var lbl_title: Label = %Title
@onready var body: Container = %Body
@onready var btn_create: Button = %BtnCreate
@onready var list: VBoxContainer = %List


#region Godot ######################################################################################
func _ready() -> void:
	# Establecer estado inicial
	add_theme_stylebox_override("panel", get_theme_stylebox("panel").duplicate())
	(get_theme_stylebox("panel") as StyleBoxFlat).border_color = color
	
	if is_instance_valid(icon):
		trt_icon.texture = icon
	
	lbl_title.text = title
	btn_create.icon = get_theme_icon("Add", "EditorIcons")
	btn_create.text = create_text
	self.is_open = list.get_child_count() > 0
	
	if not can_create:
		btn_create.hide()
	
	header.gui_input.connect(_on_input)
	list.resized.connect(_update_child_count)
	btn_create.pressed.connect(emit_signal.bind("create_clicked"))
	
	if target_list:
		_external_list = get_node(target_list) as VBoxContainer
		self.is_open = _external_list.get_child_count() > 0


#endregion

#region Public #####################################################################################
func clear_list() -> void:
	for c in list.get_children():
		# Fix #216: Delete the row immediately so that it does not interfere with the creation of
		# other rows that may have the same name as it
		c.free()


func add(node: Node, sort := false) -> void:
	if sort:
		node.ready.connect(_order_list.bind(node))
	
	list.add_child(node)
	
	btn_create.disabled = false
	
	if not is_open:
		self.is_open = true


func clear_favs() -> void:
	for popochiu_row: PopochiuRow in list.get_children():
		popochiu_row.clear_tag()


func disable_create() -> void:
	btn_create.disabled = true


func enable_create() -> void:
	btn_create.disabled = false


func get_elements() -> Array:
	return list.get_children()


func remove_by_name(node_name: String) -> void:
	if list.has_node(node_name):
		var node: HBoxContainer = list.get_node(node_name)
		
		list.remove_child(node)
		node.free()


func add_header_button(btn: Button) -> void:
	btn_create.add_sibling(btn)


func set_title_count(count: int, max_count := 0) -> void:
	if max_count > 0:
		lbl_title.text = "%s (%d/%d)" % [title, count, max_count]
	else:
		lbl_title.text = "%s (%d)" % [title, count]


func get_by_name(node_name: String) -> HBoxContainer:
	if list.has_node(node_name):
		return list.get_node(node_name)
	return null


#endregion

#region SetGet #####################################################################################
func set_icon(value: Texture2D) -> void:
	icon = value
	
	if is_instance_valid(trt_icon):
		trt_icon.texture = value


func set_is_open(value: bool) -> void:
	is_open = value
	
	_toggled(value)


func set_color(value: Color) -> void:
	color = value
	
	if is_instance_valid(header):
		(get_theme_stylebox("panel") as StyleBoxFlat).border_color = value


func set_title(value: String) -> void:
	title = value
	
	if is_instance_valid(lbl_title):
		lbl_title.text = value


#endregion

#region Private ####################################################################################
func _on_input(event: InputEvent) -> void:
	var mouse_event: = event as InputEventMouseButton
	if mouse_event and mouse_event.button_index == MOUSE_BUTTON_LEFT \
		and mouse_event.pressed:
			is_open = !is_open
			_toggled(is_open)


func _toggled(button_pressed: bool) -> void:
	if is_instance_valid(arrow):
		arrow.texture = (
			get_theme_icon("GuiTreeArrowDown", "EditorIcons") if button_pressed
			else get_theme_icon("GuiTreeArrowRight", "EditorIcons")
		)
	
	if is_instance_valid(body):
		if button_pressed: body.show()
		else: body.hide()
	
	if is_instance_valid(_external_list):
		_external_list.visible = button_pressed


func _update_child_count() -> void:
	if custom_title_count: return
	
	if is_instance_valid(lbl_title):
		var children := list.get_child_count()
		lbl_title.text = title + (" (%d)" % children) if children > 1 else title


func _order_list(node: Node) -> void:
	node.ready.disconnect(_order_list)
	
	# Place the new row in its place alphabetically
	var place_before: Node = null
	for row in list.get_children():
		if str(node.name) < str(row.name):
			place_before = row
			break
	
	if not place_before: return
	
	list.move_child(node, place_before.get_index())


#endregion
