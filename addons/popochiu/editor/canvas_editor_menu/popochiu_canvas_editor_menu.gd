@tool
extends HBoxContainer
## Used to show new buttons in the EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU (the top bar in the
## 2D editor) to select specific nodes in PopochiuClickable objects.

var _selected_node: Node = null
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
	EditorInterface.get_selection().selection_changed.connect(_check_nodes)
	
	hide()


#endregion

#region Private ####################################################################################
func _toggle_walk_to_point_visibile() -> void:
	#TODO: gizmo visibility logic
	pass


func _toggle_baseline_visibile() -> void:
	#TODO: gizmo visibility logic
	pass


func _select_interaction_polygon() -> void:
	btn_walk_point.set_pressed_no_signal(false)
	btn_baseline.set_pressed_no_signal(false)
	
	EditorInterface.get_selection().clear()
	
	var collision_polygon: CollisionPolygon2D = null
	
	if PopochiuEditorHelper.is_prop(_selected_node)\
	or PopochiuEditorHelper.is_hotspot(_selected_node):
		collision_polygon = _selected_node.get_node('InteractionPolygon')
	else:
		collision_polygon = _selected_node.get_node('../InteractionPolygon')
	
	EditorInterface.get_selection().add_node(collision_polygon)
	collision_polygon.get_parent().editing_polygon = true


# Toggles Clickable helpers in order to show walk-to-point, baseline and dialog
# position (PopochiuCharacter) only when a node of that type is selected in the
# scene tree.
func _check_nodes() -> void:
	var deselect_helpers_buttons := false
	
	if EditorInterface.get_selection().get_selected_nodes().is_empty():
		deselect_helpers_buttons = true

	# Deselect any BaselineHelper or WalkToPointHelper
	if EditorInterface.get_selection().get_selected_nodes().size() != 1:
		for node in EditorInterface.get_selection().get_selected_nodes():
			if node.name in ["InteractionPolygon"]:
				EditorInterface.get_selection().remove_node.call_deferred(node)
				deselect_helpers_buttons = true

	if deselect_helpers_buttons:
		_deselect_buttons()
	
	for n in _shown_helpers:
		if is_instance_valid(n):
			n.hide_helpers()
	
	_shown_helpers.clear()
	
	if not is_instance_valid(EditorInterface.get_selection()): return
	
	for n in EditorInterface.get_selection().get_selected_nodes():
		if n.has_method('show_helpers'):
			n.show_helpers()
			_shown_helpers.append(n)
		elif n.get_parent().has_method('show_helpers'):
			n.get_parent().show_helpers()
			_shown_helpers.append(n.get_parent())
	
	if not is_instance_valid(PopochiuEditorHelper): return
	
	hide()

	if EditorInterface.get_selection().get_selected_nodes().size() == 1:
		_selected_node = EditorInterface.get_selection().get_selected_nodes()[0]
		
		if PopochiuEditorHelper.is_prop(_selected_node)\
		or PopochiuEditorHelper.is_hotspot(_selected_node)\
		or PopochiuEditorHelper.is_prop(_selected_node.get_parent())\
		or PopochiuEditorHelper.is_hotspot(_selected_node.get_parent()):
			if PopochiuEditorHelper.is_prop(_selected_node)\
			or PopochiuEditorHelper.is_hotspot(_selected_node):
				_deselect_buttons()
			
			show()


func _deselect_buttons() -> void:
	for button: Button in get_children():
		button.set_pressed_no_signal(false)


#endregion
