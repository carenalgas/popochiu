extends "settings_bar_button.gd"

@export var btn_states := [] # (Array, Texture2D)
@export var states_descriptions := ["manual", "auto"]


#region Godot ######################################################################################
func _ready() -> void:
	super()
	texture_normal = _get_texture()


#endregion

#region Virtual ####################################################################################
func _on_pressed() -> void:
	E.settings.auto_continue_text = !E.settings.auto_continue_text
	texture_normal = _get_texture()

	G.show_hover_text(self.description)


#endregion

#region SetGet #####################################################################################
func get_description() -> String:
	return "%s: %s" % [description, states_descriptions[1 if E.settings.auto_continue_text else 0]]


#endregion

#region Private ####################################################################################
func _get_texture() -> Texture2D:
	return btn_states[1 if E.settings.auto_continue_text else 0]


#endregion
