@tool
extends VBoxContainer
## Handles the Room tab in Popochiu's dock

const OBJECT_ROW_FOLDER = "res://addons/popochiu/editor/main_dock/popochiu_row/object_row/"
const POPOCHIU_OBJECT_ROW_SCENE = preload(OBJECT_ROW_FOLDER + "popochiu_object_row.tscn")
const PopochiuRoomObjectRow = preload(
	"res://addons/popochiu/editor/main_dock/popochiu_row/object_row/" +
	"room_object_row/popochiu_room_object_row.gd"
)

var opened_room: PopochiuRoom = null
var opened_room_state_path: String = ""

var _rows_paths := []
var _last_selected: PopochiuRoomObjectRow = null
var _characters_in_room := []
var _btn_add_character: MenuButton
var _delete_dialog: PopochiuEditorHelper.DeleteConfirmation

@onready var _types: Dictionary = {
	PopochiuResources.Types.PROP: {
		group = %PropsGroup as PopochiuGroup,
		popup = PopochiuEditorHelper.CREATE_PROP,
		method = "get_props",
		type_class = PopochiuProp,
		parent = "Props"
	},
	PopochiuResources.Types.HOTSPOT: {
		group = %HotspotsGroup as PopochiuGroup,
		popup = PopochiuEditorHelper.CREATE_HOTSPOT,
		method = "get_hotspots",
		type_class = PopochiuHotspot,
		parent = "Hotspots"
	},
	PopochiuResources.Types.REGION: {
		group = %RegionsGroup as PopochiuGroup,
		popup = PopochiuEditorHelper.CREATE_REGION,
		method = "get_regions",
		type_class = PopochiuRegion,
		parent = "Regions"
	},
	PopochiuResources.Types.MARKER: {
		group = %MarkersGroup as PopochiuGroup,
		popup = PopochiuEditorHelper.CREATE_MARKER,
		method = "get_markers",
		type_class = Marker2D,
		parent = "Markers"
	},
	PopochiuResources.Types.WALKABLE_AREA: {
		group = %WalkableAreasGroup as PopochiuGroup,
		popup = PopochiuEditorHelper.CREATE_WALKABLE_AREA,
		method = "get_walkable_areas",
		type_class = PopochiuWalkableArea,
		parent = "WalkableAreas"
	},
	PopochiuResources.Types.CHARACTER: {
		group = %CharactersGroup as PopochiuGroup,
		method = "get_characters",
		type_class = PopochiuCharacter,
		parent = "Characters"
	}
}
@onready var popochiu_filter: LineEdit = %PopochiuFilter
@onready var room_name: Button = %RoomName
@onready var no_room_info: Label = %NoRoomInfo
@onready var tool_buttons: HBoxContainer = %ToolButtons
@onready var btn_script: Button = %BtnScript
@onready var btn_resource: Button = %BtnResource
@onready var btn_resource_script: Button = %BtnResourceScript


#region Godot ######################################################################################
func _ready() -> void:
	popochiu_filter.groups = _types
	
	# Setup the button that will allow to add characters to the room
	_btn_add_character = MenuButton.new()
	_btn_add_character.text = "Add character to room"
	_btn_add_character.icon = get_theme_icon("Add", "EditorIcons")
	_btn_add_character.flat = false
	_btn_add_character.size_flags_horizontal = SIZE_SHRINK_END
	
	_btn_add_character.add_theme_stylebox_override("normal", get_theme_stylebox("normal", "Button"))
	_btn_add_character.add_theme_stylebox_override("hover", get_theme_stylebox("hover", "Button"))
	_btn_add_character.add_theme_stylebox_override(
		"pressed", get_theme_stylebox("pressed", "Button")
	)
	
	_btn_add_character.about_to_popup.connect(_on_add_character_pressed)

	_types[PopochiuResources.Types.CHARACTER].group.add_header_button(_btn_add_character)
	
	# Disable all buttons by default until a PopochiuRoom is opened in the editor
	room_name.hide()
	popochiu_filter.hide()
	no_room_info.show()
	tool_buttons.hide()
	
	btn_script.icon = get_theme_icon("Script", "EditorIcons")
	btn_resource.icon = get_theme_icon("Object", "EditorIcons")
	btn_resource_script.icon = get_theme_icon("GDScript", "EditorIcons")
	
	room_name.pressed.connect(_select_file)
	btn_script.pressed.connect(_open_script)
	btn_resource.pressed.connect(_edit_resource)
	btn_resource_script.pressed.connect(_open_resource_script)
	
	for t in _types.values():
		t.group.disable_create()
		
		if t.has("popup"):
			t.group.create_clicked.connect(PopochiuEditorHelper.show_creation_popup.bind(t.popup))


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
	popochiu_filter.show()
	_btn_add_character.disabled = false
	
	# Fill info of Props, Hotspots, Walkable areas, Regions and Points
	for type_id in _types:
		for child in opened_room.call(_types[type_id].method):
			_create_row_in_dock(type_id, child)
		
		_types[type_id].group.enable_create()
		
		# Listen to node additions/deletions in container nodes
		var container: Node2D = opened_room.get_node(_types[type_id].parent)
		
		container.child_entered_tree.connect(_on_child_added.bind(type_id))
		container.child_exiting_tree.connect(_on_child_removed.bind(type_id))
	
	no_room_info.hide()
	get_parent().current_tab = 1


