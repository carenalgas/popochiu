extends PopochiuSettingsBarButton

#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	if OS.has_feature("web"):
		hide()


#endregion
