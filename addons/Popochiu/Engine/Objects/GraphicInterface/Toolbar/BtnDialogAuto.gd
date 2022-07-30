extends 'ToolbarButton.gd'

export(Array, Texture) var btn_states := []
export var states_descriptions := ['manual', 'automático']


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	texture_normal = btn_states[
		1 if E.settings.text_continue_auto else 0
	]


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_pressed() -> void:
	E.settings.text_continue_auto =\
	!E.settings.text_continue_auto
	texture_normal = btn_states[
		1 if E.settings.text_continue_auto else 0
	]

	G.show_info(self.description)


func get_description() -> String:
	return '%s: %s' % [
		description,
		states_descriptions[
			1 if E.settings.text_continue_auto else 0
		]
	]
