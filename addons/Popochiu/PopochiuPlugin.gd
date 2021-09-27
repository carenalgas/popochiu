tool
extends EditorPlugin
# Configura el plugin
# Aquí hay varios iconos que pueden resultar útiles:
#	godot\editor\editor_themes.cpp

# TODO: Que este directorio se pueda seleccionar cuando se instala el plugin por
#		primera vez
const BASE_DIR := 'res://popochiu'
const MAIN_DOCK_PATH := 'res://addons/Popochiu/Editor/MainDock/PopochiuDock.tscn'
const EMPTY_DOCK_PATH := 'res://addons/Popochiu/Editor/MainDock/EmptyDock.tscn'
const UTILS_SNGL := 'res://addons/Popochiu/Engine/Others/Utils.gd'
const CURSOR_SNGL := 'res://addons/Popochiu/Engine/Cursor/Cursor.tscn'
const POPOCHIU_SNGL := 'res://addons/Popochiu/Engine/Popochiu.tscn'
const ICHARACTER_SNGL := 'res://addons/Popochiu/Engine/Interfaces/ICharacter.gd'
const IINVENTORY_SNGL := 'res://addons/Popochiu/Engine/Interfaces/IInventory.gd'
const IDIALOG_SNGL := 'res://addons/Popochiu/Engine/Interfaces/IDialog.gd'
const IGRAPHIC_INTERFACE_SNGL :=\
'res://addons/Popochiu/Engine/Interfaces/IGraphicInterface.gd'
const IAUDIO_MANAGER_SNGL :=\
'res://addons/Popochiu/Engine/AudioManager/AudioManager.tscn'
const GLOBALS_SRC := 'res://addons/Popochiu/Engine/Objects/_Globals.gd'
const GLOBALS_SNGL := 'res://popochiu/Globals.gd'
const GRAPHIC_INTERFACE_SRC :=\
'res://addons/Popochiu/Engine/Objects/_GraphicInterface/'
const GRAPHIC_INTERFACE_SCENE :=\
BASE_DIR + '/GraphicInterface/GraphicInterface.tscn'
const TRANSITION_LAYER_SRC :=\
'res://addons/Popochiu/Engine/Objects/_TransitionLayer/'
const TRANSITION_LAYER_SCENE :=\
BASE_DIR + '/TransitionLayer/TransitionLayer.tscn'
const POPOCHIU_SCENE := 'res://addons/Popochiu/Engine/Popochiu.tscn'

var main_dock: Panel

var _editor_interface := get_editor_interface()
var _editor_file_system := _editor_interface.get_resource_filesystem()
var _directory := Directory.new()
var _is_first_install := false
var _input_actions :=\
preload('res://addons/Popochiu/Engine/Others/InputActions.gd')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _init() -> void:
	# Gracias Dialogic
	if Engine.editor_hint:
		# Verificar si existe la carpeta donde irán los elementos del juego.
		# Si no, crear carpetas, mover archivos y actualizar Popochiu.tscn.
		_init_file_structure()
	
	# Cargar los singleton para acceder directamente a objetos de Popochiu
	if _is_first_install: return
	
	add_autoload_singleton('Utils', UTILS_SNGL)
	add_autoload_singleton('Cursor', CURSOR_SNGL)
	add_autoload_singleton('E', POPOCHIU_SNGL)
	add_autoload_singleton('C', ICHARACTER_SNGL)
	add_autoload_singleton('I', IINVENTORY_SNGL)
	add_autoload_singleton('D', IDIALOG_SNGL)
	add_autoload_singleton('G', IGRAPHIC_INTERFACE_SNGL)
	add_autoload_singleton('A', IAUDIO_MANAGER_SNGL)
	add_autoload_singleton('Globals', GLOBALS_SNGL)


func _enter_tree() -> void:
	if not _is_first_install:
		_check_popochiu_dependencies()
		
		print('[es] Estás usando Popochiu, un plugin para crear juegos point n\' click')
		print('[en] You\'re using Popochiu, a plugin for making point n\' click games')
		print('▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ \\( o )3(o)/ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒')
		
		main_dock = preload(MAIN_DOCK_PATH).instance()
		main_dock.ei = _editor_interface
		main_dock.fs = _editor_file_system
		
		main_dock.connect('room_row_clicked', self, 'update_overlays')
		
		add_control_to_dock(DOCK_SLOT_RIGHT_BR, main_dock)
		
		# Llenar las listas de habitaciones, personajes, objetos de inventario
		# y árboles de diálogo.
		yield(get_tree().create_timer(1.0), 'timeout')
		main_dock.fill_data()
		main_dock.grab_focus()
		
		_editor_file_system.connect('sources_changed', self, '_on_sources_changed')
		connect('scene_changed', main_dock, 'scene_changed')
		connect('scene_closed', main_dock, 'scene_closed')
		
		main_dock.scene_changed(_editor_interface.get_edited_scene_root())


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func enable_plugin() -> void:
	_create_input_actions()
	
	# Mostrar la ventana de diálogo para pedirle a la desarrolladora que reinicie
	# el motor.
	var ad := AcceptDialog.new()
	ad.window_title = 'El reiniciador'
	ad.dialog_text = 'Toca que reinicie el motor pa que funcione el Popochiu.'
	_editor_interface.get_base_control().add_child(ad)
	ad.popup_centered()


