extends EditorInspectorPlugin

var ei: EditorInterface

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func can_handle(object: Object) -> bool:
	if object is PopochiuCharacter:
		return true
	if object is PopochiuWalkableArea:
		return true
	if object is NavigationPolygonInstance:
		return true
	return false


func parse_begin(object: Object) -> void:
	if object is PopochiuCharacter:
		_parse_character(object)
	if object is PopochiuWalkableArea:
		_parse_walkable_area(object)
	if object is NavigationPolygonInstance:
		_parse_navigation_polygon_instance(object)


func _parse_navigation_polygon_instance(object: Object) -> void:
	if not object.get_parent() is PopochiuWalkableArea: return

	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	var button := Button.new() # Adding a button to edit polygon
	
	panel.add_stylebox_override(
		'panel',
		panel.get_stylebox("sub_inspector_bg11", "Editor")
	)

	hbox.rect_min_size.y = 42.0
	hbox.alignment = HBoxContainer.ALIGN_CENTER


	button.text = "Editing done"
	button.size_flags_stretch_ratio = Button.SIZE_EXPAND
	button.align = Button.ALIGN_CENTER
	button.connect("pressed", self, "_back_to_walkable_area", [object], CONNECT_DEFERRED)
	
	hbox.add_child(button)
	panel.add_child(hbox)
	add_custom_control(panel)


func _parse_walkable_area(object: Object) -> void:
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	var button := Button.new() # Adding a button to edit polygon
	
	panel.add_stylebox_override(
		'panel',
		panel.get_stylebox("sub_inspector_bg11", "Editor")
	)

	hbox.rect_min_size.y = 42.0
	hbox.alignment = HBoxContainer.ALIGN_CENTER


	button.text = "Edit Polygon"
	button.size_flags_stretch_ratio = Button.SIZE_EXPAND
	button.align = Button.ALIGN_CENTER
	button.connect("pressed", self, "_find_polygon_instance", [object], CONNECT_DEFERRED)
	
	hbox.add_child(button)
	panel.add_child(hbox)
	add_custom_control(panel)


func _parse_character(object: Object) -> void:
	if not object.get_parent() is YSort: return
	
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	var label := Label.new()
	
	panel.add_stylebox_override(
		'panel',
		panel.get_stylebox("sub_inspector_bg11", "Editor")
	)
	hbox.rect_min_size.y = 42.0
	label.text = "* Open Node' scene to edit its properties"
	label.autowrap = true
	label.size_flags_horizontal = label.SIZE_EXPAND_FILL
	label.align = Label.ALIGN_CENTER
	label.add_color_override('font_color', Color('c46c71'))
	
	hbox.add_child(label)
	
	panel.add_child(hbox)
	
	add_custom_control(panel)


func _back_to_walkable_area(object: Object) -> void:
	if not object.get_parent() is PopochiuWalkableArea: return
	ei.edit_node(object.get_parent())


func _find_polygon_instance(object: Object) -> void:
	if not object is PopochiuWalkableArea: return
	var children = object.get_children()
	ei.edit_node(children[0])


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
