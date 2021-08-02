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

onready var _rooms_list: Container = find_node('RoomsList')
onready var _btn_create_room: Button = find_node('BtnCreateRoom')
onready var _create_room_popup: ConfirmationDialog = find_node('PopupCreateRoom')
onready var _characters_list: Container = find_node('CharactersList')
onready var _btn_create_character: Button = find_node('BtnCreateCharacter')
onready var _create_character_popup: ConfirmationDialog = find_node(\
'PopupCreateCharacter')
onready var _inventory_list: Container = find_node('InventoryItemsList')
onready var _btn_create_item: Button = find_node('BtnCreateItem')
onready var _create_item_popup: ConfirmationDialog = find_node(\
'PopupCreateInventoryItem')
onready var _dialogs_list: Container = find_node('DialogTreesList')
onready var _btn_create_dialog: Button = find_node('BtnCreateDialog')
onready var _create_dialog_popup: ConfirmationDialog = find_node(\
'PopupCreateDialogTree')
onready var _types := {
	room = {
		path = rooms_path,
		type_hint = 'GAQRoom',
		list = _rooms_list,
		button = _btn_create_room
	},
	character = {
		path = characters_path,
		type_hint = 'GAQCharacter',
		list = _characters_list,
		button = _btn_create_character
	},
	inventory_item = {
		path = inventory_items_path,
		type_hint = 'GAQInventoryItem',
		list = _inventory_list,
		button = _btn_create_item
	},
	dialog_tree = {
		path = dialog_trees_path,
		type_hint = 'DialogTree',
		list = _dialogs_list,
		button = _btn_create_dialog
	},
}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_create_room_popup.set_main_dock(self)
	_create_character_popup.set_main_dock(self)
	_create_item_popup.set_main_dock(self)
	_create_dialog_popup.set_main_dock(self)

	# Creación de habitaciones
	_btn_create_room.connect(
		'pressed', self, '_open_popup', [_create_room_popup]
	)
	_btn_create_character.connect(
		'pressed', self, '_open_popup', [_create_character_popup]
	)
	_btn_create_item.connect(
		'pressed', self, '_open_popup', [_create_item_popup]
	)
	_btn_create_dialog.connect(
		'pressed', self, '_open_popup', [_create_dialog_popup]
	)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func fill_data() -> void:
	for t in _types:
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


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _open_popup(popup: Popup) -> void:
	popup.popup_centered()
