tool
extends Container


onready var select_button : Button = $Button
onready var select_node_dialog : WindowDialog = $SelectNodeDialog


const SELECT_BUTTON_DEFAULT_TEXT := "Select a Node"


var sprite : Node setget set_sprite

var _sprite_icon : Texture
var _sprite3d_icon : Texture


signal node_selected(sprite)


func _ready():
	select_node_dialog.class_filters = ["Sprite", "Sprite3D"]

	select_button.connect("pressed", self, "_on_SelectButton_pressed")
	select_node_dialog.connect("node_selected", self, "_on_SelectNodeDialog_node_selected")


func get_state() -> Dictionary:
	var state := {}

	if sprite:
		state.sprite = sprite

	return state


func set_state(new_state : Dictionary) -> void:
	var new_sprite : Node = new_state.get("sprite")

	if new_sprite != null:
		self.sprite = new_sprite
	else:
		sprite = null
		select_button.text = SELECT_BUTTON_DEFAULT_TEXT
		select_button.icon = _sprite_icon


func _update_theme(editor_theme : EditorTheme) -> void:
	var is_sprite3d := select_button.icon == _sprite3d_icon

	_sprite_icon = editor_theme.get_icon("Sprite")
	_sprite3d_icon = editor_theme.get_icon("Sprite3D")

	if is_sprite3d:
		select_button.icon = _sprite3d_icon
	else:
		select_button.icon = _sprite_icon


# Setters and Getters
func set_sprite(node : Node) -> void:
	sprite = node

	var node_path := node.owner.get_parent().get_path_to(node)
	select_button.text = node_path

	if node.is_class("Sprite"):
		select_button.icon = _sprite_icon
	elif node.is_class("Sprite3D"):
		select_button.icon = _sprite3d_icon


# Signal Callbacks
func _on_SelectButton_pressed() -> void:
	if select_node_dialog.initialize():
		select_node_dialog.popup_centered_ratio(.5)


func _on_SelectNodeDialog_node_selected(selected_node : Node) -> void:
	self.sprite = selected_node
	emit_signal("node_selected", selected_node)
