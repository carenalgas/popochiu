@tool
class_name PopochiuGizmoClickablePlugin
extends EditorPlugin

# TODO: move these out of the plugin and into Popochiu (enums) or PopochiuClickable
enum {
	WALK_TO_POINT,
	#LOOK_AT_POINT, # TODO: enable this when the look_at_point logic is implemented
	BASELINE,
	DIALOG_POS
}

# Private vars
# State
var _target_node: Node2D
var _undo: EditorUndoRedoManager
var _gizmos: Array
var _active_gizmos: Array
var _grabbed_gizmo: Gizmo2D


#region Godot ######################################################################################

func _enter_tree() -> void:
	# TODO: remove the following 2 lines when the plugin is connected to the appropriate signal
	# e.g. popochiu_ready
	PopochiuEditorConfig.initialize_editor_settings()
	PopochiuConfig.initialize_project_settings()

	# Initialization of the plugin goes here.
	_undo = get_undo_redo()
	_gizmos.insert(WALK_TO_POINT, _init_popochiu_gizmo(WALK_TO_POINT))
	# TODO: enable this when the look_at_point logic is implemented
	# _gizmos.insert(LOOK_AT_POINT, _init_popochiu_gizmo(LOOK_AT_POINT))
	_gizmos.insert(BASELINE, _init_popochiu_gizmo(BASELINE))
	_gizmos.insert(DIALOG_POS, _init_popochiu_gizmo(DIALOG_POS))

	EditorInterface.get_editor_settings().settings_changed.connect(_on_gizmo_settings_changed)
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.connect(_on_gizmo_visibility_changed)


#endregion

#region Virtual ####################################################################################

func _edit(object: Object) -> void:
	if object.get_class() == "EditorDebuggerRemoteObject":
		return
	
	_target_node = object
	_active_gizmos.clear()

	if EditorInterface.get_edited_scene_root() is PopochiuCharacter:
		_active_gizmos.append(_gizmos[DIALOG_POS])
	elif EditorInterface.get_edited_scene_root() is PopochiuRoom:
		_active_gizmos.append(_gizmos[WALK_TO_POINT])
		# TODO: enable this when the look_at_point logic is implemented
		#_active_gizmos.append(_gizmos[LOOK_AT_POINT])
		_active_gizmos.append(_gizmos[BASELINE])

	for gizmo in _active_gizmos:
		gizmo.set_target_node(_target_node)

	if not EditorInterface.get_inspector().property_edited.is_connected(_on_property_changed):
		EditorInterface.get_inspector().property_edited.connect(_on_property_changed)
	update_overlays()


func _forward_canvas_draw_over_viewport(viewport_control: Control) -> void:
	for gizmo in _active_gizmos:
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

#region Private ####################################################################################

func _on_property_changed(property: String):
	update_overlays()


func _on_gizmo_settings_changed() -> void:
	var gizmo_id = 0
	var default_font = EditorInterface.get_editor_theme().default_font

	for gizmo in _gizmos:
		match gizmo_id:
			WALK_TO_POINT:
				gizmo.set_theme(
					PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_WALK_TO_POINT_COLOR),
					PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_HANDLER_SIZE),
					default_font,
					PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_FONT_SIZE)
				)
			# TODO: enable this when the look_at_point logic is implemented
			# LOOK_AT_POINT:
				# gizmo.set_theme(
				# 	PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_LOOK_AT_POINT_COLOR),
				# 	PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_HANDLER_SIZE),
				# 	default_font,
				# 	PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_FONT_SIZE)
				# )
			BASELINE:
				gizmo.set_theme(
					PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_BASELINE_COLOR),
					PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_HANDLER_SIZE),
					default_font,
					PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_FONT_SIZE)
				)
			DIALOG_POS:
				gizmo.set_theme(
					PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_DIALOG_POS_COLOR),
					PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_HANDLER_SIZE),
					default_font,
					PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_FONT_SIZE)
				)

		gizmo.show_connector = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_CONNECTORS)
		gizmo.show_outlines = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_OUTLINE)
		gizmo.show_target_name = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_NODE_NAME)
		gizmo_id += 1
	
	update_overlays()


func _on_gizmo_visibility_changed(gizmo_id:int, visibility:bool):
	if gizmo_id < _gizmos.size():
		_gizmos[gizmo_id].visible = visibility
		update_overlays()

func _update_properties():
	if _grabbed_gizmo and _grabbed_gizmo.target_property:
		_target_node.set(
			_grabbed_gizmo.target_property,
			_grabbed_gizmo.get_position()
		)


func _init_popochiu_gizmo(gizmo_id: int) -> Gizmo2D:
	var gizmo: Gizmo2D
	var default_font = EditorInterface.get_editor_theme().default_font

	match gizmo_id:
		WALK_TO_POINT:
			gizmo = Gizmo2D.new(_target_node, "walk_to_point", "Walk To Point", Gizmo2D.GIZMO_POS)
			gizmo.set_theme(
				PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_WALK_TO_POINT_COLOR),
				PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_HANDLER_SIZE),
				default_font,
				PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_FONT_SIZE)
			)
		# TODO: enable this when the look_at_point logic is implemented
		# LOOK_AT_POINT:
		# 	gizmo = Gizmo2D.new(_target_node, "look_at_point", "Look At Point", Gizmo2D.GIZMO_POS)
		# 	gizmo.set_theme(
		# 		PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_LOOK_AT_POINT_COLOR),
		# 		PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_HANDLER_SIZE),
		# 		default_font,
		# 		PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_FONT_SIZE)
		# 	)
		BASELINE:
			gizmo = Gizmo2D.new(_target_node, "baseline", "Baseline", Gizmo2D.GIZMO_VPOS)
			gizmo.set_theme(
				PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_BASELINE_COLOR),
				PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_HANDLER_SIZE),
				default_font,
				PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_FONT_SIZE)
			)
		DIALOG_POS:
			gizmo = Gizmo2D.new(_target_node, "dialog_pos", "Dialog Position", Gizmo2D.GIZMO_POS)
			gizmo.set_theme(
				PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_DIALOG_POS_COLOR),
				PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_HANDLER_SIZE),
				default_font,
				PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_FONT_SIZE)
			)
	return gizmo


func _try_grab_gizmo(event: InputEventMouseButton) -> bool:
	# Check if the mouse click happened on a gizmo
	# The order is reversed to the topmost gizmo
	# (the last been drawn) is selected
	for i in range(_active_gizmos.size() - 1, -1, -1):
		if not _active_gizmos[i].has_point(event.position):
			continue
		_grabbed_gizmo = _active_gizmos[i]
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
