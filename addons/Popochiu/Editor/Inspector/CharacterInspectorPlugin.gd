tool
extends EditorInspectorPlugin

var ei: EditorInterface

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func can_handle(object: Object) -> bool:
	if object is PopochiuCharacter:
		return true
	return false


func parse_begin(object: Object) -> void:
	if not object.get_parent() is YSort: return
	
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	var label := Label.new()
	
	panel.add_stylebox_override(
		'panel',
		panel.get_stylebox("sub_inspector_bg11", "Editor")
	)
	hbox.rect_min_size.y = 42.0
	label.text = "* Open Node's scene to edit its properties"
	label.autowrap = true
	label.size_flags_horizontal = label.SIZE_EXPAND_FILL
	label.align = Label.ALIGN_CENTER
	label.add_color_override('font_color', Color('c46c71'))
	
	hbox.add_child(label)
	panel.add_child(hbox)
	
	add_custom_control(panel)


#func parse_property(\
#object: Object,
#type: int,
#path: String,
#hint: int,
#hint_text: String,
#usage: int) -> bool:
#	if object and object.get_parent() is YSort and path != 'position':
#		return true
#	return false
