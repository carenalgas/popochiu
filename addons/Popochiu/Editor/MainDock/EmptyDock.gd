tool
extends Panel

const BASE_DIR := 'res://popochiu'

var ei: EditorInterface
var fs: EditorFileSystem
var directory := Directory.new()

onready var _btn_create_structure: Button = find_node('BtnCreateStructure')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_btn_create_structure.connect('pressed', self, '_create_structure')
	
	if directory.dir_exists(BASE_DIR):
		$MarginContainer/VBoxContainer/Label.text = \
		'Ahora hay que mover unos archivos. Hágale ahí al botón.'
		_btn_create_structure.text = 'Mover archivos'

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _create_structure() -> void:
	if not directory.dir_exists(BASE_DIR):
		for d in _get_directories().values():
			if not directory.dir_exists(d):
				directory.make_dir_recursive(d)

		var err: int = directory.copy(
		'res://addons/Popochiu/Engine/Others/Globals.gd', BASE_DIR + '/Globals.gd')
		prints('Oh oh...', err)

		fs.scan()

		$MarginContainer/VBoxContainer/Label.text = \
		'Ahora hay que mover unos archivos. Hágale ahí al botón.'
		_btn_create_structure.text = 'Mover archivos'
	else:
		var err: int = directory.copy(
		'res://addons/Popochiu/Engine/Others/Globals.gd', BASE_DIR + '/Globals.gd')
		prints('Oh oh...', err)


func _get_directories() -> Dictionary:
	return {
		BASE = BASE_DIR,
		ROOMS = BASE_DIR + '/Rooms',
		CHARACTERS = BASE_DIR + '/Characters',
		INVENTORY_ITEMS = BASE_DIR + '/InventoryItems',
		DIALOGS = BASE_DIR + '/Dialogs',
	}
