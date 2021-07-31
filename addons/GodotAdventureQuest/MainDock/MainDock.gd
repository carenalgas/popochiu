tool
extends Panel
# Define un conjunto de botones y otros elementos para centralizar la configuración
# de los diferentes nodos que conforman el juego:
#	Rooms (Props, Hotspots, Regions), Characters, Inventory items, Dialog trees,
#	Interfaz gráfica.

# ------------------------------------------------------------------------------
# TODO: Definir más propiedades en el popup de creación de la habitación: p. ej.
#		si va a tener al player, o los límites de la cámara. Aunque eso ya se
#		puede hacer una vez se abra el .tscn.

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
	# Llenar la lista de habitaciones
	_fill_rooms()
	# Llenar la lista de personajes
	_fill_characters()
	# Llenar la lista de ítems del inventario
	_fill_inventory_items()
	# Llenar la lista de árboles de diálogo
	_fill_dialog_trees()


func add_room_to_list(room_name: String) -> void:
	var new_room_lbl: Label = Label.new()
	new_room_lbl.text = room_name
	_rooms_list.add_child(new_room_lbl)
	_rooms_list.move_child(_btn_create_room, _rooms_list.get_child_count())


func add_character_to_list(character_name: String) -> void:
	var new_character_lbl: Label = Label.new()
	new_character_lbl.text = character_name
	_characters_list.add_child(new_character_lbl)
	_characters_list.move_child(
		_btn_create_character, _characters_list.get_child_count()
	)


func add_item_to_list(item_name: String) -> void:
	var new_item_lbl: Label = Label.new()
	new_item_lbl.text = item_name
	_inventory_list.add_child(new_item_lbl)
	_inventory_list.move_child(
		_btn_create_item, _inventory_list.get_child_count()
	)


func add_dialog_to_list(dialog_name: String) -> void:
	var new_dialog_lbl: Label = Label.new()
	new_dialog_lbl.text = dialog_name
	_dialogs_list.add_child(new_dialog_lbl)
	_dialogs_list.move_child(_btn_create_dialog, _dialogs_list.get_child_count())


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _open_popup(popup: Popup) -> void:
	popup.popup_centered()


func _fill_rooms() -> void:
	var rooms_dir: EditorFileSystemDirectory = fs.get_filesystem_path(rooms_path)
	for d in rooms_dir.get_subdir_count():
		var dir: EditorFileSystemDirectory = rooms_dir.get_subdir(d)
		for f in dir.get_file_count():
			var path = dir.get_file_path(f)

			if not fs.get_file_type(path) == "Resource":
				continue
			
			var room: GAQRoom = ResourceLoader.load(path)

			var room_lbl: Label = Label.new()
			room_lbl.text = room.id

			_rooms_list.add_child(room_lbl)

	_rooms_list.move_child(_btn_create_room, _rooms_list.get_child_count())


func _fill_characters() -> void:
	var characters_dir: EditorFileSystemDirectory = fs.get_filesystem_path(\
	characters_path)
	for d in characters_dir.get_subdir_count():
		var dir: EditorFileSystemDirectory = characters_dir.get_subdir(d)
		for f in dir.get_file_count():
			var path = dir.get_file_path(f)

			if not fs.get_file_type(path) == "Resource":
				continue
			
			var character: GAQCharacter = ResourceLoader.load(path)

			var character_lbl: Label = Label.new()
			character_lbl.text = character.id

			_characters_list.add_child(character_lbl)

	_characters_list.move_child(
		_btn_create_character, _characters_list.get_child_count()
	)


func _fill_inventory_items() -> void:
	var inventory_items_dir: EditorFileSystemDirectory = fs.get_filesystem_path(
		inventory_items_path
	)
	for d in inventory_items_dir.get_subdir_count():
		var dir: EditorFileSystemDirectory = inventory_items_dir.get_subdir(d)
		for f in dir.get_file_count():
			var path = dir.get_file_path(f)

			if not fs.get_file_type(path) == "Resource":
				continue
			
			var item: GAQInventoryItem = ResourceLoader.load(path)

			var item_lbl: Label = Label.new()
			item_lbl.text = item.id

			_inventory_list.add_child(item_lbl)

	_inventory_list.move_child(
		_btn_create_item, _inventory_list.get_child_count()
	)


func _fill_dialog_trees() -> void:
	var dialog_trees_dir: EditorFileSystemDirectory = fs.get_filesystem_path(
		dialog_trees_path
	)
	for d in dialog_trees_dir.get_subdir_count():
		var dir: EditorFileSystemDirectory = dialog_trees_dir.get_subdir(d)
		for f in dir.get_file_count():
			var path = dir.get_file_path(f)

			if not fs.get_file_type(path) == "Resource":
				continue
			
			var dialog_tree: DialogTree = ResourceLoader.load(path)

			var dialog_tree_lbl: Label = Label.new()
			dialog_tree_lbl.text = dialog_tree.script_name

			_dialogs_list.add_child(dialog_tree_lbl)

	_dialogs_list.move_child(
		_btn_create_dialog, _dialogs_list.get_child_count()
	)
