extends 'ToolbarButton.gd'

export(Array, Texture) var btn_states := []
export var states_descriptions := ['manual', 'automático']


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	texture_normal = btn_states[1 if E.text_continue_auto else 0]


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_pressed() -> void:
	E.text_continue_auto = !E.text_continue_auto
	texture_normal = btn_states[1 if E.text_continue_auto else 0]

	G.show_info(self.description)


func get_description() -> String:
	return '%s: %s' % [
		description, states_descriptions[1 if E.text_continue_auto else 0]
	]
