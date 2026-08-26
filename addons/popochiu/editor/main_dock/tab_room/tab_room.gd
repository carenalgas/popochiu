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

const CHARACTER_ICON = preload("res://addons/popochiu/icons/character.svg")

var _rows := {
	PopochiuResources.Types.PROP: PopochiuPropRow,
	PopochiuResources.Types.HOTSPOT: PopochiuHotspotRow,
	PopochiuResources.Types.REGION: PopochiuRegionRow,
	PopochiuResources.Types.MARKER: PopochiuMarkerRow,
	PopochiuResources.Types.WALKABLE_AREA: PopochiuWalkableAreaRow,
}
var _row_instances := {}

# Group that holds the characters present in the room, in the separate characters tree
var _characters_group: TreeItem

@onready var room_name: Button = %RoomName
@onready var no_room_info: Label = %NoRoomInfo
@onready var tool_buttons: HBoxContainer = %ToolButtons
@onready var btn_script: Button = %BtnScript
@onready var btn_resource: Button = %BtnResource
@onready var btn_resource_script: Button = %BtnResourceScript
@onready var characters_separator: HSeparator = %CharactersSeparator
@onready var characters_tree: Tree = %CharactersTree


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Create the row instances and their groups for each object type
	for type_key: int in _rows:
		var row: PopochiuDockRow = _rows[type_key].new(self)
		_row_instances[type_key] = row
		row.create_group()
		set_create_disabled(row.group, true)
	
	# Setup the separate tree that holds the characters present in the room
	_setup_characters_tree()
	
	# Connect to the base class signals
	item_clicked.connect(_on_item_clicked)
	button_clicked.connect(_on_item_button_clicked)
	menu_item_selected.connect(_on_menu_item_selected)
	create_clicked.connect(_on_create_clicked)
	
	# Connect the characters tree signals directly: it is handled locally, not via the base class
	characters_tree.item_selected.connect(_on_characters_item_selected)
	characters_tree.button_clicked.connect(_on_characters_button_clicked)
	
	# Setup the tool buttons
	room_name.icon = get_theme_icon("Load", "EditorIcons")
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
	characters_separator.show()
	characters_tree.show()
	no_room_info.hide()
	
	# Enable the create buttons and listen to node additions/deletions for the room objects
	for type_key: int in _rows:
		var row: PopochiuDockRow = _row_instances[type_key]
		set_create_disabled(row.group, false)
		
		var container: Node2D = opened_room.get_node(row.get_parent_name())
		container.child_entered_tree.connect(_on_child_added.bind(row))
		container.child_exiting_tree.connect(_on_child_removed.bind(row))
	
	# Enable the add-character button and listen to the Characters container for live updates
	set_button_disabled(_characters_group, PopochiuDockRow.Buttons.ADD_CHARACTER, false)
	var characters_container: Node2D = opened_room.get_node("Characters")
	characters_container.child_entered_tree.connect(_on_character_child_added)
	characters_container.child_exiting_tree.connect(_on_character_child_removed)
	
	# Fill info of Props, Hotspots, Walkable areas, Regions and Points
	for type_key: int in _rows:
		var row: PopochiuDockRow = _row_instances[type_key]
		for child in opened_room.call(row.get_method()):
			row.create_row(child)
	
	# Fill the characters present in the room
	for child in opened_room.get_characters():
		_create_character_row(child)
	
	get_parent().current_tab = 1


func scene_closed(filepath: String) -> void:
	if is_instance_valid(opened_room) and opened_room.scene_file_path == filepath:
		_clear_content()


#endregion

#region Virtual ####################################################################################
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


#endregion

#region Private ####################################################################################
func _set_no_room_state() -> void:
	room_name.hide()
	tool_buttons.hide()
	filter.hide()
	tree.hide()
	characters_separator.hide()
	characters_tree.hide()
	no_room_info.show()


