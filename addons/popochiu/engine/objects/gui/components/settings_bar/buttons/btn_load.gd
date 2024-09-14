extends PopochiuSettingsBarButton


#region Godot ######################################################################################
func _ready() -> void:
	super()
	E.game_saved.connect(show)
	
	if E.has_save():
		show()
	else:
		hide()


#endregion
