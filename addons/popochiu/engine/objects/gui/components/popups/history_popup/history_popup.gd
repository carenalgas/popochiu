@tool
extends PopochiuPopup

@export var dialog_line: PackedScene = null
@export var interaction_line: PackedScene = null

@onready var lines_list: VBoxContainer = find_child("LinesList")
@onready var empty: Label = %Empty
@onready var lines_scroll: ScrollContainer = %LinesScroll


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	if Engine.is_editor_hint(): return
	
	for c in lines_list.get_children():
		(c as Control).queue_free()


#endregion

#region Virtual ####################################################################################
func _open() -> void:
	if E.history.is_empty():
		empty.show()
		lines_scroll.hide()
	else:
		empty.hide()
		lines_scroll.show()
	
	for data in E.history:
		var lbl: RichTextLabel
		
		if data.has("character"):
			lbl = dialog_line.instantiate()
			lbl.text = "[color=%s]%s:[/color] %s" % [
				(data.character as PopochiuCharacter).text_color.to_html(false),
				(data.character as PopochiuCharacter).description,
				data.text
			]
		else:
			lbl = interaction_line.instantiate()
			lbl.text = "[color=edf171]%s[/color] [color=a9ff9f]%s[/color]" % [
				data.action, data.target
			]
	
		lines_list.add_child(lbl)


func _close() -> void:
	for c in lines_list.get_children():
		(c as Control).queue_free()


#endregion
