extends RichTextLabel
class_name PopochiuHoverText


#region Godot ######################################################################################
func _ready() -> void:
	text = ""
	
	G.hover_text_shown.connect(_show_text)


#endregion

#region Virtual ####################################################################################
func _show_text(txt := "") -> void:
	text = "[center]%s[/center]" % txt


#endregion
