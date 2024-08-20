extends PopochiuSettingsBarButton

#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	if OS.has_feature("web"):
		hide()


#endregion

#region Virtual ####################################################################################
func _on_pressed() -> void:
	G.popup_requested.emit("QuitPopup")


#endregion
