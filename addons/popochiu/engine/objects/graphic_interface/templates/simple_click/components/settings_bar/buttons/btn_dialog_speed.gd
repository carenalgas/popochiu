extends 'settings_bar_button.gd'

@export var btn_states := [] # (Array, Texture2D)
@export var states_descriptions := ['normal', 'fast', 'immediate']


#region Godot ######################################################################################
func _ready() -> void:
	super()
	texture_normal = btn_states[E.current_text_speed_idx]


#endregion

#region Virtual ####################################################################################
func _on_pressed() -> void:
	E.change_text_speed()
	texture_normal = btn_states[E.current_text_speed_idx]

	G.show_hover_text(self.description)


#endregion

#region SetGet #####################################################################################
func get_description() -> String:
	return '%s: %s' % [description, states_descriptions[E.current_text_speed_idx]]


#endregion
