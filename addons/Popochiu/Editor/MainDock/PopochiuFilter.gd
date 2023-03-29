tool
extends LineEdit

var groups := {} setget set_groups


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	right_icon = get_icon('Search', 'EditorIcons')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_groups(value: Dictionary) -> void:
	groups = value
	
	if groups:
		connect('text_changed', PopochiuUtils, 'filter_rows', [groups])
