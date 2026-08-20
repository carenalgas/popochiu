@tool
extends PopochiuTreeDock
# Handles the Room tab in Popochiu's dock. Uses a native [Tree] control to display the objects of
# the currently open room grouped by type.
#
# Ref: #558

enum Buttons {
	OPEN,
	SCRIPT,
	REMOVE_CHARACTER,
	ADD_CHARACTER,
}

enum MenuOptions {
	SEPARATOR = -1,
	DELETE,
}

var opened_room: PopochiuRoom = null
var opened_room_state_path: String = ""

var _rows_paths := []
var _characters_in_room := []
var _add_character_menu: PopupMenu

var _types := {
	PopochiuResources.Types.PROP: {
		group = null,
		popup = PopochiuEditorHelper.CREATE_PROP,
		method = "get_props",
		type_class = PopochiuProp,
		parent = "Props",
		icon = preload("res://addons/popochiu/icons/prop.png"),
		title = "Props",
		create_text = "Create prop",
	},
	PopochiuResources.Types.HOTSPOT: {
		group = null,
		popup = PopochiuEditorHelper.CREATE_HOTSPOT,
		method = "get_hotspots",
		type_class = PopochiuHotspot,
		parent = "Hotspots",
		icon = preload("res://addons/popochiu/icons/hotspot.png"),
		title = "Hotspots",
		create_text = "Create hotspot",
	},
	PopochiuResources.Types.REGION: {
		group = null,
		popup = PopochiuEditorHelper.CREATE_REGION,
		method = "get_regions",
		type_class = PopochiuRegion,
		parent = "Regions",
		icon = preload("res://addons/popochiu/icons/region.png"),
		title = "Regions",
		create_text = "Create regions",
	},
	PopochiuResources.Types.MARKER: {
		group = null,
		popup = PopochiuEditorHelper.CREATE_MARKER,
		method = "get_markers",
		type_class = Marker2D,
		parent = "Markers",
		icon = preload("res://addons/popochiu/icons/marker.png"),
		title = "Markers",
		create_text = "Create marker",
	},
	PopochiuResources.Types.WALKABLE_AREA: {
		group = null,
		popup = PopochiuEditorHelper.CREATE_WALKABLE_AREA,
		method = "get_walkable_areas",
		type_class = PopochiuWalkableArea,
		parent = "WalkableAreas",
		icon = preload("res://addons/popochiu/icons/walkable_area.png"),
		title = "Walkable areas",
		create_text = "Create walkable area",
	},
	PopochiuResources.Types.CHARACTER: {
		group = null,
		method = "get_characters",
		type_class = PopochiuCharacter,
		parent = "Characters",
		icon = preload("res://addons/popochiu/icons/character.png"),
		title = "Characters in room",
		create_text = "",
	},
}

@onready var room_name: Button = %RoomName
@onready var no_room_info: Label = %NoRoomInfo
@onready var tool_buttons: HBoxContainer = %ToolButtons
@onready var btn_script: Button = %BtnScript
@onready var btn_resource: Button = %BtnResource
@onready var btn_resource_script: Button = %BtnResourceScript


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Create the groups for each object type
	for type_key: int in _types:
		var t: Dictionary = _types[type_key]
		var can_create := t.has("popup")
		t.group = create_group(t.title, t.icon, can_create, t.create_text, { "type": type_key })
		set_create_disabled(t.group, true)
	
	# Add the "Add character to room" button to the Characters group
	var chars_group: TreeItem = _types[PopochiuResources.Types.CHARACTER].group
	add_button(
		chars_group, get_theme_icon("Load", "EditorIcons"), Buttons.ADD_CHARACTER,
		"Add character to room"
	)
	set_button_disabled(chars_group, Buttons.ADD_CHARACTER, true)
	
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
	for type_id in _types:
		set_create_disabled(_types[type_id].group, false)
		
		var container: Node2D = opened_room.get_node(_types[type_id].parent)
		container.child_entered_tree.connect(_on_child_added.bind(type_id))
		container.child_exiting_tree.connect(_on_child_removed.bind(type_id))
	set_button_disabled(
		_types[PopochiuResources.Types.CHARACTER].group, Buttons.ADD_CHARACTER, false
	)
	
	# Fill info of Props, Hotspots, Walkable areas, Regions and Points
	for type_id in _types:
		for child in opened_room.call(_types[type_id].method):
			_create_row_in_dock(type_id, child)
	
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
	for type_id in _types:
		var container: Node2D = opened_room.get_node(_types[type_id].parent)
		
		if container.child_entered_tree.is_connected(_on_child_added):
			container.child_entered_tree.disconnect(_on_child_added)
		
		if container.child_exiting_tree.is_connected(_on_child_removed):
			container.child_exiting_tree.disconnect(_on_child_removed)
	
	if PopochiuEditorHelper.undo_redo.history_changed.is_connected(_check_undoredo_history):
		PopochiuEditorHelper.undo_redo.history_changed.disconnect(_check_undoredo_history)
	
	opened_room = null
	opened_room_state_path = ""
	
	_characters_in_room.clear()
	_rows_paths.clear()
	
	clear_items()
	
	# Disable the create buttons and the add-character button
	for t: Dictionary in _types.values():
		set_create_disabled(t.group, true)
	set_button_disabled(
		_types[PopochiuResources.Types.CHARACTER].group, Buttons.ADD_CHARACTER, true
	)
	
	_set_no_room_state()
	await get_tree().process_frame


