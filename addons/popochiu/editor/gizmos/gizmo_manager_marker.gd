@tool
class_name GizmoManagerMarker
extends RefCounted

# Configurations
var _color_settings: Dictionary = {}
var _font: Font

# State
var _current_room: PopochiuRoom  # Reference to the current room
var _undo: EditorUndoRedoManager
var _marker_gizmos: Dictionary = {}  # Dictionary of marker nodes to their gizmos
var _grabbed_gizmo: Gizmo2D  # Currently grabbed gizmo
var _grabbed_marker: Marker2D  # Currently grabbed marker node
var _gizmos_visible: bool = true  # Global visibility state


#region Godot ######################################################################################
func _init(undo_manager: EditorUndoRedoManager):
    _undo = undo_manager


#endregion

#region Private #####################################################################################
func _create_marker_gizmo(marker: Marker2D) -> Gizmo2D:
    # Create a gizmo for a specific marker with forced visibility
    var gizmo = Gizmo2D.new(marker, "position", "", Gizmo2D.GIZMO_POS, Gizmo2D.VISIBILITY_MODE_FORCE_SHOW)
    _configure_gizmo(gizmo)
    return gizmo


func _configure_gizmo(gizmo: Gizmo2D) -> void:
    # Apply theme settings
    gizmo.set_theme(
        PopochiuEditorConfig.get_editor_setting(_color_settings[PopochiuGizmoPlugin.MARKER_POS]),
        PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_HANDLER_SIZE),
        _font,
        PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_FONT_SIZE)
    )

    # Apply properties
    gizmo.show_outlines = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_OUTLINE)
    gizmo.show_target_name = true  # Always show the marker's name
    gizmo.show_position = true     # Always show the marker's position
    gizmo.show_connector = false   # Never show the connector for markers
    gizmo.visible = _gizmos_visible # Set visibility based on global state

    # Additional marker-specific settings could be added here


func _scan_for_markers(room: PopochiuRoom) -> void:
    # Clear existing gizmos
    _marker_gizmos.clear()

    # Find the Markers node
    var markers_container = _find_markers_container(room)
    if not markers_container:
        return

    # Find all marker nodes under Markers
    for child in markers_container.get_children():
        if child is Marker2D:
            _marker_gizmos[child] = _create_marker_gizmo(child)


func _find_markers_container(root: Node) -> Node:
    # Find the "Markers" node in the scene
    for child in root.get_children():
        if child.name == "Markers":
            return child
    return null

func _update_properties() -> void:
    if _grabbed_gizmo and _grabbed_marker:
        _grabbed_marker.set(
            _grabbed_gizmo.target_property,
            _grabbed_gizmo.get_position()
        )


#endregion

#region Public #####################################################################################
func initialize_gizmos(font: Font, color_settings: Dictionary) -> void:
    _font = font
    _color_settings = color_settings
    _marker_gizmos.clear()


func handle_object(object: Object, edited_root: Node) -> bool:
    # If we're not in a room, reset and return false
    if not edited_root is PopochiuRoom:
        reset()
        return false

    # Find all markers in the scene
    _current_room = edited_root
    _scan_for_markers(edited_root)
    return _marker_gizmos.size() > 0


func draw_gizmos(viewport_control: Control) -> void:
    # Draw all marker gizmos
    for marker in _marker_gizmos:
        # Check if the marker is available.
        # This avoids errors when the user opens another scene, coming from a room
        # with markers.
        if not is_instance_valid(marker) or not marker.is_inside_tree():
            continue
        # Draw the gizmo
        var gizmo = _marker_gizmos[marker]
        if gizmo.visible:
            gizmo.draw(viewport_control, marker.get(gizmo.target_property))


func try_grab_gizmo(event: InputEventMouseButton) -> bool:
    if _marker_gizmos.is_empty():
        return false

    # Check if the mouse click happened on any marker gizmo
    for marker in _marker_gizmos:
        var gizmo = _marker_gizmos[marker]
        if gizmo.visible and gizmo.has_point(event.position):
            _grabbed_gizmo = gizmo
            _grabbed_marker = marker

            # Hold the gizmo with the mouse
            _grabbed_gizmo.grab(event.position)
            _undo.create_action("Move marker gizmo")
            _undo.add_undo_property(
                marker,
                _grabbed_gizmo.target_property,
                marker.get(_grabbed_gizmo.target_property)
            )
            return true

    return false


func release_gizmo() -> bool:
    if not _grabbed_gizmo:
        return false

    _grabbed_gizmo.release()
    _undo.add_do_property(
        _grabbed_marker,
        _grabbed_gizmo.target_property,
        _grabbed_marker.get(_grabbed_gizmo.target_property)
    )
    _undo.commit_action()
    _grabbed_gizmo = null
    _grabbed_marker = null
    return true


func drag_gizmo(event: InputEventMouseMotion) -> bool:
    if not _grabbed_gizmo:
        return false

    # Drag the gizmo
    _grabbed_gizmo.drag_to(event.position)
    _update_properties()
    return true


func cancel_dragging() -> bool:
    if not _grabbed_gizmo:
        return false

    # Cancel the action
    _grabbed_gizmo.cancel()
    _undo.commit_action()
    _undo.get_history_undo_redo(_undo.get_object_history_id(_grabbed_marker)).undo()
    _grabbed_gizmo = null
    _grabbed_marker = null
    return true


func has_active_gizmo() -> bool:
    return _grabbed_gizmo != null


# Update all existing gizmos
func update_gizmo_settings() -> void:
    for marker in _marker_gizmos:
        _configure_gizmo(_marker_gizmos[marker])


# Set visibility for all marker gizmos
func set_gizmo_visibility(gizmo_id: int, visible: bool) -> void:
    _gizmos_visible = visible

    for marker in _marker_gizmos:
        _marker_gizmos[marker].visible = visible


# Refresh markers when scene changes
func refresh_markers() -> void:
    if _current_room:
        _scan_for_markers(_current_room)


# Clear all marker gizmos and reset internal state.
# Called when changing scenes or explicitly resetting the manager.
func reset() -> void:
    _marker_gizmos.clear()
    _current_room = null
    _grabbed_gizmo = null
    _grabbed_marker = null


#endregion