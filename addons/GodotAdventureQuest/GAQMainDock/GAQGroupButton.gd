tool
extends Button

export var target_group: NodePath

var open_icon: Texture = load('res://addons/GodotAdventureQuest/GAQMainDock/icons/group_arrow-open.png')
var closed_icon: Texture = load('res://addons/GodotAdventureQuest/GAQMainDock/icons/group_arrow-closed.png')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
# TODO: ?


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func _toggled(button_pressed: bool) -> void:
	icon = open_icon if button_pressed else closed_icon
	
	if get_node_or_null(target_group):
		if button_pressed: get_node(target_group).show()
		else: get_node(target_group).hide()