func _clear_content() -> void:
	for type_key: int in _rows:
		var row: PopochiuDockRow = _row_instances[type_key]
		var container: Node2D = opened_room.get_node(row.get_parent_name())
		
		# Disconnect with the same bound callable used at connect time (fixes a latent mismatch
		# where the unbound callable never matched the bound connection)
		var on_added := _on_child_added.bind(row)
		if container.child_entered_tree.is_connected(on_added):
			container.child_entered_tree.disconnect(on_added)
		
		var on_removed := _on_child_removed.bind(row)
		if container.child_exiting_tree.is_connected(on_removed):
			container.child_exiting_tree.disconnect(on_removed)
	
	# Disconnect the Characters container signals
	var characters_container: Node2D = opened_room.get_node("Characters")
	if characters_container.child_entered_tree.is_connected(_on_character_child_added):
		characters_container.child_entered_tree.disconnect(_on_character_child_added)
	if characters_container.child_exiting_tree.is_connected(_on_character_child_removed):
		characters_container.child_exiting_tree.disconnect(_on_character_child_removed)
	
	if PopochiuEditorHelper.undo_redo.history_changed.is_connected(_check_undoredo_history):
		PopochiuEditorHelper.undo_redo.history_changed.disconnect(_check_undoredo_history)
	
	opened_room = null
	opened_room_state_path = ""
	
	characters_in_room.clear()
	rows_paths.clear()
	
	clear_items()
	_clear_characters_items()
	
	# Disable the create buttons and the add-character button
	for row: PopochiuDockRow in _row_instances.values():
		set_create_disabled(row.group, true)
	set_button_disabled(_characters_group, PopochiuDockRow.Buttons.ADD_CHARACTER, true)
	
	_set_no_room_state()
	await get_tree().process_frame


