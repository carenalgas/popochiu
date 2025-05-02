@tool
extends EditorPlugin

const DOCKS_PATH := "res://addons/popochiu/editor/importers/aseprite/docks/"
const INSPECTOR_DOCK = preload(DOCKS_PATH + "aseprite_importer_inspector_dock.tscn")
const CONFIG_SCRIPT = preload("res://addons/popochiu/editor/config/config.gd")
const INSPECTOR_DOCK_CHARACTER := DOCKS_PATH + "aseprite_importer_inspector_dock_character.gd"
const INSPECTOR_DOCK_ROOM := DOCKS_PATH + "aseprite_importer_inspector_dock_room.gd"

var _dock: Control = null
var _target_node: Node = null
var _scene_check_timer: Timer
var _current_scene_path: String = ""
var _popup_active = false


func _enter_tree() -> void:
	# Create the dock but don't add it yet
	_dock = INSPECTOR_DOCK.instantiate()
	_dock.name = "Importers"

	# Connect to scene change signals
	scene_changed.connect(_on_scene_changed)

	# Create a timer to poll for "first scene opened" event
	# This is a workaround for https://github.com/godotengine/godot/issues/97427
	_scene_check_timer = Timer.new()
	add_child(_scene_check_timer)
	_scene_check_timer.wait_time = 0.1
	_scene_check_timer.one_shot = false
	_scene_check_timer.timeout.connect(_check_for_scene_change)

	# Start timer if there is no valid scene open
	if _no_valid_scene_open():
		_scene_check_timer.start()

	# Add the dock to the editor, only if needed
	_update_dock_visibility()


func _exit_tree() -> void:
	# Stop and remove timer
	if _scene_check_timer:
		_scene_check_timer.stop()
		_scene_check_timer.queue_free()

	# Remove the dock and free resources
	if _dock:
		if _dock.is_inside_tree():
			remove_control_from_docks(_dock)
		_dock.queue_free()


# Workaround for # https://github.com/godotengine/godot/issues/97427
# Check we're in the bug trigger condition when:
# 1. Current scene is empty AND
# 2. It's the only open scene
func _no_valid_scene_open() -> bool:
	return (
		(
			EditorInterface.get_edited_scene_root() == null
			or EditorInterface.get_edited_scene_root().scene_file_path.is_empty()
		)
		and EditorInterface.get_open_scenes().size() <=1
	)


# TODO: Remove this workaround when
# https://github.com/godotengine/godot/issues/97427
# gets fixed
func _check_for_scene_change() -> void:
	var root = EditorInterface.get_edited_scene_root()
	if root:
		var scene_path = root.scene_file_path
		# Check if this is a new scene with a path
		if scene_path != _current_scene_path and not scene_path.is_empty():
			_current_scene_path = scene_path
			# Stop the timer and process the scene change
			_scene_check_timer.stop()
			_on_scene_changed(root)


func _on_scene_changed(scene_root: Node) -> void:
	_current_scene_path = scene_root.scene_file_path if scene_root else ""
	_update_dock_visibility()

	# Check if we need to restart the timer
	# TODO: Remove this workaround when
	# https://github.com/godotengine/godot/issues/97427
	# gets fixed
	if _no_valid_scene_open():
		# Restart the timer if the editor only has an empty scene
		# opened.
		_scene_check_timer.start()
	else:
		# We are in a valid scene, so we can stop the timer
		if not _scene_check_timer.is_stopped():
			_scene_check_timer.stop()


func _update_dock_visibility() -> void:
	if _dock and _dock.is_inside_tree():
		remove_control_from_docks(_dock)

	# First check if we should show the dock at all
	if not (
		PopochiuEditorHelper.is_editing_room()
		or PopochiuEditorHelper.is_editing_character()
	):
		return
	
	# Choose the right script based on node type
	var target_node = EditorInterface.get_edited_scene_root()
	var script_path = ""
	
	if PopochiuEditorHelper.is_editing_room():
		script_path = INSPECTOR_DOCK_ROOM
	elif PopochiuEditorHelper.is_editing_character():
		script_path = INSPECTOR_DOCK_CHARACTER
	
	# Only change the script if needed (avoid unnecessary reloads)
	if _dock.get_script() != load(script_path):
		_dock.set_script(load(script_path))
	
	# Initialize the dock with the new target
	_dock.target_node = target_node
	_dock.file_system = EditorInterface.get_resource_filesystem()
	_dock.init()
	
	# Add to docks (not already there)
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, _dock)
