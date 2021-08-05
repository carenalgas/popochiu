tool
class_name PopochiuDock
extends Panel
# Define un conjunto de botones y otros elementos para centralizar la configuración
# de los diferentes nodos que conforman el juego:
#	Rooms (Props, Hotspots, Regions), Characters, Inventory items, Dialog trees,
#	Interfaz gráfica.

const GAQ_PATH := 'res://src/Autoload/GodotAdventureQuest.tscn'

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
		type_hint = 'GAQRoom',
		list = find_node('RoomsList') as Container,
		button = find_node('BtnCreateRoom') as Button,
		popup = find_node('CreateRoom') as ConfirmationDialog
	},
	character = {
		path = characters_path,
		type_hint = 'GAQCharacter',
		list = find_node('CharactersList') as Container,
		button = find_node('BtnCreateCharacter') as Button,
		popup = find_node('CreateCharacter') as ConfirmationDialog
	},
	inventory_item = {
		path = inventory_items_path,
		type_hint = 'GAQInventoryItem',
		list = find_node('InventoryItemsList') as Container,
		button = find_node('BtnCreateItem') as Button,
		popup = find_node('CreateInventoryItem') as ConfirmationDialog
	},
	dialog_tree = {
		path = dialog_trees_path,
		type_hint = 'DialogTree',
		list = find_node('DialogTreesList') as Container,
		button = find_node('BtnCreateDialog') as Button,
		popup = find_node('CreateDialogTree') as ConfirmationDialog
	},
	prop = {
		list = find_node('PropsList') as Container,
		button = find_node('BtnCreateProp') as Button,
		popup = find_node('CreateProp') as ConfirmationDialog
	},
}
onready var _props_group: PopochiuGroupButton = find_node('PropsGroupButton')
onready var _props_list: Container = _types['prop'].list
onready var _props_btn: Button = _types['prop'].button
onready var _props_popup: ConfirmationDialog = _types['prop'].popup
onready var _hotspots_group: PopochiuGroupButton = find_node('HotspotsGroupButton')
onready var _hotspots_list: Container = find_node('HotspotsList')
onready var _hotspots_btn: Button = find_node('BtnCreateHotspot')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	# Por defecto deshabilitar los botones hasta que no se haya seleccionado
	# una habitación.
	_props_btn.disabled = true
	_hotspots_btn.disabled = true
	
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

				var lbl: Label = Label.new()
				lbl.text = resource.script_name

				_types[t].list.add_child(lbl)

		_types[t].list.move_child(
			_types[t].button, _types[t].list.get_child_count()
		)


func add_to_list(type: String, name_to_add: String) -> void:
	var new_lbl: Label = Label.new()
	new_lbl.text = name_to_add
	_types[type].list.add_child(new_lbl)
	_types[type].list.move_child(
		_types[type].button, _types[type].list.get_child_count()
	)


func scene_changed(scene_root: Node) -> void:
	if scene_root is Room:
		_props_group.clear_list()
		_props_popup.room_opened()
		_hotspots_group.clear_list()

		opened_room = null
		_props_btn.disabled = true
		_hotspots_btn.disabled = true

		opened_room = scene_root

		_tab_container.current_tab = 1
		_props_btn.disabled = false
		_hotspots_btn.disabled = false

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


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _open_popup(popup: Popup) -> void:
	popup.popup_centered()
