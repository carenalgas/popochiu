@tool
extends EditorPlugin

const DOCKS_PATH := "res://addons/popochiu/editor/importers/aseprite/docks/"
const INSPECTOR_DOCK = preload(DOCKS_PATH + "aseprite_importer_inspector_dock.tscn")
const CONFIG_SCRIPT = preload("res://addons/popochiu/editor/config/config.gd")
const INSPECTOR_DOCK_CHARACTER := DOCKS_PATH + "aseprite_importer_inspector_dock_character.gd"
const INSPECTOR_DOCK_ROOM := DOCKS_PATH + "aseprite_importer_inspector_dock_room.gd"

var _dock: Control = null
var _target_node: Node = null

func _enter_tree() -> void:
    # Create the dock but don't add it yet
    _dock = INSPECTOR_DOCK.instantiate()
    _dock.name = "Importers"
    
    # Connect to scene change signals
    scene_changed.connect(_on_scene_changed)
    
    # Initial check
    _update_dock_visibility()


func _exit_tree() -> void:
    # Remove the dock and free resources
    if _dock:
        if _dock.is_inside_tree():
            remove_control_from_docks(_dock)
        _dock.queue_free()


func _on_scene_changed(scene_root: Node) -> void:
    _update_dock_visibility()


func _update_dock_visibility() -> void:
    # If the dock is currently in the tree, remove it first
    if _dock and _dock.is_inside_tree():
        remove_control_from_docks(_dock)
    
    if PopochiuEditorHelper.is_editing_room():
        # Configure for room
        _dock.set_script(load(INSPECTOR_DOCK_ROOM))
    # IMPROVE: this call has to be changed to is_editing_character() as soon as
    # #393 is merged
    elif PopochiuEditorHelper.is_character(EditorInterface.get_edited_scene_root()):
        # Configure for character
        _dock.set_script(load(INSPECTOR_DOCK_CHARACTER))

    _dock.target_node = EditorInterface.get_edited_scene_root()
    _dock.file_system = EditorInterface.get_resource_filesystem()
    add_control_to_dock(DOCK_SLOT_RIGHT_BL, _dock)
