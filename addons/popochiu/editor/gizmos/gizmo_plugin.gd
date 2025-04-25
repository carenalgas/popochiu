@tool
class_name PopochiuGizmoPlugin
extends EditorPlugin

# Gizmo type enums for external visibility mapping
enum {
    WALK_TO_POINT,
    LOOK_AT_POINT,
    BASELINE,
    DIALOG_POS,
    MARKER_POS
}

# Private vars
# State
var _undo: EditorUndoRedoManager
var _clickable_manager: GizmoManagerClickable
var _marker_manager: GizmoManagerMarker

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

    # Initialization of the plugin
    _undo = get_undo_redo()
    
    # Initialize managers
    _clickable_manager = GizmoManagerClickable.new(_undo)
    _marker_manager = GizmoManagerMarker.new(_undo)
    
    # Setup gizmos in managers
    _clickable_manager.initialize_gizmos(_font, _color_settings)
    _marker_manager.initialize_gizmos(_font, _color_settings)

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
        PopochiuEditorHelper.is_editing_room() or
        PopochiuEditorHelper.is_editing_character()
    ):
        # Clear all gizmos when not in a relevant scene
        _marker_manager.reset()
        _clickable_manager.reset()
        return

    # Track if any managers are handling objects
    var has_handled_objects = false
    var edited_root = EditorInterface.get_edited_scene_root()

    # Always call the marker manager with the edited root
    # This ensures markers are shown in rooms and cleared in other scenes
    has_handled_objects = _marker_manager.handle_object(edited_root, edited_root) or has_handled_objects

    # Handle clickables with the currently selected object
    has_handled_objects = _clickable_manager.handle_object(object, edited_root) or has_handled_objects

    # If any manager is handling objects, connect to inspector signal
    if has_handled_objects:
        if not EditorInterface.get_inspector().property_edited.is_connected(_on_property_changed):
            EditorInterface.get_inspector().property_edited.connect(_on_property_changed)

    update_overlays()


func _forward_canvas_draw_over_viewport(viewport_control: Control) -> void:
    # Only draw gizmos in Room or Character scenes.
    # This is necessary to aviod errors when opening scenes that are not rooms or characters,
    # coming from a room with markers! Godot calls this method still once before loading the
    # new scene but it finds no markers to attach to.
    if not (PopochiuEditorHelper.is_editing_room() or PopochiuEditorHelper.is_editing_character()):
        return

    _clickable_manager.draw_gizmos(viewport_control)
    _marker_manager.draw_gizmos(viewport_control)


func _handles(object: Object) -> bool:
    var edited_root = EditorInterface.get_edited_scene_root()
    return \
        edited_root is PopochiuCharacter or \
        edited_root is PopochiuRoom or \
        edited_root is PopochiuCharacter


func _forward_canvas_gui_input(event: InputEvent) -> bool:
    # For left mouse buttons, try to grab or release, depending on state
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        # Grab
        if not _clickable_manager.has_active_gizmo() and not _marker_manager.has_active_gizmo() and event.is_pressed():
            if _clickable_manager.try_grab_gizmo(event) or _marker_manager.try_grab_gizmo(event):
                update_overlays()
                return true
        # Release
        elif (_clickable_manager.has_active_gizmo() or _marker_manager.has_active_gizmo()) and event.is_released():
            if _clickable_manager.release_gizmo() or _marker_manager.release_gizmo():
                update_overlays()
                return true

    # For mouse movement, drag the grabbed gizmo
    if event is InputEventMouseMotion:
        if _clickable_manager.drag_gizmo(event) or _marker_manager.drag_gizmo(event):
            update_overlays()
            return true

    # For ESC key or comparable events, cancel the dragging if in place
    if event.is_action_pressed("ui_cancel"):
        if _clickable_manager.cancel_dragging() or _marker_manager.cancel_dragging():
            update_overlays()
            return true
    
    # Nothing to handle outside the cases above
    return false

#endregion

#region Private ####################################################################################

func _init_theme_settings() -> void:
    # Read color settings (done every time to allow for runtime changes)
    _color_settings = {
        WALK_TO_POINT: PopochiuEditorConfig.GIZMOS_WALK_TO_POINT_COLOR,
        LOOK_AT_POINT: PopochiuEditorConfig.GIZMOS_LOOK_AT_POINT_COLOR,
        BASELINE: PopochiuEditorConfig.GIZMOS_BASELINE_COLOR,
        DIALOG_POS: PopochiuEditorConfig.GIZMOS_DIALOG_POS_COLOR,
        MARKER_POS: PopochiuEditorConfig.GIZMOS_MARKER_POS_COLOR
    }
    # Set default font from editor
    _font = EditorInterface.get_editor_theme().default_font


func _on_property_changed(_property: String):
    # Update gizmos that are currently visible on the scene
    # to reflect the new property value
    update_overlays()


func _on_gizmo_settings_changed() -> void:
    # Update theme settings
    _init_theme_settings()

    # Update gizmos appearance based on the new settings
    _clickable_manager.initialize_gizmos(_font, _color_settings)
    _marker_manager.initialize_gizmos(_font, _color_settings)
    
    # Update gizmos in the viewport
    update_overlays()


func _on_gizmo_visibility_changed(gizmo_id: int, visibility: bool):
    # The visibility enum values match between plugin and clickable manager
    if gizmo_id <= DIALOG_POS:
        _clickable_manager.set_gizmo_visibility(gizmo_id, visibility)
    # The MARKER_POS enum value is different between the two systems
    elif gizmo_id == MARKER_POS:
        _marker_manager.set_gizmo_visibility(0, visibility)
    
    update_overlays()

#endregion
