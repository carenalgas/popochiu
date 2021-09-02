tool
extends EditorPlugin

# TODO: Que este directorio se pueda seleccionar cuando se instala el plugin por
#		primera vez
const BASE_DIR := 'res://popochiu'

var gaq_dock: Panel

var _editor_interface: EditorInterface
var _editor_file_system: EditorFileSystem


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _init() -> void:
	# Gracias Dialogic
	if Engine.editor_hint:
		# Verificar si existe la carpeta donde irán los elementos del juego.
		# Si no, crear carpetas, mover archivos y actualizar Popochiu.tscn.
		init_file_structure()
	
	# Cargar los singleton para acceder directamente a objetos de Popochiu
	add_autoload_singleton('Utils', 'res://addons/Popochiu/Engine/Others/Utils.gd')
	add_autoload_singleton('Cursor', 'res://addons/Popochiu/Engine/Cursor/Cursor.tscn')
	add_autoload_singleton('E', 'res://addons/Popochiu/Engine/Popochiu.tscn')
	add_autoload_singleton('C', 'res://addons/Popochiu/Engine/Interfaces/ICharacter.gd')
	add_autoload_singleton('I', 'res://addons/Popochiu/Engine/Interfaces/IInventory.gd')
	add_autoload_singleton('D', 'res://addons/Popochiu/Engine/Interfaces/IDialog.gd')
	add_autoload_singleton('G', 'res://addons/Popochiu/Engine/Interfaces/IGraphicInterface.gd')
	add_autoload_singleton('Globals', 'res://popochiu/Globals.gd')


func _enter_tree() -> void:
	_editor_interface = get_editor_interface()
	_editor_file_system = _editor_interface.get_resource_filesystem()

	gaq_dock = preload("res://addons/Popochiu/Editor/MainDock/PopochiuDock.tscn").instance()
	gaq_dock.ei = _editor_interface
	gaq_dock.fs = _editor_file_system

	add_control_to_dock(DOCK_SLOT_RIGHT_BR, gaq_dock)
	
	# Agregar los tipos de Resource del plugin
#	add_custom_type(
#		'> PopochiuRoomData',
#		'Script',
#		preload('res://addons/Popochiu/Engine/Objects/Room/PopochiuRoomData.gd'),
#		preload('res://addons/Popochiu/icons/room.png')
#	)
#	add_custom_type(
#		'> PopochiuCharacterData',
#		'Script',
#		preload('res://addons/Popochiu/Engine/Objects/Character/PopochiuCharacterData.gd'),
#		preload('res://addons/Popochiu/icons/character.png')
#	)
#	add_custom_type(
#		'> PopochiuInventoryItemData',
#		'Script',
#		preload('res://addons/Popochiu/Engine/Objects/InventoryItem/PopochiuInventoryItemData.gd'),
#		preload('res://addons/Popochiu/icons/inventory_item.png')
#	)
	
#	_editor_file_system.connect("filesystem_changed", self, "_on_filesystem_changed")
	connect('scene_changed', gaq_dock, 'scene_changed')
	
	# Llenar las listas de habitaciones, personajes, objetos de inventario y
	# árboles de diálogo.
	yield(get_tree().create_timer(1.0), 'timeout')
	gaq_dock.fill_data()


func _exit_tree() -> void:
	remove_autoload_singleton('Utils')
	remove_autoload_singleton('Cursor')
	remove_autoload_singleton('E')
	remove_autoload_singleton('C')
	remove_autoload_singleton('I')
	remove_autoload_singleton('D')
	remove_autoload_singleton('G')
	remove_autoload_singleton('Globals')
	remove_control_from_docks(gaq_dock)


func _on_filesystem_changed() -> void:
	prints('Cambiao')
#	gaq_dock.fill_data()


func init_file_structure() -> void:
	var d := Directory.new()
	
	if not d.dir_exists(BASE_DIR):
		prints('-------------------------------------', 'Creando lo inicial!!!')

		d.make_dir_recursive(BASE_DIR)
		d.make_dir_recursive(BASE_DIR + '/Rooms')
		d.make_dir_recursive(BASE_DIR + '/Characters')
		d.make_dir_recursive(BASE_DIR + '/InventoryItems')
		d.make_dir_recursive(BASE_DIR + '/Dialogs')

		d.copy('res://addons/Popochiu/Engine/Others/Globals.gd', BASE_DIR)
