@tool
extends VBoxContainer
# Handles the Room tab in Popochiu's dock
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

const PopochiuObjectRow := preload('object_row/popochiu_object_row.gd')
const Constants := preload('res://addons/popochiu/popochiu_resources.gd')

var opened_room: PopochiuRoom = null
var main_dock: Panel : set = set_main_dock
var object_row: PackedScene = null
var opened_room_state_path: String = ''

var _rows_paths := []
var _last_selected: PopochiuObjectRow = null
var _characters_in_room := []
var _btn_add_character: MenuButton
var _remove_dialog: ConfirmationDialog

@onready var _types: Dictionary = {
	Constants.Types.PROP: {
		group = find_child('PropsGroup') as PopochiuGroup,
		popup = 'CreateProp',
		method = 'get_props',
		type_class = PopochiuProp,
		parent = 'Props'
	},
	Constants.Types.HOTSPOT: {
		group = find_child('HotspotsGroup') as PopochiuGroup,
		popup = 'CreateHotspot',
		method = 'get_hotspots',
		type_class = PopochiuHotspot,
		parent = 'Hotspots'
	},
	Constants.Types.REGION: {
		group = find_child('RegionsGroup') as PopochiuGroup,
		popup = 'CreateRegion',
		method = 'get_regions',
		type_class = PopochiuRegion,
		parent = 'Regions'
	},
	Constants.Types.MARKER: {
		group = find_child('MarkersGroup') as PopochiuGroup,
		method = 'get_markers',
		type_class = Marker2D,
		parent = 'Markers'
	},
	Constants.Types.WALKABLE_AREA: {
		group = find_child('WalkableAreasGroup') as PopochiuGroup,
		popup = 'CreateWalkableArea',
		method = 'get_walkable_areas',
		type_class = PopochiuWalkableArea,
		parent = 'WalkableAreas'
	},
	Constants.Types.CHARACTER: {
		group = find_child('CharactersGroup') as PopochiuGroup,
		method = 'get_characters',
		type_class = PopochiuCharacter,
		parent = 'Characters'
	}
}
@onready var _room_name: Button = find_child('RoomName')
@onready var _no_room_info: Label = find_child('NoRoomInfo')
@onready var _tool_buttons: HBoxContainer = find_child('ToolButtons')
@onready var _btn_script: Button = _tool_buttons.get_node('BtnScript')
@onready var _btn_resource: Button = _tool_buttons.get_node('BtnResource')
@onready var _btn_resource_script: Button = _tool_buttons.get_node('BtnResourceScript')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	$PopochiuFilter.groups = _types
	
	# Setup the button that will allow to add characters to the room
	_btn_add_character = MenuButton.new()
	_btn_add_character.text = 'Add character to room'
	_btn_add_character.icon = get_theme_icon('Add', 'EditorIcons')
	_btn_add_character.flat = false
	_btn_add_character.size_flags_horizontal = SIZE_SHRINK_END
	
	_btn_add_character.add_theme_stylebox_override(
		'normal', get_theme_stylebox("normal", "Button")
	)
	_btn_add_character.add_theme_stylebox_override(
		'hover', get_theme_stylebox("hover", "Button")
	)
	_btn_add_character.add_theme_stylebox_override(
		'pressed', get_theme_stylebox("pressed", "Button")
	)
	
	_btn_add_character.about_to_popup.connect(_on_add_character_pressed)

	_types[Constants.Types.CHARACTER].group.add_header_button(_btn_add_character)
	
	# Disable all buttons by default until a PopochiuRoom is opened in the editor
	_room_name.hide()
	$PopochiuFilter.hide()
	_no_room_info.show()
	_tool_buttons.hide()
	
	_btn_script.icon = get_theme_icon('Script', 'EditorIcons')
	_btn_resource.icon = get_theme_icon('Object', 'EditorIcons')
	_btn_resource_script.icon = get_theme_icon('GDScript', 'EditorIcons')
	
	_room_name.pressed.connect(_select_file)
	_btn_script.pressed.connect(_open_script)
	_btn_resource.pressed.connect(_edit_resource)
	_btn_resource_script.pressed.connect(_open_resource_script)
	
	for t in _types.values():
		t.group.disable_create()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func scene_changed(scene_root: Node) -> void:
	# Set the default tab state
	if is_instance_valid(opened_room):
		await _clear_content()
	
	if scene_root is PopochiuRoom and scene_root.script_name.is_empty():
		PopochiuUtils.print_error(
			"This room doesn't have a [code]script_name[/code] value!"
		)
		
		return
	
	if not scene_root is PopochiuRoom:
		get_parent().current_tab = 0
		return
	
	# Updated the opened room's info
	opened_room = scene_root
	opened_room_state_path = PopochiuResources.get_data_value(
		'rooms', opened_room.script_name, null
	)
	
	_room_name.text = opened_room.script_name
	
	_room_name.show()
	_tool_buttons.show()
	$PopochiuFilter.show()
	
	# Fill info of Props, Hotspots, Walkable areas, Regions and Points
	for type_id in _types:
		for child in opened_room.call(_types[type_id].method):
			_create_row_in_dock(type_id, child)
		
		if _types[type_id].has('popup'):
			_types[type_id].popup.room_opened(opened_room)
		
		_types[type_id].group.enable_create()
		
		# Listen to node additions/deletions in container nodes
		var container: Node2D = opened_room.get_node(_types[type_id].parent)
		
		container.child_entered_tree.connect(_on_child_added.bind(type_id))
		container.child_exiting_tree.connect(_on_child_removed.bind(type_id))
	
	_no_room_info.hide()
	get_parent().current_tab = 1