func disable_plugin() -> void:
	remove_autoload_singleton('Utils')
	remove_autoload_singleton('Cursor')
	remove_autoload_singleton('E')
	remove_autoload_singleton('C')
	remove_autoload_singleton('I')
	remove_autoload_singleton('D')
	remove_autoload_singleton('G')
	remove_autoload_singleton('A')
	remove_autoload_singleton('Globals')
	
	_remove_input_actions()
	
	remove_control_from_docks(main_dock)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _init_file_structure() -> void:
	var directory := Directory.new()
	
	_is_first_install = directory.dir_exists(GRAPHIC_INTERFACE_SRC)
	
	# Crear las carpetas que no existan
	for d in _get_directories().values():
		if not directory.dir_exists(d):
			directory.make_dir_recursive(d)
	
	if _is_first_install:
		# Copiar archivos y carpetas que las desarrolladoras podrán modificar
		directory.rename(GLOBALS_SRC, GLOBALS_SNGL)
		directory.rename(
			GRAPHIC_INTERFACE_SRC, GRAPHIC_INTERFACE_SCENE.get_base_dir()
		)
		directory.rename(
			TRANSITION_LAYER_SRC, TRANSITION_LAYER_SCENE.get_base_dir()
		)
		
		# Refrescar el FileSystem
		_editor_file_system.scan()


func _get_directories() -> Dictionary:
	return {
		BASE = BASE_DIR,
		ROOMS = BASE_DIR + '/Rooms',
		CHARACTERS = BASE_DIR + '/Characters',
		INVENTORY_ITEMS = BASE_DIR + '/InventoryItems',
		DIALOGS = BASE_DIR + '/Dialogs',
	}


func _create_input_actions() -> void:
	# Registrar los Input de interact, look y skip
	# Gracias QuentinCaffeino :) ()
	for d in _input_actions.ACTIONS:
		var setting_name = 'input/' + d.name
		
		if not ProjectSettings.has_setting(setting_name):
			var event: InputEvent
			
			if d.has('button'):
				event = InputEventMouseButton.new()
				event.button_index = d.button
			elif d.has('key'):
				event = InputEventKey.new()
				event.scancode = d.key
			
			ProjectSettings.set_setting(
				setting_name,
				{
					deadzone = float(d.deadzone if d.has('deadzone') else 0.5),
					events = [event]
				}
			)

	var result = ProjectSettings.save()
	assert(result == OK, 'Failed to save project settings')


func _remove_input_actions() -> void:
	for d in _input_actions.ACTIONS:
		var setting_name = 'input/' + d.name
		
		if ProjectSettings.has_setting(setting_name):
			ProjectSettings.clear(setting_name)
	
	var result = ProjectSettings.save()
	assert(result == OK, 'Failed to save project settings')


func _check_popochiu_dependencies() -> void:
	# Agregar la interfaz gráfica y la escena de transiciones a Popochiu
	var popochiu: Node = load(POPOCHIU_SCENE).instance()
	if popochiu.get_node_or_null('GraphicInterface')\
	and popochiu.get_node_or_null('TransitionLayer'):
		return
	
	var result := OK

	# Actualizar dependencias de la GraphicInterface
	_fix_dependencies(
		_editor_file_system.get_filesystem_path(
			GRAPHIC_INTERFACE_SCENE.get_base_dir()
		)
	)
	yield(get_tree().create_timer(0.3), 'timeout')
	
	# Actualizar dependencias de la TransitionLayer
	_fix_dependencies(
		_editor_file_system.get_filesystem_path(
			TRANSITION_LAYER_SCENE.get_base_dir()
		)
	)
	yield(get_tree().create_timer(0.3), 'timeout')
	
	var gi: CanvasLayer = load(GRAPHIC_INTERFACE_SCENE).instance()
	var tl: CanvasLayer = load(TRANSITION_LAYER_SCENE).instance()
	
	popochiu.add_child(gi)
	popochiu.add_child(tl)
	gi.owner = popochiu
	tl.owner = popochiu
	
	var new_popochiu: PackedScene = PackedScene.new()
	new_popochiu.pack(popochiu)
	_editor_file_system.scan()
	result = ResourceSaver.save(POPOCHIU_SCENE, new_popochiu)
	assert(
		result == OK,
		'[Popochiu] No se pudieron asignar la interfaz gráfica ni las transiciones.'
	)
	
	prints('██████████████████████████████████████████ Lista la estructura ███')


# Gracias PigDev:
# https://github.com/pigdevstudio/godot_tools/blob/master/source/tools/DependencyFixer.gd
func _fix_dependencies(dir: EditorFileSystemDirectory) -> void:
	var res := _editor_file_system.get_filesystem()
	
	for f in dir.get_file_count():
		var path = dir.get_file_path(f)
		var dependencies = ResourceLoader.get_dependencies(path)
		var file = File.new()

		for d in dependencies:
			if file.file_exists(d):
				continue
			_fix_dependency(d, res, path)

	for subdir in dir.get_subdir_count():
		subdir = dir.get_subdir(subdir)
		for f in subdir.get_file_count():
			var path = subdir.get_file_path(f)
			var dependencies = ResourceLoader.get_dependencies(path)
			if dependencies.size() < 1:
				continue
			var file = File.new()
			for d in dependencies:
				if file.file_exists(d):
					continue
				_fix_dependency(d, res, path)
	_editor_file_system.scan()


func _fix_dependency(dependency, directory, resource_path):
	for subdir in directory.get_subdir_count():
		_fix_dependency(dependency, directory.get_subdir(subdir), resource_path)

	for f in directory.get_file_count():
		if not directory.get_file(f) == dependency.get_file():
			continue
		var file = File.new()
		file.open(resource_path, file.READ)
		var text = file.get_as_text()
		file.close()
		text = text.replace(dependency, directory.get_file_path(f))
		file.open(resource_path, file.WRITE)
		file.store_string(text)
		file.close()


func _on_sources_changed(exist: bool) -> void:
	if Engine.editor_hint and is_instance_valid(main_dock):
		main_dock.search_audio_files()