func _create_item(type: int, name: String, path: String, node_path: String) -> TreeItem:
	var group: TreeItem = _types[type].group
	var data := {
		"type": type,
		"path": path,
		"node_path": node_path,
		"script_name": name,
	}
	var item := add_item(group, name, _types[type].icon, data)
	_rows_paths.append("%s/%d/%s" % [opened_room.script_name, type, name])
	return item


func _on_item_clicked(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	if is_instance_valid(opened_room):
		var node := opened_room.get_node("%s/%s" % [_types[data.type].parent, data.node_path])
		PopochiuEditorHelper.select_node(node)


func _on_item_button_clicked(item: TreeItem, id: int) -> void:
	match id:
		Buttons.OPEN:
			_open(item)
		Buttons.SCRIPT:
			_open_script(item)
		Buttons.REMOVE_CHARACTER:
			_on_remove_character_pressed(item)


func _on_group_button_clicked(group_item: TreeItem, id: int) -> void:
	match id:
		Buttons.ADD_CHARACTER:
			_open_add_character_menu()


func _on_menu_item_selected(item: TreeItem, id: int) -> void:
	match id:
		MenuOptions.DELETE:
			_remove_object(item)


func _on_create_clicked(group_item: TreeItem) -> void:
	var type_key: int = group_item.get_metadata(COL_TEXT).type
	PopochiuEditorHelper.show_creation_popup(_types[type_key].popup)


func _get_menu_cfg(item: TreeItem) -> Array:
	return [
		{
			id = MenuOptions.DELETE,
			icon = get_theme_icon("Remove", "EditorIcons"),
			label = "Remove",
		}
	]


func _get_location(path: String) -> String:
	# Structure of path: "res://game/rooms/room_name/props/prop_name/"
	# path split: [res:, popochiu, rooms, room_name, props, prop_name]
	return "Room%s" % (path.split("/", false)[3]).to_pascal_case()


func _remove_from_core(item: TreeItem, should_save_and_delete := true) -> void:
	var data := item.get_metadata(COL_TEXT)
	var type: int = data.type
	var path: String = data.path
	var name: String = item.get_text(COL_TEXT)
	
	var room_child_to_free: Node = null
	if EditorInterface.get_edited_scene_root() is PopochiuRoom:
		var opened_room: PopochiuRoom = EditorInterface.get_edited_scene_root()
		match type:
			PopochiuResources.Types.PROP:
				room_child_to_free = opened_room.get_prop(name)
			PopochiuResources.Types.HOTSPOT:
				room_child_to_free = opened_room.get_hotspot(name)
			PopochiuResources.Types.MARKER:
				room_child_to_free = opened_room.get_marker(name)
			PopochiuResources.Types.REGION:
				room_child_to_free = opened_room.get_region(name)
			PopochiuResources.Types.WALKABLE_AREA:
				room_child_to_free = opened_room.get_walkable_area(name)
	
	# Check if the files should be deleted in the file system
	if _delete_dialog.check_box.button_pressed:
		_delete_from_file_system(path)
	
	# Fix #196: Remove the Node from the Room tree once the folder of the object has been deleted
	# from the FileSystem (this applies to Props, Hotspots, Walkable areas and Regions).
	if room_child_to_free:
		room_child_to_free.queue_free()
	
	EditorInterface.save_scene()


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


# Removes the character from the room
func _on_remove_character_pressed(item: TreeItem) -> void:
	_delete_dialog = PopochiuEditorHelper.DELETE_CONFIRMATION_SCENE.instantiate()
	_delete_dialog.title = "Remove character in room"
	_delete_dialog.message = "Are you sure you want to remove [b]%s[/b] from this room?" % item.get_text(COL_TEXT)
	_delete_dialog.on_confirmed = _on_remove_character_confirmed.bind(item)
	
	PopochiuEditorHelper.show_delete_confirmation(_delete_dialog)


func _on_remove_character_confirmed(item: TreeItem) -> void:
	var name: String = item.get_text(COL_TEXT)
	_characters_in_room.erase(name)
	opened_room.get_node("Characters").get_node("Character%s *" % name).queue_free()
	remove_item(item)
	EditorInterface.save_scene()


# Fills the list to show after pressing "+ Add character to room" and listens to selections to add
# the clicked character to the room
func _open_add_character_menu() -> void:
	_add_character_menu.clear()
	
	var idx := 0
	for key in PopochiuResources.get_section_keys("characters"):
		_add_character_menu.add_item(key, idx)
		_add_character_menu.set_item_disabled(idx, _characters_in_room.has(key))
		
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


## Called when a [param child] is added to the room's tree without using the Popochiu dock.
## [param type_id] can be used to classify the object (prop, hotspot, etc.).
func _create_row_in_dock(type_id: int, child: Node) -> TreeItem:
	var item: TreeItem = null
	
	if child is PopochiuCharacter:
		# Get the script_name of the character
		var char_name: String = child.name.trim_prefix("Character").rstrip(" *")
		_characters_in_room.append(char_name)
		
		# Create the item for the character
		item = _create_item(
			type_id,
			char_name,
			"res://game/characters/%s/character_%s.tscn".replace("%s", char_name.to_snake_case()),
			child.name
		)
		item.get_metadata(COL_TEXT).no_menu = true
		
		# Create button to remove the character from the room
		add_button(
			item, get_theme_icon("Unlinked", "EditorIcons"), Buttons.REMOVE_CHARACTER,
			"Remove character from room"
		)
	elif is_instance_of(child, _types[type_id].type_class):
		var row_path := _get_row_path(type_id, child)
		if row_path in _rows_paths: return null
		
		var node_path := _get_node_path(type_id, child)
		item = _create_item(type_id, child.name, row_path, node_path)
		
		# Add the action buttons
		add_button(item, get_theme_icon("InstanceOptions", "EditorIcons"), Buttons.OPEN, "Open in Editor")
		if FileAccess.file_exists(row_path.replace(".tscn", ".gd")):
			add_button(item, get_theme_icon("Script", "EditorIcons"), Buttons.SCRIPT, "Open in Script")
		add_menu_button(item)
	
	return item


func _get_row_path(type_id: int, child: Node) -> String:
	var row_path := child.scene_file_path
	
	if row_path.is_empty() and child.script and not "addons" in child.script.resource_path:
		row_path = child.script.resource_path
	
	return row_path


func _get_node_path(type_id: int, child: Node) -> String:
	return String(child.get_path()).split("%s/" % _types[type_id].parent)[1]


func _on_child_added(node: Node, type_id: int) -> void:
	_create_row_in_dock(type_id, node)
	
	if not is_instance_of(node, _types[type_id].type_class): return
	
	node.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0


func _on_child_removed(node: Node, type_id: int) -> void:
	if not is_instance_of(node, _types[type_id].type_class): return
	
	var node_name := node.name
	
	if node is PopochiuCharacter:
		# Get the script_name of the character
		node_name = node_name.lstrip("Character").rstrip(" *")
		_characters_in_room.erase(str(node_name))
	else:
		_rows_paths.erase("%s/%d/%s" % [opened_room.script_name, type_id, node_name])
	
	var item := get_item(_types[type_id].group, node_name)
	if item:
		remove_item(item)


func _check_undoredo_history() -> void:
	if not opened_room or not is_instance_valid(opened_room):
		return
	
	var walkable_areas: Array = opened_room.call(
		_types[PopochiuResources.Types.WALKABLE_AREA].method
	)
	
	if walkable_areas.is_empty(): return
	
	for wa: PopochiuWalkableArea in walkable_areas:
		(wa.get_node("Perimeter") as NavigationRegion2D).bake_navigation_polygon()


#endregion