func scene_closed(filepath: String) -> void:
	if is_instance_valid(opened_room) and opened_room.scene_file_path == filepath:
		_clear_content()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_main_dock(value: Panel) -> void:
	main_dock = value
	_remove_dialog = main_dock.delete_dialog
	
	for t in _types.values():
		if not t.has('popup'): continue
		
		t.popup = main_dock.get_popup(t.popup)
		t.popup.set_main_dock(main_dock)
		t.popup.room_tab = self
		
		t.group.create_clicked.connect(main_dock._open_popup.bind(t.popup))


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _clear_content() -> void:
	for type_id in _types:
		var container: Node2D = opened_room.get_node(_types[type_id].parent)
		
		if container.child_entered_tree.is_connected(_on_child_added):
			container.child_entered_tree.disconnect(_on_child_added)
		
		if container.child_exiting_tree.is_connected(_on_child_removed):
			container.child_exiting_tree.disconnect(_on_child_removed)
	
	opened_room = null
	opened_room_state_path = ''
	
	_characters_in_room.clear()
	_rows_paths.clear()
	_room_name.hide()
	_tool_buttons.hide()
	$PopochiuFilter.hide()
	_no_room_info.show()
	
	if is_instance_valid(_last_selected):
		_last_selected.deselect()
		_last_selected = null
	
	for t in _types.values():
		t.group.clear_list()
		t.group.disable_create()
	
	await get_tree().process_frame


func _create_object_row(
	type: int, node_name: String, path := '', node_path := ''
) -> PopochiuObjectRow:
	var new_obj: PopochiuObjectRow = object_row.instantiate()
	
	new_obj.name = node_name
	new_obj.type = type
	new_obj.path = path # This will be useful for deleting objects with interaction
	new_obj.main_dock = main_dock
	new_obj.node_path = node_path
	new_obj.clicked.connect(_select_in_tree)
	
	_rows_paths.append('%s/%d/%s' % [opened_room.script_name, type, node_name])
	
	return new_obj


func _select_in_tree(por: PopochiuObjectRow) -> void:
	if _last_selected and _last_selected != por:
		_last_selected.deselect()
	
	if is_instance_valid(opened_room):
		var node := opened_room.get_node('%s/%s'\
		% [_types[por.type].parent, por.node_path])
		
		PopochiuUtils.select_node(node)
	
	_last_selected = por


func _select_file() -> void:
	main_dock.ei.select_file(opened_room.scene_file_path)


func _open_script() -> void:
	main_dock.ei.select_file(opened_room.get_script().resource_path)
	main_dock.ei.set_main_screen_editor('Script')
	main_dock.ei.edit_script(opened_room.get_script())


func _edit_resource() -> void:
	main_dock.ei.select_file(opened_room_state_path)
	main_dock.ei.edit_resource(load(opened_room_state_path))


func _open_resource_script() -> void:
	var prd: PopochiuRoomData = load(opened_room_state_path)
	main_dock.ei.select_file(prd.get_script().resource_path)
	main_dock.ei.set_main_screen_editor('Script')
	main_dock.ei.edit_resource(prd.get_script())


# Removes the character from the room
func _on_remove_character_pressed(row: PopochiuObjectRow) -> void:
	main_dock.show_confirmation(
		'Remove character in room',
		'Are you sure you want to remove [b]%s[/b] from this room?' % row.name,
		'',
		Vector2(200, 120)
	)
	
	_remove_dialog.confirmed.connect(
		_on_remove_character_confirmed.bind(row)
	)
	_remove_dialog.canceled.connect(_on_remove_dialog_hide)


