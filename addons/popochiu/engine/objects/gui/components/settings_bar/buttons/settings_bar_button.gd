class_name PopochiuSettingsBarButton
extends TextureButton

@export var description := "" : get = get_description
@export var script_name := ""


#region Godot ######################################################################################
func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


#endregion

#region SetGet #####################################################################################
func get_description() -> String:
	return description


#endregion

#region Private ####################################################################################
func _on_mouse_entered() -> void:
	PopochiuUtils.g.show_hover_text(self.description)


func _on_mouse_exited() -> void:
	PopochiuUtils.g.show_hover_text()


#endregion
