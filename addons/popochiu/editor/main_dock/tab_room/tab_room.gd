@tool
extends PopochiuTreeDock
# Handles the Room tab in Popochiu's dock. Uses a native [Tree] control to display the objects of
# the currently open room grouped by type.
#
# Each object type is handled by a specialized row class (see rows/). Room objects (Props,
# Hotspots, Regions, Markers, Walkable areas) share a common base; Characters in room are special.
#
# Ref: #558

var opened_room: PopochiuRoom = null
var opened_room_state_path: String = ""

var rows_paths := []
var characters_in_room := []
var _add_character_menu: PopupMenu

var _rows := {
	PopochiuResources.Types.PROP: PopochiuPropRow,
	PopochiuResources.Types.HOTSPOT: PopochiuHotspotRow,
	PopochiuResources.Types.REGION: PopochiuRegionRow,
	PopochiuResources.Types.MARKER: PopochiuMarkerRow,
	PopochiuResources.Types.WALKABLE_AREA: PopochiuWalkableAreaRow,
	PopochiuResources.Types.CHARACTER: PopochiuCharacterInRoomRow,
}
var _row_instances := {}

@onready var room_name: Button = %RoomName
@onready var no_room_info: Label = %NoRoomInfo
@onready var tool_buttons: HBoxContainer = %ToolButtons
@onready var btn_script: Button = %BtnScript
@onready var btn_resource: Button = %BtnResource
@onready var btn_resource_script: Button = %BtnResourceScript


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Create the row instances and their groups for each object type
	for type_key: int in _rows:
		var row: PopochiuDockRow = _rows[type_key].new(self)
		_row_instances[type_key] = row
		row.create_group()
		set_create_disabled(row.group, true)
	
	# Add the "Add character to room" button to the Characters group
	var chars_group: TreeItem = _row_instances[PopochiuResources.Types.CHARACTER].group
	add_button(
		chars_group, get_theme_icon("Load", "EditorIcons"), PopochiuDockRow.Buttons.ADD_CHARACTER,
		"Add character to room"
	)
	set_button_disabled(chars_group, PopochiuDockRow.Buttons.ADD_CHARACTER, true)
	
	# Connect to the base class signals
	item_clicked.connect(_on_item_clicked)
	button_clicked.connect(_on_item_button_clicked)
	menu_item_selected.connect(_on_menu_item_selected)
	create_clicked.connect(_on_create_clicked)
	group_button_clicked.connect(_on_group_button_clicked)
	
	# Setup the tool buttons
	btn_script.icon = get_theme_icon("Script", "EditorIcons")
	btn_resource.icon = get_theme_icon("Object", "EditorIcons")
	btn_resource_script.icon = get_theme_icon("GDScript", "EditorIcons")
	
	room_name.pressed.connect(_edit_root_node)
	btn_script.pressed.connect(_open_room_script)
	btn_resource.pressed.connect(_edit_resource)
	btn_resource_script.pressed.connect(_open_resource_script)
	
	# Setup the add-character menu
	_add_character_menu = PopupMenu.new()
	_add_character_menu.id_pressed.connect(_on_character_selected)
	add_child(_add_character_menu)
	
	# Initial state: no room open
	_set_no_room_state()


#endregion

#region Public #####################################################################################
func scene_changed(scene_root: Node) -> void:
	# Set the default tab state
	if is_instance_valid(opened_room):
		await _clear_content()
	
	if not scene_root is PopochiuRoom:
		return
	
	if scene_root is PopochiuRoom and scene_root.script_name.is_empty():
		PopochiuUtils.print_error("This room doesn't have a [code]script_name[/code] value!")
		return
	
	if opened_room == scene_root:
		return
	
	# Updated the opened room's info
	opened_room = scene_root
	opened_room_state_path = PopochiuResources.get_data_value(
		"rooms", opened_room.script_name, ""
	)
	
	if not PopochiuEditorHelper.undo_redo.history_changed.is_connected(_check_undoredo_history):
		PopochiuEditorHelper.undo_redo.history_changed.connect(_check_undoredo_history)
	
	room_name.text = opened_room.script_name
	
	room_name.show()
	tool_buttons.show()
	filter.show()
	tree.show()
	no_room_info.hide()
	
	# Enable the create buttons and the add-character button, and listen to node additions/deletions
	for type_key: int in _rows:
		var row: PopochiuDockRow = _row_instances[type_key]
		set_create_disabled(row.group, false)
		
		var container: Node2D = opened_room.get_node(row.get_parent_name())
		container.child_entered_tree.connect(_on_child_added.bind(row))
		container.child_exiting_tree.connect(_on_child_removed.bind(row))
	set_button_disabled(
		_row_instances[PopochiuResources.Types.CHARACTER].group,
		PopochiuDockRow.Buttons.ADD_CHARACTER,
		false
	)
	
	# Fill info of Props, Hotspots, Walkable areas, Regions and Points
	for type_key: int in _rows:
		var row: PopochiuDockRow = _row_instances[type_key]
		for child in opened_room.call(row.get_method()):
			row.create_row(child)
	
	get_parent().current_tab = 1


func scene_closed(filepath: String) -> void:
	if is_instance_valid(opened_room) and opened_room.scene_file_path == filepath:
		_clear_content()


#endregion

#region Private ####################################################################################
func _set_no_room_state() -> void:
	room_name.hide()
	tool_buttons.hide()
	filter.hide()
	tree.hide()
	no_room_info.show()


