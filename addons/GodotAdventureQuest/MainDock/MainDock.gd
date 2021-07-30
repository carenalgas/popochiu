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


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_create_room_popup.set_main_dock(self)
	_create_character_popup.set_main_dock(self)

	# Creación de habitaciones
	_btn_create_room.connect('pressed', self, '_show_create_room_popup')
	_btn_create_character.connect('pressed', self, '_show_create_character_popup')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func fill_data() -> void:
	# Llenar la lista de habitaciones
	_fill_rooms()
	# Llenar la lista de personajes
	_fill_characters()


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


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _show_create_room_popup() -> void:
	_create_room_popup.popup_centered()


func _show_create_character_popup() -> void:
	_create_character_popup.popup_centered()


func _fill_rooms() -> void:
	var rooms_dir: EditorFileSystemDirectory = fs.get_filesystem_path(rooms_path)
	for d in rooms_dir.get_subdir_count():
		var dir: EditorFileSystemDirectory = rooms_dir.get_subdir(d)
		for f in dir.get_file_count():
			var path = dir.get_file_path(f)

			if not fs.get_file_type(path) == "Resource":
				continue
			
			var room: GAQRoom = ResourceLoader.load(path) as GAQRoom

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
			
			var character: GAQCharacter = ResourceLoader.load(path) as\
			GAQCharacter

			var character_lbl: Label = Label.new()
			character_lbl.text = character.id

			_characters_list.add_child(character_lbl)

	_characters_list.move_child(
		_btn_create_character, _characters_list.get_child_count()
	)
