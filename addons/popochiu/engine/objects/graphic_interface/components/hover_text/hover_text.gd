extends PanelContainer
class_name PopochiuHoverText

@onready var hover_text: RichTextLabel = $Label


#region Godot ######################################################################################
func _ready() -> void:
	hover_text.text = ""
	
	G.hover_text_shown.connect(_show_text)


#endregion

#region Virtual ####################################################################################
func _show_text(txt := "") -> void:
	hover_text.text = "[center]%s[/center]" % txt


#endregion
