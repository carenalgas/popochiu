extends EditorInspectorPlugin

var ei: EditorInterface


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _can_handle(object: Object) -> bool:
	if object is PopochiuWalkableArea or object is NavigationRegion2D:
		return true
	return false


func _parse_begin(object: Object) -> void:
	if object is PopochiuWalkableArea:
		_parse_walkable_area(object)
	if object is NavigationRegion2D:
		_parse_navigation_polygon_instance(object)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _parse_walkable_area(object: Object) -> void:
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	var button := Button.new() # Adding a button to edit polygon

	panel.add_theme_stylebox_override(
		'panel',
		panel.get_theme_stylebox("sub_inspector_bg11", "Editor")
	)
	
	hbox.custom_minimum_size.y = 42.0
	hbox.alignment = HBoxContainer.ALIGNMENT_CENTER
	button.text = "Edit Polygon"
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	button.pressed.connect(_find_polygon_instance.bind(object), CONNECT_DEFERRED)
	
	hbox.add_child(button)
	panel.add_child(hbox)
	
	add_custom_control(panel)


func _find_polygon_instance(object: Object) -> void:
	if not object is PopochiuWalkableArea: return
	var children = object.get_children()
	ei.edit_node(children[0])


func _parse_navigation_polygon_instance(object: Object) -> void:
	if not object.get_parent() is PopochiuWalkableArea: return
	
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	var button := Button.new() # Adding a button to edit polygon
	
	panel.add_theme_stylebox_override(
		'panel',
		panel.get_theme_stylebox("sub_inspector_bg11", "Editor")
	)
	
	hbox.custom_minimum_size.y = 42.0
	hbox.alignment = HBoxContainer.ALIGNMENT_CENTER
	button.text = "Editing done"
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	button.pressed.connect(_back_to_walkable_area.bind(object), CONNECT_DEFERRED)
	
	hbox.add_child(button)
	panel.add_child(hbox)
	
	add_custom_control(panel)


func _back_to_walkable_area(object: Object) -> void:
	if not object.get_parent() is PopochiuWalkableArea: return
	ei.edit_node(object.get_parent())