func _on_remove_dialog_hide() -> void:
	_remove_dialog.call_deferred(
		'disconnect',
		'confirmed', _on_remove_character_confirmed
	)
	_remove_dialog.call_deferred(
		'disconnect',
		'canceled', _on_remove_dialog_hide
	)


func _on_remove_character_confirmed(row: PopochiuObjectRow) -> void:
	_characters_in_room.erase(str(row.name))
	opened_room.get_node('Characters').get_node(
		'Character%s *' % row.name
	).queue_free()
	row.queue_free()
	main_dock.ei.save_scene()
	
	_on_remove_dialog_hide()


# Fills the list to show after pressing "+ Add character to room" and listens
# to selections to add the clicked character to the room
func _on_add_character_pressed() -> void:
	var characters_menu := _btn_add_character.get_popup()
	characters_menu.clear()
	
	var idx := 0
	for key in PopochiuResources.get_section_keys('characters'):
		characters_menu.add_item(key, idx)
		characters_menu.set_item_disabled(idx, _characters_in_room.has(key))
		
		idx += 1
	
	if not characters_menu.id_pressed.is_connected(_on_character_seleced):
		characters_menu.id_pressed.connect(_on_character_seleced)


# Adds the clicked character in the "+ Add character to room" menu to the
# current room
func _on_character_seleced(id: int) -> void:
	var characters_menu := _btn_add_character.get_popup()
	var char_name := characters_menu.get_item_text(
		characters_menu.get_item_index(id)
	)
	var instance: PopochiuCharacter = load(
		'res://popochiu/characters/%s/character_%s.tscn' % [
			char_name.to_snake_case(),
			char_name.to_snake_case()
		]
	).instantiate()
	
	opened_room.get_node('Characters').add_child(instance)
	instance.owner = opened_room
	
	main_dock.ei.save_scene()
	PopochiuUtils.select_node(instance)


func _create_row_in_dock(type_id: int, child: Node) -> PopochiuObjectRow:
	var row: PopochiuObjectRow = null
	
	if child is Marker2D:
		row = _create_object_row(type_id, child.name)
		_types[type_id].group.add(row)
	elif child is PopochiuCharacter:
		# Get the script_name of the character
		var char_name: String =\
		child.name.lstrip('Character').rstrip(' *')
		_characters_in_room.append(char_name)

		# Create the row for the character
		row = _create_object_row(
			type_id,
			char_name,
			'res://popochiu/characters/%s/character_%s.tscn' % [
				char_name, char_name
			],
			child.name
		)
		row.is_menu_hidden = true

		_types[type_id].group.add(row)

		# Create button to remove the character from the room
		var remove_btn := Button.new()
		remove_btn.icon = get_theme_icon("Remove", "EditorIcons")
		remove_btn.tooltip_text = 'Remove character from room'
		remove_btn.flat = true
		
		remove_btn.pressed.connect(
			_on_remove_character_pressed.bind(row)
		)

		row.add_button(remove_btn)
	elif is_instance_of(child, _types[type_id].type_class):
		var row_path := _get_row_path(type_id, child)
	
		if row_path in _rows_paths: return
	
		var node_path := _get_node_path(type_id, child)
		
		row = _create_object_row(
			type_id, child.name, row_path, node_path
		)
		
		_types[type_id].group.add(row)
	
	return row


func _get_row_path(type_id: int, child: Node) -> String:
	var row_path := ""
	
	if type_id == Constants.Types.PROP:
		row_path = '%s/props/%s/prop_%s.tscn' % [
			opened_room.scene_file_path.get_base_dir(),
			(child.name as String).to_snake_case(),
			(child.name as String).to_snake_case()
		]
	elif child.script.resource_path.find('addons') == -1:
		row_path = child.script.resource_path
	else:
		row_path = '%s/%s' % [
			opened_room.scene_file_path.get_base_dir(),
			(_types[type_id].parent as String).to_snake_case()
		]
	
	return row_path


func _get_node_path(type_id: int, child: Node) -> String:
	return String(child.get_path()).split(
		'%s/' % _types[type_id].parent
	)[1]


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
		node_name = node_name.lstrip('Character').rstrip(' *')
		_characters_in_room.erase(str(node_name))
	else:
		_rows_paths.erase('%s/%d/%s' % [
			opened_room.script_name, type_id, node_name
		])
	
	_types[type_id].group.remove_by_name(node_name)
