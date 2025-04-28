@tool
class_name GizmoManagerClickable
extends RefCounted

# Configurations
var _color_settings: Dictionary = {}
var _font: Font

# State
var _target_node: Node2D
var _undo: EditorUndoRedoManager
var _gizmos: Array[Gizmo2D] = []
var _active_gizmos: Array[Gizmo2D] = []
var _grabbed_gizmo: Gizmo2D


#region Godot ######################################################################################
func _init(undo_manager: EditorUndoRedoManager):
    _undo = undo_manager
    _gizmos.resize(4)


#endregion

#region Private #####################################################################################
func _init_gizmo(gizmo_id: int) -> Gizmo2D:
    var gizmo: Gizmo2D
    
    match gizmo_id:
        PopochiuGizmoPlugin.WALK_TO_POINT:
            gizmo = Gizmo2D.new(_target_node, "walk_to_point", "Walk To Point", Gizmo2D.GIZMO_OFFSET)
        PopochiuGizmoPlugin.LOOK_AT_POINT:
            gizmo = Gizmo2D.new(_target_node, "look_at_point", "Look At Point", Gizmo2D.GIZMO_OFFSET)
        PopochiuGizmoPlugin.BASELINE:
            gizmo = Gizmo2D.new(_target_node, "baseline", "Baseline", Gizmo2D.GIZMO_VOFFSET)
        PopochiuGizmoPlugin.DIALOG_POS:
            gizmo = Gizmo2D.new(_target_node, "dialog_pos", "Dialog Position", Gizmo2D.GIZMO_OFFSET)
    
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
    gizmo.show_connector = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_CONNECTORS)
    gizmo.show_target_name = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_NODE_NAME)
    gizmo.show_outlines = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_OUTLINE)
    gizmo.show_position = PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_SHOW_POSITION)


func _update_properties() -> void:
    if _grabbed_gizmo and _grabbed_gizmo.target_property:
        _target_node.set(
            _grabbed_gizmo.target_property,
            _grabbed_gizmo.get_position()
        )


#endregion

#region Public #####################################################################################
func initialize_gizmos(font: Font, color_settings: Dictionary) -> void:
    _font = font
    _color_settings = color_settings

    # Initialize gizmos for PopochiuClickable objects
    _gizmos[PopochiuGizmoPlugin.WALK_TO_POINT] = _init_gizmo(PopochiuGizmoPlugin.WALK_TO_POINT)
    _gizmos[PopochiuGizmoPlugin.LOOK_AT_POINT] = _init_gizmo(PopochiuGizmoPlugin.LOOK_AT_POINT)
    _gizmos[PopochiuGizmoPlugin.BASELINE] = _init_gizmo(PopochiuGizmoPlugin.BASELINE)
    _gizmos[PopochiuGizmoPlugin.DIALOG_POS] = _init_gizmo(PopochiuGizmoPlugin.DIALOG_POS)


func handle_object(object: Object, edited_root: Node) -> bool:
    if not object is PopochiuClickable:
        reset()
        return false

    _target_node = object
    _active_gizmos.clear()

    # Add the appropriate gizmos for clickable objects
    if edited_root is PopochiuCharacter:
        _active_gizmos.append(_gizmos[PopochiuGizmoPlugin.DIALOG_POS])
    elif edited_root is PopochiuRoom:
        _active_gizmos.append(_gizmos[PopochiuGizmoPlugin.WALK_TO_POINT])
        _active_gizmos.append(_gizmos[PopochiuGizmoPlugin.LOOK_AT_POINT])
        _active_gizmos.append(_gizmos[PopochiuGizmoPlugin.BASELINE])

    for gizmo in _active_gizmos:
        gizmo.set_target_node(_target_node)

    return _active_gizmos.size() > 0


func draw_gizmos(viewport_control: Control) -> void:
    for gizmo in _active_gizmos:
        gizmo.draw(viewport_control, _target_node.get(gizmo.target_property))


func try_grab_gizmo(event: InputEventMouseButton) -> bool:
    if not _target_node or _active_gizmos.is_empty():
        return false

    # Check if the mouse click happened on a gizmo (in reverse order)
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
    _undo.create_action("Move clickable gizmo")
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


# Clear all active gizmos and reset internal state.
# Called when changing scenes or explicitly resetting the manager.
func reset() -> void:
    _active_gizmos.clear()
    _target_node = null
    _grabbed_gizmo = null


#endregion