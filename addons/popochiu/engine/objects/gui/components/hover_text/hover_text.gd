extends Control
class_name PopochiuHoverText

@onready var label: RichTextLabel = $Label


#region Godot ######################################################################################
func _ready() -> void:
	label.text = ""
	
	G.hover_text_shown.connect(_show_text)


#endregion

#region Virtual ####################################################################################
func _show_text(txt := "") -> void:
	label.text = "[center]%s[/center]" % txt


#endregion
