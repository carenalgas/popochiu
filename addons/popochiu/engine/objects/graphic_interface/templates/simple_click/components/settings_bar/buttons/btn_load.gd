extends "settings_bar_button.gd"


#region Godot ######################################################################################
func _ready() -> void:
	super()
	E.game_saved.connect(show)
	
	if E.has_save():
		show()
	else:
		hide()


#endregion

#region Virtual ####################################################################################
func _on_pressed() -> void:
	G.show_load()


#endregion
