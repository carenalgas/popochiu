@tool
class_name GizmoManagerMarker
extends RefCounted

enum {
    MARKER_POS
}

# Configurations
var _color_settings: Dictionary = {}
var _font: Font

# State
var _target_node: Node2D
var _undo: EditorUndoRedoManager
var _gizmos: Array[Gizmo2D] = []
var _active_gizmos: Array[Gizmo2D] = []
var _grabbed_gizmo: Gizmo2D

func _init(undo_manager: EditorUndoRedoManager):
    _undo = undo_manager
    _gizmos.resize(1)

func initialize_gizmos(font: Font, color_settings: Dictionary) -> void:
    _font = font
    _color_settings = color_settings
    
    # Initialize marker gizmo
    _gizmos[MARKER_POS] = _init_gizmo(MARKER_POS)

func _init_gizmo(gizmo_id: int) -> Gizmo2D:
    var gizmo: Gizmo2D
    
    # No label for markers, 'cause their gizmos only show their position (coords)
    gizmo = Gizmo2D.new(_target_node, "coordinates", "", Gizmo2D.GIZMO_POS)
    
    _set_gizmo_theme(gizmo, gizmo_id)
    _set_gizmo_properties(gizmo)
    return gizmo

func _set_gizmo_theme(gizmo: Gizmo2D, gizmo_id: int) -> void:
    gizmo.set_theme(
        PopochiuEditorConfig.get_editor_setting(_color_settings[gizmo_id]),
        PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_HANDLER_SIZE),
        _font,
        PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_FONT_SIZE)
    )

func _set_gizmo_properties(gizmo: Gizmo2D) -> void:
    # Base properties from config
    gizmo.show_connector = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_CONNECTORS)
    gizmo.show_outlines = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_OUTLINE)
    
    # Always show the marker's name
    gizmo.show_target_name = true
    # Always show the marker's position
    gizmo.show_position = true
    # Never show the connector, cause the marker center is in 0,0
    gizmo.show_connector = false

func handle_object(object: Object, edited_root: Node) -> bool:
    if not object is PopochiuMarker:
        _active_gizmos.clear()
        return false
    
    _target_node = object
    _active_gizmos.clear()
    
    # Add marker gizmo if we're in a room
    if edited_root is PopochiuRoom:
        _active_gizmos.append(_gizmos[MARKER_POS])
    
    for gizmo in _active_gizmos:
        gizmo.set_target_node(_target_node)
    
    return _active_gizmos.size() > 0

func draw_gizmos(viewport_control: Control) -> void:
    for gizmo in _active_gizmos:
        gizmo.draw(viewport_control, _target_node.get(gizmo.target_property))

func try_grab_gizmo(event: InputEventMouseButton) -> bool:
    if not _target_node or _active_gizmos.is_empty():
        return false
        
    # Check if the mouse click happened on a gizmo
    for i in range(_active_gizmos.size() - 1, -1, -1):
        if not _active_gizmos[i].has_point(event.position):
            continue
        _grabbed_gizmo = _active_gizmos[i]
        break

    # If user clicked on no gizmos, ignore the event
    if not _grabbed_gizmo:
        return false

    # Hold the gizmo with the mouse
    _grabbed_gizmo.grab(event.position)
    _undo.create_action("Move marker gizmo")
    _undo.add_undo_property(
        _grabbed_gizmo.target_node,
        _grabbed_gizmo.target_property,
        _grabbed_gizmo.target_node.get(_grabbed_gizmo.target_property)
    )
    return true

func release_gizmo() -> bool:
    if not _grabbed_gizmo:
        return false
        
    _grabbed_gizmo.release()
    _undo.add_do_property(
        _grabbed_gizmo.target_node,
        _grabbed_gizmo.target_property,
        _grabbed_gizmo.target_node.get(_grabbed_gizmo.target_property)
    )
    _undo.commit_action()
    _grabbed_gizmo = null
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
    _undo.get_history_undo_redo(_undo.get_object_history_id(_grabbed_gizmo.target_node)).undo()
    _grabbed_gizmo = null
    return true

func has_active_gizmo() -> bool:
    return _grabbed_gizmo != null

func update_gizmo_settings() -> void:
    for gizmo_id in _gizmos.size():
        _set_gizmo_theme(_gizmos[gizmo_id], gizmo_id)
        _set_gizmo_properties(_gizmos[gizmo_id])

func set_gizmo_visibility(gizmo_id: int, visible: bool) -> void:
    if gizmo_id < _gizmos.size():
        _gizmos[gizmo_id].visible = visible

func _update_properties() -> void:
    if _grabbed_gizmo and _grabbed_gizmo.target_property:
        _target_node.set(
            _grabbed_gizmo.target_property,
            _grabbed_gizmo.get_position()
        )