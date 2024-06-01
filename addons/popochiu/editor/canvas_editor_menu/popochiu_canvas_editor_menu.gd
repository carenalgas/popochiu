@tool
extends HBoxContainer
## Used to show new buttons in the EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU (the top bar in the
## 2D editor) to select specific nodes in PopochiuClickable objects.

var _active_popochiu_clickable: Node = null
var _shown_helpers := []

@onready var btn_baseline: Button = %BtnBaseline
@onready var btn_walk_point: Button = %BtnWalkPoint
@onready var btn_interaction_polygon: Button = %BtnInteractionPolygon


#region Godot ######################################################################################
func _ready() -> void:
	# Connect to child signals
	btn_baseline.pressed.connect(_toggle_baseline_visibile)
	btn_walk_point.pressed.connect(_toggle_walk_to_point_visibile)
	btn_interaction_polygon.pressed.connect(_select_interaction_polygon)

	# Connect to singleton signals
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)

	hide()


#endregion

#region Private ####################################################################################
func _toggle_walk_to_point_visibile() -> void:
	#TODO: gizmo visibility logic
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoClickablePlugin.WALK_TO_POINT,
		btn_walk_point.button_pressed
	)


func _toggle_baseline_visibile() -> void:
	#TODO: gizmo visibility logic
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoClickablePlugin.BASELINE,
		btn_baseline.button_pressed
	)


func _select_interaction_polygon() -> void:
	btn_walk_point.set_pressed_no_signal(false)
	btn_baseline.set_pressed_no_signal(false)


	var collision_polygon: CollisionPolygon2D = null

	if PopochiuEditorHelper.is_prop(_active_popochiu_clickable)\
	or PopochiuEditorHelper.is_hotspot(_active_popochiu_clickable):
		collision_polygon = _active_popochiu_clickable.get_node('InteractionPolygon')
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(collision_polygon)
		collision_polygon.get_parent().editing_polygon = true
		collision_polygon.show()

	# TODO: change the function to toggle between the parent and the polygon



func _on_selection_changed():
	_active_popochiu_clickable = null
	hide()

	if EditorInterface.get_selection().get_selected_nodes().is_empty():
		_deselect_all_buttons()
	elif EditorInterface.get_selection().get_selected_nodes().size() != 1:
		for node in EditorInterface.get_selection().get_selected_nodes():
			if node.name in ["InteractionPolygon"]:
				node.hide()
				EditorInterface.get_selection().remove_node.call_deferred(node)
				btn_interaction_polygon.set_pressed_no_signal(false)
	elif EditorInterface.get_selection().get_selected_nodes().size() == 1:
		var selected_node = EditorInterface.get_selection().get_selected_nodes()[0]
		if selected_node.name in ["InteractionPolygon"]:
			_active_popochiu_clickable = selected_node.get_parent()
		else:
			_active_popochiu_clickable = selected_node

	_set_buttons_visibility()


func _set_buttons_visibility():
	if PopochiuEditorHelper.is_prop(_active_popochiu_clickable)\
	or PopochiuEditorHelper.is_hotspot(_active_popochiu_clickable):
		show()


func _deselect_all_buttons() -> void:
	for button: Button in get_children():
		button.set_pressed_no_signal(false)


# Toggles Clickable helpers in order to show walk-to-point, baseline and dialog
# position (PopochiuCharacter) only when a node of that type is selected in the
# scene tree.
# func _check_nodes() -> void:
# 	var deselect_helpers_buttons := false

# 	if EditorInterface.get_selection().get_selected_nodes().is_empty():
# 		deselect_helpers_buttons = true

# 	# Deselect any BaselineHelper or WalkToPointHelper
# 	if EditorInterface.get_selection().get_selected_nodes().size() != 1:
# 		for node in EditorInterface.get_selection().get_selected_nodes():
# 			if node.name in ["InteractionPolygon"]:
# 				EditorInterface.get_selection().remove_node.call_deferred(node)
# 				deselect_helpers_buttons = true

# 	if deselect_helpers_buttons:
# 		_deselect_buttons()

# 	for n in _shown_helpers:
# 		if is_instance_valid(n):
# 			n.hide_helpers()

# 	_shown_helpers.clear()

# 	if not is_instance_valid(EditorInterface.get_selection()): return

# 	for n in EditorInterface.get_selection().get_selected_nodes():
# 		if n.has_method('show_helpers'):
# 			n.show_helpers()
# 			_shown_helpers.append(n)
# 		elif n.get_parent().has_method('show_helpers'):
# 			n.get_parent().show_helpers()
# 			_shown_helpers.append(n.get_parent())

# 	if not is_instance_valid(PopochiuEditorHelper): return

# 	hide()

# 	if EditorInterface.get_selection().get_selected_nodes().size() == 1:
# 		_active_popochiu_clickable = EditorInterface.get_selection().get_selected_nodes()[0]

# 		if PopochiuEditorHelper.is_prop(_active_popochiu_clickable)\
# 		or PopochiuEditorHelper.is_hotspot(_active_popochiu_clickable)\
# 		or PopochiuEditorHelper.is_prop(_active_popochiu_clickable.get_parent())\
# 		or PopochiuEditorHelper.is_hotspot(_active_popochiu_clickable.get_parent()):
# 			if PopochiuEditorHelper.is_prop(_active_popochiu_clickable)\
# 			or PopochiuEditorHelper.is_hotspot(_active_popochiu_clickable):
# 				_deselect_buttons()

# 			show()





#endregion
