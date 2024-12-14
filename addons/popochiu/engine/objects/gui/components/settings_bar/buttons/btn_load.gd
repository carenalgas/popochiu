extends PopochiuSettingsBarButton


#region Godot ######################################################################################
func _ready() -> void:
	super()
	PopochiuUtils.e.game_saved.connect(show)
	
	if PopochiuUtils.e.has_save():
		show()
	else:
		hide()


#endregion
