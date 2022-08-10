extends 'ToolbarButton.gd'

export(Array, Texture) var btn_states := []
export var states_descriptions := ['manual', 'automático']


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	texture_normal = btn_states[
		1 if E.settings.auto_continue_text else 0
	]


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_pressed() -> void:
	E.settings.auto_continue_text =\
	!E.settings.auto_continue_text
	texture_normal = btn_states[
		1 if E.settings.auto_continue_text else 0
	]

	G.show_info(self.description)


func get_description() -> String:
	return '%s: %s' % [
		description,
		states_descriptions[
			1 if E.settings.auto_continue_text else 0
		]
	]
