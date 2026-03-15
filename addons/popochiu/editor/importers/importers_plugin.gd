@tool
extends EditorPlugin

const DOCKS_PATH := "res://addons/popochiu/editor/importers/aseprite/docks/"
const INSPECTOR_DOCK = preload(DOCKS_PATH + "aseprite_importer_dock.tscn")
const CONFIG_SCRIPT = preload("res://addons/popochiu/editor/config/config.gd")
const INSPECTOR_DOCK_CHARACTER := DOCKS_PATH + "aseprite_importer_dock_character.gd"
const INSPECTOR_DOCK_ROOM := DOCKS_PATH + "aseprite_importer_dock_room.gd"
const INSPECTOR_DOCK_INVENTORY := DOCKS_PATH + "aseprite_importer_dock_inventory.gd"

## Available importer types and their configurations.
enum ImporterType {
	CHARACTER,
	ROOM,
	INVENTORY
}

var _tab_container: TabContainer = null
var _dock_tabs: Dictionary = {}
var _scene_check_timer: Timer
var _current_scene_path := PopochiuEditorHelper.EMPTY_STRING
var _popup_active := false


#region Godot ######################################################################################
func _enter_tree() -> void:
	# Create the main tab container dock
	_tab_container = TabContainer.new()
	_tab_container.name = "Importers"
	
	# Create all importer tabs
	_create_importer_tabs()

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

	# Update dock visibility based on current scene
	_update_dock_visibility()


func _exit_tree() -> void:
	# Stop and remove timer
	if _scene_check_timer:
		_scene_check_timer.stop()
		_scene_check_timer.queue_free()

	# Clean up dock tabs
	_cleanup_dock_tabs()

	# Remove the main dock if it exists
	if _tab_container and _tab_container.is_inside_tree():
		remove_control_from_docks(_tab_container)
		_tab_container.queue_free()


#endregion

#region Private ######################################################################################
func _on_scene_changed(scene_root: Node) -> void:
	_current_scene_path = scene_root.scene_file_path if scene_root else PopochiuEditorHelper.EMPTY_STRING
	_update_dock_visibility()

	# Check if we need to restart the timer
	# TODO: Remove this workaround when
	# https://github.com/godotengine/godot/issues/97427
	# gets fixed
	if _no_valid_scene_open():
		# Restart the timer if the editor only has an empty scene opened.
		_scene_check_timer.start()
	else:
		# We are in a valid scene, so we can stop the timer
		if not _scene_check_timer.is_stopped():
			_scene_check_timer.stop()


## Creates all importer tabs and stores them in the _dock_tabs dictionary.
func _create_importer_tabs() -> void:
	# Create Character tab
	_dock_tabs[ImporterType.CHARACTER] = _create_importer_tab(ImporterType.CHARACTER, "Character", INSPECTOR_DOCK_CHARACTER)

	# Create Room tab
	_dock_tabs[ImporterType.ROOM] = _create_importer_tab(ImporterType.ROOM, "Room", INSPECTOR_DOCK_ROOM)

	# Create Inventory tab
	_dock_tabs[ImporterType.INVENTORY] = _create_importer_tab(ImporterType.INVENTORY, "Inventory", INSPECTOR_DOCK_INVENTORY)


## Creates a single importer tab with the specified configuration.
func _create_importer_tab(type: ImporterType, tab_name: String, script_path: String) -> Control:
	var tab := INSPECTOR_DOCK.instantiate()
	tab.name = tab_name
	tab.set_script(load(script_path))
	
	# Initialize common properties
	tab.file_system = EditorInterface.get_resource_filesystem()
	
	_tab_container.add_child(tab)
	return tab


## Updates dock visibility and tab states based on the current scene.
func _update_dock_visibility() -> void:
	# Add dock if not already present
	if _tab_container and not _tab_container.is_inside_tree():
		add_control_to_dock(DOCK_SLOT_RIGHT_BL, _tab_container)
	
	# Update tab visibility and initialization
	_update_tab_states()


## Updates the visibility and initialization of individual tabs.
func _update_tab_states() -> void:
	var target_node := EditorInterface.get_edited_scene_root()
	var active_tab_set := false
	
	# Update Character tab
	_update_tab_for_type(ImporterType.CHARACTER, PopochiuEditorHelper.is_editing_character(), target_node)
	
	# Update Room tab
	_update_tab_for_type(ImporterType.ROOM, PopochiuEditorHelper.is_editing_room(), target_node)
	
	# Update Inventory tab (always visible and available)
	_update_tab_for_type(ImporterType.INVENTORY, true, null)
	
	# Set appropriate active tab
	_set_appropriate_active_tab()


## Updates a specific tab's visibility and initialization.
func _update_tab_for_type(type: ImporterType, should_show: bool, target_node: Node) -> void:
	if not _dock_tabs.has(type):
		return
		
	var importer: Control = _dock_tabs[type]
	var tab_index := importer.get_index()
	
	# Hide/show the tab in the TabContainer
	_tab_container.set_tab_hidden(tab_index, not should_show)
	
	if should_show and target_node and type != ImporterType.INVENTORY:
		# Initialize tab with target node (except inventory which doesn't need a target)
		importer.target_node = target_node
		importer.init()
	elif should_show and type == ImporterType.INVENTORY:
		# Initialize inventory tab (doesn't need a target node)
		importer.init()


## Sets the appropriate active tab based on current scene context.
func _set_appropriate_active_tab() -> void:
	var character_tab_index:int = _dock_tabs[ImporterType.CHARACTER].get_index()
	var room_tab_index:int = _dock_tabs[ImporterType.ROOM].get_index()
	var inventory_tab_index:int = _dock_tabs[ImporterType.INVENTORY].get_index()
	
	if PopochiuEditorHelper.is_editing_character() and not _tab_container.is_tab_hidden(character_tab_index):
		_tab_container.current_tab = character_tab_index
	elif PopochiuEditorHelper.is_editing_room() and not _tab_container.is_tab_hidden(room_tab_index):
		_tab_container.current_tab = room_tab_index
	elif not _tab_container.is_tab_hidden(inventory_tab_index):
		_tab_container.current_tab = inventory_tab_index


## Cleans up all dock tabs and their resources.
func _cleanup_dock_tabs() -> void:
	for tab in _dock_tabs.values():
		if is_instance_valid(tab):
			tab.queue_free()
	_dock_tabs.clear()


# Workaround for https://github.com/godotengine/godot/issues/97427
# Check we're in the bug trigger condition when:
# 1. Current scene is empty AND
# 2. It's the only open scene
func _no_valid_scene_open() -> bool:
	return (
		(
			EditorInterface.get_edited_scene_root() == null
			or EditorInterface.get_edited_scene_root().scene_file_path.is_empty()
		)
		and EditorInterface.get_open_scenes().size() <= 1
	)


# TODO: Remove this workaround when
# https://github.com/godotengine/godot/issues/97427
# gets fixed
func _check_for_scene_change() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not is_instance_valid(root):
		return
	var scene_path := root.scene_file_path
	# Check if this is a new scene with a path
	if scene_path != _current_scene_path and not scene_path.is_empty():
		_current_scene_path = scene_path
		# Stop the timer and process the scene change
		_scene_check_timer.stop()
		_on_scene_changed(root)


#endregion
