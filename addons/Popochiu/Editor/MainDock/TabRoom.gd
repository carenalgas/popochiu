tool
extends VBoxContainer
# Controla la lógica de la pestaña Room en el dock Popochiu

var opened_room: PopochiuRoom = null
var main_dock: Panel setget _set_main_dock

onready var _types := {
	prop = {
		group = find_node('PropsGroup'),
		popup = 'CreateProp'
	},
	hotspot = {
		group = find_node('HotspotsGroup'),
		popup = 'CreateHotspot'
	},
	region = {
		group = find_node('RegionsGroup'),
		popup = 'CreateRegion'
	},
	point = {
		group = find_node('PointsGroup')
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
	# Poner todo en su estado por defecto
	opened_room = null
	get_parent().current_tab = 0

	_room_name.hide()
	_no_room_info.show()
	
	for t in _types.values():
		t.group.clear_list()
	
	if scene_root is PopochiuRoom:
		# Actualizar la información de la habitación que se abrió
		opened_room = scene_root
		_room_name.text = opened_room.script_name
		
		_room_name.show()
		
		for t in _types:
			if _types[t].has('popup'):
				_types[t].popup.room_opened(opened_room)
		
		# Llenar la lista de props
		for p in opened_room.get_props():
			if p is Prop:
				var lbl: Label = Label.new()
				lbl.text = (p as Prop).name
				_types.prop.group.add(lbl)
		
		# Llenar la lista de hotspots
		for h in opened_room.get_hotspots():
			if h is Hotspot:
				var lbl: Label = Label.new()
				lbl.text = (h as Hotspot).name
				_types.hotspot.group.add(lbl)
		
		# Llenar la lista de regiones
		for r in opened_room.get_regions():
			if r is Region:
				var lbl: Label = Label.new()
				lbl.text = (r as Region).name
				_types.region.group.add(lbl)
		
		# Llenar la lista de puntos
		for p in opened_room.get_points():
			if p is Position2D:
				var lbl: Label = Label.new()
				lbl.text = (p as Position2D).name
				_types.point.group.add(lbl)
		
		_no_room_info.hide()

		get_parent().current_tab = 1


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _set_main_dock(value: Panel) -> void:
	main_dock = value
	
	for t in _types.values():
		if not t.has('popup'): continue
		t.popup = main_dock.get_popup(t.popup)
		t.popup.set_main_dock(main_dock)
		t.group.connect('create_clicked', main_dock, '_open_popup', [t.popup])
