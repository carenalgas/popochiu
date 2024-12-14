extends Control
class_name PopochiuHoverText

@export var hide_during_dialogs := false

@onready var label: RichTextLabel = $RichTextLabel


#region Godot ######################################################################################
func _ready() -> void:
	label.text = ""
	
	# Connect to autoloads' signals
	PopochiuUtils.g.hover_text_shown.connect(_show_text)
	PopochiuUtils.g.dialog_line_started.connect(_on_dialog_line_started)
	PopochiuUtils.g.dialog_line_finished.connect(_on_dialog_line_finished)


#endregion

#region Virtual ####################################################################################
func _show_text(txt := "") -> void:
	label.text = "[center]%s[/center]" % txt


#endregion

#region Private ####################################################################################
func _on_dialog_line_started() -> void:
	if hide_during_dialogs:
		hide()


func _on_dialog_line_finished() -> void:
	if hide_during_dialogs:
		show()


#endregion
