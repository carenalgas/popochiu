extends 'toolbar_button.gd'

@export var btn_states := [] # (Array, Texture2D)
@export var states_descriptions := ['normal', 'fast', 'immediate']


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	texture_normal = btn_states[E.current_text_speed_idx]


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_pressed() -> void:
	E.change_text_speed()
	texture_normal = btn_states[E.current_text_speed_idx]

	G.show_info(self.description)


func get_description() -> String:
	return '%s: %s' % [description, states_descriptions[E.current_text_speed_idx]]