func _clear_content() -> void:
	for type_key: int in _rows:
		var row: PopochiuDockRow = _row_instances[type_key]
		var container: Node2D = opened_room.get_node(row.get_parent_name())
		
		if container.child_entered_tree.is_connected(_on_child_added):
			container.child_entered_tree.disconnect(_on_child_added)
		
		if container.child_exiting_tree.is_connected(_on_child_removed):
			container.child_exiting_tree.disconnect(_on_child_removed)
	
	if PopochiuEditorHelper.undo_redo.history_changed.is_connected(_check_undoredo_history):
		PopochiuEditorHelper.undo_redo.history_changed.disconnect(_check_undoredo_history)
	
	opened_room = null
	opened_room_state_path = ""
	
	characters_in_room.clear()
	rows_paths.clear()
	
	clear_items()
	
	# Disable the create buttons and the add-character button
	for row: PopochiuDockRow in _row_instances.values():
		set_create_disabled(row.group, true)
	set_button_disabled(
		_row_instances[PopochiuResources.Types.CHARACTER].group,
		PopochiuDockRow.Buttons.ADD_CHARACTER,
		true
	)
	
	_set_no_room_state()
	await get_tree().process_frame


func _on_item_clicked(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	_row_instances[data.type].on_item_clicked(item)


func _on_item_button_clicked(item: TreeItem, id: int) -> void:
	var data := item.get_metadata(COL_TEXT)
	_row_instances[data.type].on_button_clicked(item, id)


func _on_group_button_clicked(group_item: TreeItem, id: int) -> void:
	match id:
		PopochiuDockRow.Buttons.ADD_CHARACTER:
			_open_add_character_menu()


func _on_menu_item_selected(item: TreeItem, id: int) -> void:
	var data := item.get_metadata(COL_TEXT)
	_row_instances[data.type].on_menu_item_selected(item, id)


func _on_create_clicked(group_item: TreeItem) -> void:
	var type_key: int = group_item.get_metadata(COL_TEXT).type
	PopochiuEditorHelper.show_creation_popup(_row_instances[type_key].get_popup())


func _get_menu_cfg(item: TreeItem) -> Array:
	var data := item.get_metadata(COL_TEXT)
	return _row_instances[data.type].get_menu_cfg(item)


func _get_location(path: String) -> String:
	# Structure of path: "res://game/rooms/room_name/props/prop_name/"
	# path split: [res:, popochiu, rooms, room_name, props, prop_name]
	return "Room%s" % (path.split("/", false)[3]).to_pascal_case()


func _remove_from_core(item: TreeItem, should_save_and_delete := true) -> void:
	var data := item.get_metadata(COL_TEXT)
	_row_instances[data.type].remove_from_core(item, should_save_and_delete)


func _edit_root_node() -> void:
	_select_file()
	_select_root_node()


func _select_file() -> void:
	EditorInterface.select_file(opened_room.scene_file_path)


func _select_root_node() -> void:
	PopochiuEditorHelper.select_node(EditorInterface.get_edited_scene_root())


func _open_room_script() -> void:
	EditorInterface.select_file(opened_room.get_script().resource_path)
	EditorInterface.set_main_screen_editor("Script")
	EditorInterface.edit_script(opened_room.get_script())


func _edit_resource() -> void:
	EditorInterface.select_file(opened_room_state_path)
	EditorInterface.edit_resource(load(opened_room_state_path))


func _open_resource_script() -> void:
	var prd: PopochiuRoomData = load(opened_room_state_path)
	EditorInterface.select_file(prd.get_script().resource_path)
	EditorInterface.set_main_screen_editor("Script")
	EditorInterface.edit_resource(prd.get_script())


# Fills the list to show after pressing "+ Add character to room" and listens to selections to add
# the clicked character to the room
func _open_add_character_menu() -> void:
	_add_character_menu.clear()
	
	var idx := 0
	for key in PopochiuResources.get_section_keys("characters"):
		_add_character_menu.add_item(key, idx)
		_add_character_menu.set_item_disabled(idx, characters_in_room.has(key))
		
		idx += 1
	
	_add_character_menu.popup(Rect2i(DisplayServer.mouse_get_position(), Vector2i.ZERO))


# Adds the clicked character in the "+ Add character to room" menu to the current room
func _on_character_selected(id: int) -> void:
	var char_name := _add_character_menu.get_item_text(
		_add_character_menu.get_item_index(id)
	)
	var instance: PopochiuCharacter = (load(
		"res://game/characters/%s/character_%s.tscn".replace("%s", char_name.to_snake_case())
	) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	
	opened_room.get_node("Characters").add_child(instance)
	instance.owner = opened_room

	EditorInterface.save_scene()
	PopochiuEditorHelper.select_node(instance)


func _on_child_added(node: Node, row: PopochiuDockRow) -> void:
	row.create_row(node)
	row.on_child_added(node)


func _on_child_removed(node: Node, row: PopochiuDockRow) -> void:
	row.on_child_removed(node)


func _check_undoredo_history() -> void:
	if not opened_room or not is_instance_valid(opened_room):
		return
	
	var walkable_areas: Array = opened_room.call(
		_row_instances[PopochiuResources.Types.WALKABLE_AREA].get_method()
	)
	
	if walkable_areas.is_empty(): return
	
	for wa: PopochiuWalkableArea in walkable_areas:
		(wa.get_node("Perimeter") as NavigationRegion2D).bake_navigation_polygon()


#endregion