func scene_closed(filepath: String) -> void:
	if is_instance_valid(opened_room) and opened_room.scene_file_path == filepath:
		_clear_content()


#endregion

#region Private ####################################################################################
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
	room_name.hide()
	tool_buttons.hide()
	popochiu_filter.hide()
	no_room_info.show()
	
	if is_instance_valid(_last_selected):
		_last_selected.deselect()
		_last_selected = null
	
	for t: Dictionary in _types.values():
		t.group.clear_list()
		t.group.disable_create()
	
	_btn_add_character.disabled = true
	await get_tree().process_frame


func _create_object_row(
	type: int, node_name: String, path := "", node_path := ""
) -> PopochiuRoomObjectRow:
	var object_row_instance := POPOCHIU_OBJECT_ROW_SCENE.instantiate()
	object_row_instance.set_script(PopochiuRoomObjectRow)
	var new_obj: PopochiuRoomObjectRow = object_row_instance
	
	new_obj.name = node_name
	new_obj.type = type
	new_obj.path = path
	new_obj.node_path = node_path
	new_obj.clicked.connect(_select_in_tree)
	
	_rows_paths.append("%s/%d/%s" % [opened_room.script_name, type, node_name])
	
	return new_obj


func _select_in_tree(por: PopochiuRoomObjectRow) -> void:
	if _last_selected and _last_selected != por:
		_last_selected.deselect()
	
	if is_instance_valid(opened_room):
		var node := opened_room.get_node("%s/%s" % [_types[por.type].parent, por.node_path])
		PopochiuEditorHelper.select_node(node)
	
	_last_selected = por


func _select_file() -> void:
	EditorInterface.select_file(opened_room.scene_file_path)


func _open_script() -> void:
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
func _on_remove_character_pressed(row: PopochiuRoomObjectRow) -> void:
	_delete_dialog = PopochiuEditorHelper.DELETE_CONFIRMATION_SCENE.instantiate()
	_delete_dialog.title = "Remove character in room"
	_delete_dialog.message = "Are you sure you want to remove [b]%s[/b] from this room?" % row.name
	_delete_dialog.on_confirmed = _on_remove_character_confirmed.bind(row)
	
	PopochiuEditorHelper.show_delete_confirmation(_delete_dialog)


func _on_remove_character_confirmed(row: PopochiuRoomObjectRow) -> void:
	_characters_in_room.erase(str(row.name))
	opened_room.get_node("Characters").get_node("Character%s *" % row.name).queue_free()
	row.queue_free()
	EditorInterface.save_scene()


# Fills the list to show after pressing "+ Add character to room" and listens to selections to add
# the clicked character to the room
func _on_add_character_pressed() -> void:
	var characters_menu := _btn_add_character.get_popup()
	characters_menu.clear()
	
	var idx := 0
	for key in PopochiuResources.get_section_keys("characters"):
		characters_menu.add_item(key, idx)
		characters_menu.set_item_disabled(idx, _characters_in_room.has(key))
		
		idx += 1
	
	if not characters_menu.id_pressed.is_connected(_on_character_selected):
		characters_menu.id_pressed.connect(_on_character_selected)


# Adds the clicked character in the "+ Add character to room" menu to the
# current room
func _on_character_selected(id: int) -> void:
	var characters_menu := _btn_add_character.get_popup()
	var char_name := characters_menu.get_item_text(
		characters_menu.get_item_index(id)
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
func _create_row_in_dock(type_id: int, child: Node) -> PopochiuRoomObjectRow:
	var row: PopochiuRoomObjectRow = null
	
	if child is PopochiuCharacter:
		# Get the script_name of the character
		var char_name: String = child.name.trim_prefix("Character").rstrip(" *")
		_characters_in_room.append(char_name)
		
		# Create the row for the character
		row = _create_object_row(
			type_id,
			char_name,
			"res://game/characters/%s/character_%s.tscn".replace("%s", char_name.to_snake_case()),
			child.name
		)
		row.is_menu_hidden = true
		_types[type_id].group.add(row)
		
		# Create button to remove the character from the room
		var remove_btn := Button.new()
		remove_btn.icon = get_theme_icon("Remove", "EditorIcons")
		remove_btn.tooltip_text = "Remove character from room"
		remove_btn.flat = true
		
		remove_btn.pressed.connect(_on_remove_character_pressed.bind(row))
		row.add_button(remove_btn)
	elif is_instance_of(child, _types[type_id].type_class):
		var row_path := _get_row_path(type_id, child)
		if row_path in _rows_paths: return
		
		var node_path := _get_node_path(type_id, child)
		row = _create_object_row(type_id, child.name, row_path, node_path)
		_types[type_id].group.add(row)
	
	return row


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
	
	_types[type_id].group.remove_by_name(node_name)


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
