extends EditorInspectorPlugin

var ei: EditorInterface


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _can_handle(object: Object) -> bool:
	if object is PopochiuCharacter:
		return true
	return false


func _parse_begin(object: Object) -> void:
	if not object.get_parent() is Node2D: return
	
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	var button := Button.new()
	
	hbox.custom_minimum_size.y = 42.0
	button.text = "* Open Node' scene to edit its properties"
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	panel.add_theme_stylebox_override(
		'panel',
		panel.get_theme_stylebox("sub_inspector_bg11", "Editor")
	)
	button.add_theme_color_override('font_color', Color('c46c71'))
	button.add_theme_color_override('font_color_hover', Color('c46c71'))
	button.add_theme_color_override('font_color_pressed', Color('c46c71'))
	
	button.pressed.connect(
		_open_scene.bind((object as PopochiuCharacter).scene_file_path),
		CONNECT_DEFERRED
	)
	
	hbox.add_child(button)
	panel.add_child(hbox)
	
	add_custom_control(panel)


func _parse_property(
	object: Object,
	type,
	path: String,
	hint,
	hint_text: String,
	usage,
	wide: bool
) -> bool:
	if object and object.get_parent() is Node2D and path != 'position':
		return true
	
	return false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _open_scene(path: String) -> void:
	ei.set_main_screen_editor('2D')
	ei.open_scene_from_path(path)
