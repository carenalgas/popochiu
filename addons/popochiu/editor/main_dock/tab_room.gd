@tool
extends VBoxContainer
# Handles the Room tab in Popochiu's dock
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

const PopochiuObjectRow := preload('object_row/popochiu_object_row.gd')
const Constants := preload('res://addons/popochiu/popochiu_resources.gd')

var opened_room: PopochiuRoom = null
var main_dock: Panel : set = _set_main_dock
var object_row: PackedScene = null
var opened_room_state_path: String = ''

var _rows_paths := []
var _last_selected: PopochiuObjectRow = null

@onready var _types: Dictionary = {
	Constants.Types.PROP: {
		group = find_child('PropsGroup'),
		popup = 'CreateProp',
		method = 'get_props',
		type_class = PopochiuProp,
		parent = 'Props'
	},
	Constants.Types.HOTSPOT: {
		group = find_child('HotspotsGroup'),
		popup = 'CreateHotspot',
		method = 'get_hotspots',
		type_class = PopochiuHotspot,
		parent = 'Hotspots'
	},
	Constants.Types.REGION: {
		group = find_child('RegionsGroup'),
		popup = 'CreateRegion',
		method = 'get_regions',
		type_class = PopochiuRegion,
		parent = 'Regions'
	},
	Constants.Types.POINT: {
		group = find_child('MarkersGroup'),
		method = 'get_markers',
		type_class = Marker2D,
		parent = 'Markers'
	},
	Constants.Types.WALKABLE_AREA: {
		group = find_child('WalkableAreasGroup'),
		popup = 'CreateWalkableArea',
		method = 'get_walkable_areas',
		type_class = PopochiuWalkableArea,
		parent = 'WalkableAreas'
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
	# Disable all buttons by default until a PopochiuRoom is opened in the editor
	_room_name.hide()
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
	
	if scene_root is PopochiuRoom and not scene_root.script_name.is_empty():
		# Updated the opened room's info
		opened_room = scene_root
		opened_room_state_path = PopochiuResources.get_data_value(
			'rooms', opened_room.script_name, null
		)
		
		_room_name.text = opened_room.script_name
		
		_room_name.show()
		_tool_buttons.show()
		
		for t in _types:
			for c in opened_room.call(_types[t].method):
				var row_path := ''
				
				if c is Marker2D:
					var row: PopochiuObjectRow = _create_object_row(t, c.name)
					_types[t].group.add(row)
					continue
				
				if t == Constants.Types.PROP:
					row_path = '%s/props/%s/prop_%s.tscn' % [
						opened_room.scene_file_path.get_base_dir(),
						PopochiuUtils.pascal2snake(c.name),
						PopochiuUtils.pascal2snake(c.name)
					]
				elif c.script.resource_path.find('addons') == -1:
					row_path = c.script.resource_path
				else:
					row_path = '%s/%s' % [
						opened_room.scene_file_path.get_base_dir(),
						PopochiuUtils.pascal2snake(_types[t].parent)
					]
				
				var node_path: String = String(c.get_path()).split(
					'%s/' % _types[t].parent
				)[1]
				
				if row_path in _rows_paths: continue
				
				if is_instance_of(c, _types[t].type_class):
					var row: PopochiuObjectRow = _create_object_row(
						t, c.name, row_path, node_path
					)
					_types[t].group.add(row)
			
			if _types[t].has('popup'):
				_types[t].popup.room_opened(opened_room)
			
			_types[t].group.enable_create()
		
		_no_room_info.hide()

		get_parent().current_tab = 1
	else:
		get_parent().current_tab = 0


func scene_closed(filepath: String) -> void:
	if is_instance_valid(opened_room) and opened_room.scene_file_path == filepath:
		_clear_content()


func add_to_list(type: int, node_name: String, path := '') -> void:
	_types[type].group.add(_create_object_row(type, node_name, path))


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func _set_main_dock(value: Panel) -> void:
	main_dock = value
	
	for t in _types.values():
		if not t.has('popup'): continue
		t.popup = main_dock.get_popup(t.popup)
		t.popup.set_main_dock(main_dock)
		t.popup.room_tab = self
		t.group.create_clicked.connect(main_dock._open_popup.bind(t.popup))


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _clear_content() -> void:
	opened_room = null
	opened_room_state_path = ''
	
	_rows_paths.clear()
	_room_name.hide()
	_tool_buttons.hide()
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
		main_dock.ei.edit_node(node)
	
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
