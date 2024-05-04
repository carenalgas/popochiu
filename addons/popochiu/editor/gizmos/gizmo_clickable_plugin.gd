@tool
extends EditorPlugin

# TODO: move these out of the plugin and into Popochiu (enums) or PopochiuClickable
enum {
	WALK_TO_POINT,
	#LOOK_AT_POINT,
	BASELINE
}

# Private vars
# State
var _target_node: Node2D
var _undo: EditorUndoRedoManager
var _gizmos: Array
var _grabbed_gizmo: Gizmo2D


#region Virtual Methods implementations
func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	_undo = get_undo_redo()
	_gizmos.insert(WALK_TO_POINT, _init_popochiu_gizmo(WALK_TO_POINT))
	#_gizmos.insert(LOOK_AT_POINT, _init_popochiu_gizmo(LOOK_AT_POINT))
	_gizmos.insert(BASELINE, _init_popochiu_gizmo(BASELINE))
	print(_gizmos.size())


func _edit(object: Object) -> void:
	_target_node = object
	for gizmo in _gizmos:
		gizmo.set_target_node(_target_node)
	if not EditorInterface.get_inspector().property_edited.is_connected(_on_property_changed):
		EditorInterface.get_inspector().property_edited.connect(_on_property_changed)
	update_overlays()


func _forward_canvas_draw_over_viewport(viewport_control: Control) -> void:
	print("Drawing")
	for gizmo in _gizmos:
		print(gizmo._label)
		gizmo.draw(viewport_control, _target_node.get(gizmo.target_property))


func _handles(object: Object) -> bool:
	return object is PopochiuClickable


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if not _target_node or not _target_node.is_visible_in_tree():
		return false

	# For left mouse buttons, try to grab or release, depending on state
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Grab
		if not _grabbed_gizmo and event.is_pressed():
			return _try_grab_gizmo(event)
		# Release
		elif _grabbed_gizmo and event.is_released():
			return _release_gizmo(event)

	# For mouse movement, drag the grabbed gizmo
	if event is InputEventMouseMotion:
		return _drag_gizmo(event)

	# For ESC key or comparable events, cancel the dragging if in place
	if event.is_action_pressed("ui_cancel"):
		return _cancel_dragging_gizmo(event)
	
	## Nothing to handle outside the cases above
	return false
#endregion


#region Signals handlers
func _on_property_changed(property: String):
	update_overlays()
#endregion


#region Private Methods
func _update_properties():
	if _grabbed_gizmo and _grabbed_gizmo.target_property:
		_target_node.set(
			_grabbed_gizmo.target_property,
			_grabbed_gizmo.get_position()
		)


func _init_popochiu_gizmo(gizmo_id: int) -> Gizmo2D:
	var gizmo: Gizmo2D
	match gizmo_id:
		WALK_TO_POINT:
			gizmo = Gizmo2D.new(_target_node, "walk_to_point", "Walk To Point", Gizmo2D.GIZMO_POS)
			gizmo.set_theme(
				Color.RED, # TODO: take this from PopochiuSettings
				24, # TODO: take this from PopochiuSettings
				EditorInterface.get_editor_theme().default_font,
				EditorInterface.get_editor_theme().default_font_size
			)
		# LOOK_AT_POINT:
		# 	gizmo = Gizmo2D.new(_target_node, "LOOK_AT_POINT_Position", "Look At Point", Gizmo2D.GIZMO_POS)
		# 	gizmo.set_theme(
		# 		Color.GREEN, # TODO: take this from PopochiuSettings
		# 		24, # TODO: take this from PopochiuSettings
		# 		EditorInterface.get_editor_theme().default_font,
		# 		EditorInterface.get_editor_theme().default_font_size
		# 	)
		BASELINE:
			gizmo = Gizmo2D.new(_target_node, "baseline", "Baseline", Gizmo2D.GIZMO_VPOS)
			gizmo.set_theme(
				Color.DARK_ORANGE, # TODO: take this from PopochiuSettings
				24, # TODO: take this from PopochiuSettings
				EditorInterface.get_editor_theme().default_font,
				EditorInterface.get_editor_theme().default_font_size
			)
	return gizmo


func _try_grab_gizmo(event: InputEvent) -> bool:
	# Check if the mouse click happened on a gizmo
	# The order is reversed to the topmost gizmo
	# (the last been drawn) is selected
	for i in range(_gizmos.size() - 1, -1, -1):
		if not _gizmos[i].has_point(event.position):
			continue
		_grabbed_gizmo = _gizmos[i]
		break

	# If user clicked on no gizmos
	# ignore the event
	if not _grabbed_gizmo:
		return false

	# hold the gizmo with the mouse
	_grabbed_gizmo.grab(event.position)
	_undo.create_action("Move gizmo")
	_undo.add_undo_property(
		_grabbed_gizmo.target_node,
		_grabbed_gizmo.target_property,
		_grabbed_gizmo.target_node.get(_grabbed_gizmo.target_property)
	)
	update_overlays()
	return true


func _release_gizmo(event: InputEvent) -> bool:
	# If there is no gizmo to release
	# ignore the event
	if not _grabbed_gizmo:
		return false
		
	_grabbed_gizmo.release()
	_undo.add_do_property(
		_grabbed_gizmo.target_node,
		_grabbed_gizmo.target_property,
		_grabbed_gizmo.target_node.get(_grabbed_gizmo.target_property)
	)
	_undo.commit_action()
	update_overlays()
	_grabbed_gizmo = null
	return true


func _drag_gizmo(event: InputEvent) -> bool:
	# If no gizmo to drag
	# ignore the event
	if not _grabbed_gizmo:
		return false

	# Drag the gizmo
	_grabbed_gizmo.drag_to(event.position)
	_update_properties()
	update_overlays()
	return true


func _cancel_dragging_gizmo(event: InputEvent) -> bool:
	# If ESC/Cancel happens but we're not dragging
	# ignore the event
	if not _grabbed_gizmo:
		return false
	
	# Cancel the action
	_grabbed_gizmo.cancel()
	_undo.commit_action()
	_undo.get_history_undo_redo(_undo.get_object_history_id(_grabbed_gizmo.target_node)).undo()
	update_overlays()
	_grabbed_gizmo = null
	return true
#endregion
