tool
class_name PopochiuDock
extends Panel
# Define un conjunto de botones y otros elementos para centralizar la configuración
# de los diferentes nodos que conforman el juego:
#	Rooms (Props, Hotspots, Regions), Characters, Inventory items, Dialog trees,
#	Interfaz gráfica.

const POPOCHIU_SCENE := 'res://src/Autoload/Popochiu.tscn'

export var rooms_path := 'res://src/Rooms/'
export var characters_path := 'res://src/Characters/'
export var inventory_items_path := 'res://src/InventoryItems/'
export var dialog_trees_path := 'res://src/DialogTrees/'

var ei: EditorInterface
var fs: EditorFileSystem
var dir := Directory.new()
var opened_room: Room = null

onready var _tab_container: TabContainer = find_node('TabContainer')
onready var _types := {
	room = {
		path = rooms_path,
		type_hint = 'PopochiuRoom',
		list = find_node('RoomsList'),
		button = find_node('BtnCreateRoom'),
		popup = find_node('CreateRoom'),
		scene = rooms_path + ('%s/Room%s.tscn')
	},
	character = {
		path = characters_path,
		type_hint = 'PopochiuCharacter',
		list = find_node('CharactersList'),
		button = find_node('BtnCreateCharacter'),
		popup = find_node('CreateCharacter'),
		scene = characters_path + ('%s/Character%s.tscn')
	},
	inventory_item = {
		path = inventory_items_path,
		type_hint = 'PopochiuInventoryItem',
		list = find_node('InventoryItemsList'),
		button = find_node('BtnCreateItem'),
		popup = find_node('CreateInventoryItem'),
		scene = inventory_items_path + ('%s/Inventory%s.tscn')
	},
	dialog_tree = {
		path = dialog_trees_path,
		type_hint = 'DialogTree',
		list = find_node('DialogTreesList'),
		button = find_node('BtnCreateDialog'),
		popup = find_node('CreateDialogTree'),
		scene = dialog_trees_path + ('%s/Dialog%s.tres')
	},
	prop = {
		group = find_node('PropsGroupButton'),
		list = find_node('PropsList'),
		button = find_node('BtnCreateProp'),
		popup = find_node('CreateProp')
	},
	hotspot = {
		group = find_node('HotspotsGroupButton'),
		list = find_node('HotspotsList'),
		button = find_node('BtnCreateHotspot'),
		popup = find_node('CreateHotspot')
	},
	region = {
		group = find_node('RegionsGroupButton'),
		list = find_node('RegionsList'),
		button = find_node('BtnCreateRegion'),
		popup = find_node('CreateRegion')
	},
}
onready var _no_room_info: Label = find_node('NoRoomInfo')
onready var _props_group: PopochiuGroupButton = _types['prop'].group
onready var _props_list: Container = _types['prop'].list
onready var _props_btn: Button = _types['prop'].button
onready var _props_popup: ConfirmationDialog = _types['prop'].popup
onready var _hotspots_group: PopochiuGroupButton = _types['hotspot'].group
onready var _hotspots_list: Container = _types['hotspot'].list
onready var _hotspots_btn: Button = _types['hotspot'].button
onready var _hotspots_popup: ConfirmationDialog = _types['hotspot'].popup
onready var _regions_group: PopochiuGroupButton = _types['region'].group
onready var _regions_list: Container = _types['region'].list
onready var _regions_btn: Button = _types['region'].button
onready var _regions_popup: ConfirmationDialog = _types['region'].popup
onready var _points_group: PopochiuGroupButton = find_node('PointsGroupButton')
onready var _points_list: Container = find_node('PointsList')
onready var _object_row: PackedScene = preload(\
'res://addons/Popochiu/Editor/MainDock/ObjectRow/PopochiuObjectRow.tscn')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	# Por defecto deshabilitar los botones hasta que no se haya seleccionado
	# una habitación.
	_props_btn.disabled = true
	_hotspots_btn.disabled = true
	_regions_btn.disabled = true
	_tab_container.current_tab = 0
	
	_tab_container.set_tab_disabled(0, false)
	_tab_container.set_tab_disabled(1, false)

	_no_room_info.hide()
	
	# Creación de habitaciones
	for t in _types:
		_types[t].popup.set_main_dock(self)
		(_types[t].button as Button).connect(
			'pressed', self, '_open_popup', [_types[t].popup]
		)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func fill_data() -> void:
	for t in _types:
		if not _types[t].has('path'):
			continue
		
		var type_dir: EditorFileSystemDirectory = fs.get_filesystem_path(
			_types[t].path
		)
		for d in type_dir.get_subdir_count():
			var dir: EditorFileSystemDirectory = type_dir.get_subdir(d)
			for f in dir.get_file_count():
				var path = dir.get_file_path(f)

				if not fs.get_file_type(path) == "Resource":
					continue
				
				var resource: Resource = ResourceLoader.load(
					path, _types[t].type_hint
				)

				add_to_list(t, resource.script_name)


func add_to_list(type: String, name_to_add: String) -> void:
	var new_obj: PopochiuObjectRow = _object_row.instance()

	new_obj.name = name_to_add
	new_obj.type = type
	new_obj.path = _types[type].scene % [name_to_add, name_to_add]
	
	new_obj.connect('delete_pressed', self, '_delete_object')
	new_obj.connect('open_pressed', self, '_open_object')

	_types[type].list.add_child(new_obj)
	_types[type].list.move_child(
		_types[type].button, _types[type].list.get_child_count()
	)


func scene_changed(scene_root: Node) -> void:
	# Poner todo en su estado por defecto
	opened_room = null

	_props_btn.disabled = true
	_hotspots_btn.disabled = true
	_regions_btn.disabled = true

	_no_room_info.show()
	_props_group.clear_list()
	_hotspots_group.clear_list()
	_regions_group.clear_list()
	_points_group.clear_list()
	
	if scene_root is Room:
		# Actualizar la información de la habitación que se abrió
		opened_room = scene_root

		_props_popup.room_opened()
		_hotspots_popup.room_opened()
		_regions_popup.room_opened()

		# Llenar la lista de props
		for p in opened_room.get_props():
			if p is Prop:
				var lbl: Label = Label.new()
				lbl.text = (p as Prop).name
				_props_list.add_child(lbl)
		_props_list.move_child(_props_btn, _props_list.get_child_count())
		
		# Llenar la lista de hotspots
		for h in opened_room.get_hotspots():
			if h is Hotspot:
				var lbl: Label = Label.new()
				lbl.text = (h as Hotspot).name
				_hotspots_list.add_child(lbl)
		_hotspots_list.move_child(
			_hotspots_btn, _hotspots_list.get_child_count()
		)
		
		# Llenar la lista de regiones
		for r in opened_room.get_regions():
			if r is Region:
				var lbl: Label = Label.new()
				lbl.text = (r as Region).name
				_regions_list.add_child(lbl)
		_regions_list.move_child(_regions_btn, _regions_list.get_child_count())
		
		# Llenar la lista de puntos
		for p in opened_room.get_points():
			if p is Position2D:
				var lbl: Label = Label.new()
				lbl.text = (p as Position2D).name
				_points_list.add_child(lbl)
		
		_no_room_info.hide()
		_props_btn.disabled = false
		_hotspots_btn.disabled = false
		_regions_btn.disabled = false

		_tab_container.current_tab = 1


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _open_popup(popup: Popup) -> void:
	popup.popup_centered()


func _open_object(path: String) -> void:
	ei.select_file(path)
	if path.find('.tres') < 0:
		ei.open_scene_from_path(path)
	else:
		ei.edit_resource(load(path))
