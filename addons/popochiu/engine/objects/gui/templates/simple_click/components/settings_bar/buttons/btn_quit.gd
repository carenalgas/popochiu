extends "settings_bar_button.gd"

#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	if OS.has_feature("web"):
		hide()


#endregion

#region Virtual ####################################################################################
func _on_pressed() -> void:
	get_tree().quit()


#endregion