func _on_item_clicked(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	_row_instances[data.type].on_item_clicked(item)


func _on_item_button_clicked(item: TreeItem, id: int) -> void:
	var data := item.get_metadata(COL_TEXT)
	_row_instances[data.type].on_button_clicked(item, id)


func _on_menu_item_selected(item: TreeItem, id: int) -> void:
	var data := item.get_metadata(COL_TEXT)
	_row_instances[data.type].on_menu_item_selected(item, id)


func _on_create_clicked(group_item: TreeItem) -> void:
	var type_key: int = group_item.get_metadata(COL_TEXT).type
	PopochiuEditorHelper.show_creation_popup(_row_instances[type_key].get_popup())


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


# Sets up the separate tree that holds the characters present in the room. It is handled locally
# (not via the base class) because the characters list uses none of the base class's complex
# machinery (no context menu, no create button, no tags/dimming, no file deletion).
func _setup_characters_tree() -> void:
	characters_tree.columns = 3
	characters_tree.hide_root = true
	characters_tree.select_mode = Tree.SELECT_ROW
	characters_tree.allow_rmb_select = true
	characters_tree.set_column_expand(COL_TEXT, true)
	characters_tree.set_column_expand(COL_TAG, false)
	characters_tree.set_column_expand(COL_BUTTONS, false)
	characters_tree.set_column_custom_minimum_width(COL_TAG, 16)
	
	# Create the "Characters in room" group. It has no create button: characters are added to the
	# room through the "+ Add character" menu instead.
	var root := characters_tree.get_root()
	if not root:
		root = characters_tree.create_item()
	_characters_group = characters_tree.create_item(root)
	_characters_group.set_text(COL_TEXT, "Characters in room")
	_characters_group.set_icon(COL_TEXT, CHARACTER_ICON)
	_characters_group.set_metadata(COL_TEXT, {
		"title": "Characters in room",
		"can_create": false,
	})
	
	# Add the "Add character to room" button to the Characters group
	add_button(
		_characters_group, get_theme_icon("Instance", "EditorIcons"),
		PopochiuDockRow.Buttons.ADD_CHARACTER, "Add character to room"
	)
	set_button_disabled(_characters_group, PopochiuDockRow.Buttons.ADD_CHARACTER, true)


# Clears the character items but keeps the group (mirrors clear_items() for the main tree).
func _clear_characters_items() -> void:
	for child in _characters_group.get_children():
		child.free()
	update_group_count(_characters_group)


# Creates the row for a character present in the room in the characters tree.
func _create_character_row(child: Node) -> void:
	if not child is PopochiuCharacter: return
	
	# Get the script_name of the character
	var char_name: String = child.name.trim_prefix("Character").rstrip(" *")
	characters_in_room.append(char_name)
	
	# Create the item for the character
	var item := _create_character_item(
		char_name,
		"res://game/characters/%s/character_%s.tscn".replace("%s", char_name.to_snake_case()),
		child.name
	)
	item.get_metadata(COL_TEXT).no_menu = true
	
	# Create button to remove the character from the room
	add_button(
		item, get_theme_icon("Unlinked", "EditorIcons"), PopochiuDockRow.Buttons.REMOVE_CHARACTER,
		"Remove character from room"
	)


func _create_character_item(name: String, path: String, node_path: String) -> TreeItem:
	var data := {
		"type": PopochiuResources.Types.CHARACTER,
		"path": path,
		"node_path": node_path,
		"script_name": name,
	}
	var item := characters_tree.create_item(_characters_group)
	item.set_text(COL_TEXT, name)
	item.set_icon(COL_TEXT, CHARACTER_ICON)
	item.set_metadata(COL_TEXT, data)
	item.set_tooltip_text(COL_TEXT, path)
	update_group_count(_characters_group)
	rows_paths.append("%s/%d/%s" % [opened_room.script_name, PopochiuResources.Types.CHARACTER, name])
	return item


func _on_characters_item_selected() -> void:
	var item := characters_tree.get_selected()
	# Ignore the group item (direct child of the hidden root)
	if not item or item.get_parent() != characters_tree.get_root(): return
	
	var data := item.get_metadata(COL_TEXT)
	if is_instance_valid(opened_room):
		var node: Node = opened_room.get_node("Characters/%s" % data.node_path)
		PopochiuEditorHelper.select_node(node)


func _on_characters_button_clicked(
	item: TreeItem, column: int, id: int, mouse_button_index: int
) -> void:
	if column != COL_BUTTONS or mouse_button_index != MOUSE_BUTTON_LEFT: return
	
	match id:
		PopochiuDockRow.Buttons.ADD_CHARACTER:
			_open_add_character_menu()
		PopochiuDockRow.Buttons.REMOVE_CHARACTER:
			_remove_character_from_room(item)


func _on_character_child_added(node: Node) -> void:
	if not node is PopochiuCharacter: return
	
	_create_character_row(node)
	
	node.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0


func _on_character_child_removed(node: Node) -> void:
	if not node is PopochiuCharacter: return
	
	var node_name: String = node.name.trim_prefix("Character").rstrip(" *")
	characters_in_room.erase(node_name)
	
	var item := get_item(_characters_group, node_name)
	if item:
		remove_item(item)


func _remove_character_from_room(item: TreeItem) -> void:
	delete_dialog = PopochiuEditorHelper.DELETE_CONFIRMATION_SCENE.instantiate()
	delete_dialog.title = "Remove character in room"
	delete_dialog.message = (
		"Are you sure you want to remove [b]%s[/b] from this room?" % item.get_text(COL_TEXT)
	)
	delete_dialog.on_confirmed = _on_remove_character_confirmed.bind(item)
	
	PopochiuEditorHelper.show_delete_confirmation(delete_dialog)


func _on_remove_character_confirmed(item: TreeItem) -> void:
	var name: String = item.get_text(COL_TEXT)
	characters_in_room.erase(name)
	opened_room.get_node("Characters").get_node("Character%s *" % name).queue_free()
	remove_item(item)
	EditorInterface.save_scene()


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