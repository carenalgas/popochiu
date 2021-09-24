tool
extends VBoxContainer
# Controla la lógica de la pestaña Room en el dock Popochiu

enum Types { PROP = 4, HOTSPOT, REGION, POINT }

var opened_room: PopochiuRoom = null
var main_dock: Panel setget _set_main_dock
var object_row: PackedScene = null

var _rows_paths := []

onready var _types := {
	Types.PROP: {
		group = find_node('PropsGroup'),
		popup = 'CreateProp',
		method = 'get_props',
		type_class = Prop
	},
	Types.HOTSPOT: {
		group = find_node('HotspotsGroup'),
		popup = 'CreateHotspot',
		method = 'get_hotspots',
		type_class = Hotspot
	},
	Types.REGION: {
		group = find_node('RegionsGroup'),
		popup = 'CreateRegion',
		method = 'get_regions',
		type_class = Region
	},
	Types.POINT: {
		group = find_node('PointsGroup'),
		method = 'get_points',
		type_class = Position2D
	}
}
onready var _room_name: Label = find_node('RoomName')
onready var _no_room_info: Label = find_node('NoRoomInfo')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	# Por defecto deshabilitar los botones hasta que no se haya seleccionado
	# una habitación.
	_room_name.hide()
	_no_room_info.hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func scene_changed(scene_root: Node) -> void:
	if scene_root is PopochiuRoom:
		if is_instance_valid(opened_room) and\
		scene_root.name != opened_room.name:
			_rows_paths.clear()
			
			for t in _types.values():
				t.group.clear_list()
				t.group.disable_create()
			
			yield(get_tree(), 'idle_frame')
		
		# Actualizar la información de la habitación que se abrió
		opened_room = scene_root
		_room_name.text = opened_room.script_name
		
		_room_name.show()
		
		for t in _types:
			for c in opened_room.call(_types[t].method):
				var row_path: String = '%s/%d/%s' %\
				[opened_room.script_name, t, c.name]
				
				if row_path in _rows_paths: continue
				
				if c is _types[t].type_class:
					var row: PopochiuObjectRow = _create_object_row(t, c.name)
					_types[t].group.add(row)
			
			if _types[t].has('popup'):
				_types[t].popup.room_opened(opened_room)
			
			_types[t].group.enable_create()
		
		_no_room_info.hide()

		get_parent().current_tab = 1
	else:
		# Poner todo en su estado por defecto
		opened_room = null
		get_parent().current_tab = 0

		_room_name.hide()
		_no_room_info.show()


func add_to_list(type: int, node_name: String) -> void:
	_types[type].group.add(_create_object_row(type, node_name))


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _create_object_row(type: int, node_name: String) -> PopochiuObjectRow:
	var new_obj: PopochiuObjectRow = object_row.instance()

	new_obj.name = node_name
	new_obj.type = type
	new_obj.main_dock = main_dock
	
#	main_dock.ei.select_file(por.path)
	
	_rows_paths.append('%s/%d/%s' % [opened_room.script_name, type, node_name])
	
	return new_obj



func _set_main_dock(value: Panel) -> void:
	main_dock = value
	
	for t in _types.values():
		if not t.has('popup'): continue
		t.popup = main_dock.get_popup(t.popup)
		t.popup.set_main_dock(main_dock)
		t.popup.room_tab = self
		t.group.connect('create_clicked', main_dock, '_open_popup', [t.popup])
