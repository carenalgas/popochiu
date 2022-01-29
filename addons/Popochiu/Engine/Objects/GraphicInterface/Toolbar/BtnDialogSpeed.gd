extends ToolbarButton

export(Array, Texture) var btn_states := []
export var states_descriptions := ['normal', 'rápido', 'inmediato']


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	texture_normal = btn_states[E.text_speed_idx]


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_pressed() -> void:
	E.text_speed_idx = wrapi(E.text_speed_idx + 1, 0, btn_states.size())
	texture_normal = btn_states[E.text_speed_idx]

	G.show_info(self.description)


func get_description() -> String:
	return '%s: %s' % [description, states_descriptions[E.text_speed_idx]]
