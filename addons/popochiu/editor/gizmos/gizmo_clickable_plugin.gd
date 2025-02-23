@tool
class_name PopochiuGizmoClickablePlugin
extends EditorPlugin

# TODO: move these out of the plugin and into Popochiu (enums) or PopochiuClickable
enum {
	WALK_TO_POINT,
	LOOK_AT_POINT,
	BASELINE,
	DIALOG_POS,
	MARKER_POS
}

# Private vars
# State
var _target_node: Node2D
var _undo: EditorUndoRedoManager
var _gizmos: Array
var _active_gizmos: Array
var _grabbed_gizmo: Gizmo2D

# Appearance
var _color_settings: Dictionary = {}
var _font: Font


#region Godot ######################################################################################

func _enter_tree() -> void:
	# TODO: remove the following 2 lines when the plugin is connected to the appropriate signal
	# e.g. popochiu_ready
	PopochiuEditorConfig.initialize_editor_settings()
	PopochiuConfig.initialize_project_settings()

	# Read theme settings
	_init_theme_settings()

	# Initialization of the plugin goes here.
	_undo = get_undo_redo()
	# Initialize gizmos for PopochiuClickable objects
	_gizmos.insert(WALK_TO_POINT, _init_popochiu_gizmo(WALK_TO_POINT))
	_gizmos.insert(LOOK_AT_POINT, _init_popochiu_gizmo(LOOK_AT_POINT))
	_gizmos.insert(BASELINE, _init_popochiu_gizmo(BASELINE))
	_gizmos.insert(DIALOG_POS, _init_popochiu_gizmo(DIALOG_POS))
	# Initialize gizmo for PopochiuMarker objects
	_gizmos.insert(MARKER_POS, _init_popochiu_gizmo(MARKER_POS))

	# Connect signals to update gizmos when editor settings or visibility change
	EditorInterface.get_editor_settings().settings_changed.connect(_on_gizmo_settings_changed)
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.connect(_on_gizmo_visibility_changed)


#endregion

#region Virtual ####################################################################################
func _edit(object: Object) -> void:
	# If the object is null or a remote object, this plugin should not kick in
	if object == null or object.get_class() == "EditorDebuggerRemoteObject":
		return
	# If the user isn't editing a Room or Character scene, no gizmos should be shown
	if not (
		EditorInterface.get_edited_scene_root() is PopochiuCharacter or
		EditorInterface.get_edited_scene_root() is PopochiuRoom
	):
		return

	# Set the target node (the selected object in the scene tree)
	# and clear the active gizmos list, we'll then add the appropriate ones
	_target_node = object
	_active_gizmos.clear()

	# Add the appropriate gizmos for the selected object
	if EditorInterface.get_edited_scene_root() is PopochiuCharacter:
		_active_gizmos.append(_gizmos[DIALOG_POS])
	elif EditorInterface.get_edited_scene_root() is PopochiuRoom:
		if object is PopochiuClickable:
			_active_gizmos.append(_gizmos[WALK_TO_POINT])
			_active_gizmos.append(_gizmos[LOOK_AT_POINT])
			_active_gizmos.append(_gizmos[BASELINE])
		elif object is PopochiuMarker:
			_active_gizmos.append(_gizmos[MARKER_POS])

	for gizmo in _active_gizmos:
		gizmo.set_target_node(_target_node)

	if not EditorInterface.get_inspector().property_edited.is_connected(_on_property_changed):
		EditorInterface.get_inspector().property_edited.connect(_on_property_changed)
	update_overlays()


func _forward_canvas_draw_over_viewport(viewport_control: Control) -> void:
	for gizmo in _active_gizmos:
		gizmo.draw(viewport_control, _target_node.get(gizmo.target_property))


func _handles(object: Object) -> bool:
	return object is PopochiuClickable \
		or object is PopochiuMarker


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
func _init_theme_settings() -> void:
	# read color settings (done every time to allow for runtime changes)
	_color_settings = {
		WALK_TO_POINT: PopochiuEditorConfig.GIZMOS_WALK_TO_POINT_COLOR,
		LOOK_AT_POINT: PopochiuEditorConfig.GIZMOS_LOOK_AT_POINT_COLOR,
		BASELINE: PopochiuEditorConfig.GIZMOS_BASELINE_COLOR,
		DIALOG_POS: PopochiuEditorConfig.GIZMOS_DIALOG_POS_COLOR,
		MARKER_POS: PopochiuEditorConfig.GIZMOS_MARKER_POINT_COLOR
	}
	# set default font from editor
	_font = EditorInterface.get_editor_theme().default_font


func _init_popochiu_gizmo(gizmo_id: int) -> Gizmo2D:
	var gizmo: Gizmo2D

	match gizmo_id:
		WALK_TO_POINT:
			gizmo = Gizmo2D.new(_target_node, "walk_to_point", "Walk To Point", Gizmo2D.GIZMO_POS)
		LOOK_AT_POINT:
			gizmo = Gizmo2D.new(_target_node, "look_at_point", "Look At Point", Gizmo2D.GIZMO_POS)
		BASELINE:
			gizmo = Gizmo2D.new(_target_node, "baseline", "Baseline", Gizmo2D.GIZMO_VPOS)
		DIALOG_POS:
			gizmo = Gizmo2D.new(_target_node, "dialog_pos", "Dialog Position", Gizmo2D.GIZMO_POS)
		MARKER_POS:
			# No label for markers, 'cause their gizmos only show their position (coords)
			gizmo = Gizmo2D.new(_target_node, "marker_point", "", Gizmo2D.GIZMO_POS)

	_set_gizmo_theme(gizmo, gizmo_id)
	_set_gizmo_properties(gizmo, gizmo_id)
	return gizmo


func _set_gizmo_theme(gizmo: Gizmo2D, gizmo_id: int) -> void:
	gizmo.set_theme(
		PopochiuEditorConfig.get_editor_setting(_color_settings[gizmo_id]),
		PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_HANDLER_SIZE),
		_font,
		PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_FONT_SIZE)
	)


func _set_gizmo_properties(gizmo: Gizmo2D, gizmo_id: int) -> void:
	# These defaults work well for all PopochiuClickable gizmos
	gizmo.show_connector = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_CONNECTORS)
	gizmo.show_target_name = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_NODE_NAME)
	gizmo.show_outlines = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_OUTLINE)
	gizmo.show_position = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_POSITION)

	# Special overrides for PopochiuMarker gizmos
	if gizmo_id == MARKER_POS:
		# Always show the marker's position
		gizmo.show_position = true
		# Never show the connector, 'cause the marker center is in 0,0
		# and the gizmo is updating a special property, not the node's position
		gizmo.show_connector = false


func _on_property_changed(_property: String):
	# Update gizmos that are currently visible on the scene
	# to reflect the new property value
	update_overlays()


func _on_gizmo_settings_changed() -> void:
	# Update theme settings
	_init_theme_settings()

	# Update gizmos appearance based on the new settings
	for gizmo_id in _gizmos.size():
		_set_gizmo_theme(_gizmos[gizmo_id], gizmo_id)
		_set_gizmo_properties(_gizmos[gizmo_id], gizmo_id)
	
	# Update gizmos that are currently visible on the scene
	# to reflect the new settings
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
