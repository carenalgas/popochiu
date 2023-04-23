tool
extends EditorInspectorPlugin ## TODO: create a base class with pointer variables

var ei: EditorInterface
var fs: EditorFileSystem
var config: Reference

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func can_handle(object: Object) -> bool:
	if object is PopochiuCharacter:
		return true
	return false


func parse_begin(object: Object) -> void:
	if not object.get_parent() is YSort: return
	
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	var button := Button.new()
	
	panel.add_stylebox_override(
		'panel',
		panel.get_stylebox("sub_inspector_bg11", "Editor")
	)
	hbox.rect_min_size.y = 42.0
	button.text = "* Open Node's scene to edit its properties"
	button.size_flags_horizontal = button.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = button.CURSOR_POINTING_HAND
	button.align = Label.ALIGN_CENTER
	
	button.add_color_override('font_color', Color('c46c71'))
	button.add_color_override('font_color_hover', Color('c46c71'))
	button.add_color_override('font_color_pressed', Color('c46c71'))
	button.connect('pressed', self, '_open_scene', [
		(object as PopochiuCharacter).filename
	])
	
	hbox.add_child(button)
	panel.add_child(hbox)
	
	add_custom_control(panel)


func parse_property(\
	object: Object,
	type: int,
	path: String,
	hint: int,
	hint_text: String,
	usage: int) -> bool:
	if object and object.get_parent() is YSort and path != 'position':
		return true
	return false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _open_scene(path: String) -> void:
	ei.set_main_screen_editor('2D')
	ei.open_scene_from_path(path)
