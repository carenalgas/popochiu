tool
extends EditorPlugin
# Configura el plugin
# Aquí hay varios iconos que pueden resultar útiles:
#	godot\editor\editor_themes.cpp

const Constants := preload('res://addons/Popochiu/Constants.gd')
#const PopochiuDock := preload('res://addons/Popochiu/Editor/MainDock/PopochiuDock.gd')

var main_dock: Panel

var _editor_interface := get_editor_interface()
var _editor_file_system := _editor_interface.get_resource_filesystem()
var _directory := Directory.new()
var _is_first_install := false
var _input_actions :=\
preload('res://addons/Popochiu/Engine/Others/InputActions.gd')
var _shown_helpers := []


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _init() -> void:
	# Gracias Dialogic
	if Engine.editor_hint:
		# Verificar si existe la carpeta donde irán los elementos del juego.
		# Si no, crear carpetas, mover archivos y actualizar Popochiu.tscn.
		_init_file_structure()
	
	# Cargar los singleton para acceder directamente a objetos de Popochiu
	add_autoload_singleton('U', Constants.UTILS_SNGL)
	add_autoload_singleton('Cursor', Constants.CURSOR_SNGL)
	add_autoload_singleton('E', Constants.POPOCHIU_SNGL)
	add_autoload_singleton('C', Constants.ICHARACTER_SNGL)
	add_autoload_singleton('I', Constants.IINVENTORY_SNGL)
	add_autoload_singleton('D', Constants.IDIALOG_SNGL)
	add_autoload_singleton('G', Constants.IGRAPHIC_INTERFACE_SNGL)
	add_autoload_singleton('A', Constants.IAUDIO_MANAGER_SNGL)


func _enter_tree() -> void:
	prints('[es] Estás usando Popochiu, un plugin para crear juegos point n\' click')
	prints('[en] You\'re using Popochiu, a plugin for making point n\' click games')
	prints('▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ \\( o )3(o)/ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒')

	main_dock = load(Constants.MAIN_DOCK_PATH).instance()
	main_dock.ei = _editor_interface
	main_dock.fs = _editor_file_system
	main_dock.focus_mode = Control.FOCUS_ALL

	main_dock.connect('room_row_clicked', self, 'update_overlays')
	add_control_to_dock(DOCK_SLOT_RIGHT_BR, main_dock)
	
	# Llenar las listas de habitaciones, personajes, objetos de inventario
	# y árboles de diálogo.
	yield(get_tree().create_timer(0.5), 'timeout')

	main_dock.fill_data()
	main_dock.grab_focus()
	
	_editor_interface.get_selection().connect(
		'selection_changed', self, '_check_nodes'
	)
	_editor_file_system.connect('sources_changed', self, '_on_sources_changed')
	connect('scene_changed', main_dock, 'scene_changed')
	connect('scene_closed', main_dock, 'scene_closed')
	
	main_dock.scene_changed(_editor_interface.get_edited_scene_root())

	if _is_first_install:
		main_dock.connect('move_folders_pressed', self, '_move_addon_folders')
		main_dock.show_move_folders_button()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func enable_plugin() -> void:
	_create_input_actions()
	
	if _is_first_install:
		# Mostrar la ventana de diálogo para pedirle a la desarrolladora que reinicie
		# el motor.
		var ad := AcceptDialog.new()
		# TODO: Localize
		ad.window_title = 'Popochiu'
		ad.dialog_text = '[es] Reinicia el motor para completar la instalación.\n' + \
		'[en] Restart Godot to complete the instalation.'
		_editor_interface.get_base_control().add_child(ad)
		ad.popup_centered()


func disable_plugin() -> void:
	remove_autoload_singleton('U')
	remove_autoload_singleton('Cursor')
	remove_autoload_singleton('E')
	remove_autoload_singleton('C')
	remove_autoload_singleton('I')
	remove_autoload_singleton('D')
	remove_autoload_singleton('G')
	remove_autoload_singleton('A')
	
	_remove_input_actions()
	
	remove_control_from_docks(main_dock)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _init_file_structure() -> void:
	var directory := Directory.new()
	
	_is_first_install = !directory.dir_exists(Constants.BASE_DIR)
	
	# Crear las carpetas que no existan
	for d in _get_directories().values():
		if not directory.dir_exists(d):
			directory.make_dir_recursive(d)

#	_is_first_install = directory.dir_exists(Constants.GRAPHIC_INTERFACE_SRC)\
#	or directory.dir_exists(Constants.TRANSITION_LAYER_SRC)


func _get_directories() -> Dictionary:
	return {
		BASE = Constants.BASE_DIR,
		ROOMS = Constants.BASE_DIR + '/Rooms',
		CHARACTERS = Constants.BASE_DIR + '/Characters',
		INVENTORY_ITEMS = Constants.BASE_DIR + '/InventoryItems',
		DIALOGS = Constants.BASE_DIR + '/Dialogs',
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
	assert(result == OK, '[Popochiu] Failed to save project settings.')


func _remove_input_actions() -> void:
	for d in _input_actions.ACTIONS:
		var setting_name = 'input/' + d.name
		
		if ProjectSettings.has_setting(setting_name):
			ProjectSettings.clear(setting_name)
	
	var result = ProjectSettings.save()
	assert(result == OK, '[Popochiu] Failed to save project settings.')


func _move_addon_folders() -> void:
	# Eliminar las referencias de la interfaz gráfica y las animaciones de transición.
	var result := OK
	var popochiu: Node = load(Constants.POPOCHIU_SCENE).instance()
	var gi: CanvasLayer = popochiu.get_node_or_null('GraphicInterface')
	var tl: CanvasLayer = popochiu.get_node_or_null('TransitionLayer')

	popochiu.remove_child(gi)
	popochiu.remove_child(tl)
	
	var new_popochiu: PackedScene = PackedScene.new()
	new_popochiu.pack(popochiu)
	_editor_file_system.scan()
	result = ResourceSaver.save(Constants.POPOCHIU_SCENE, new_popochiu)
	assert(
		result == OK,
		'[Popochiu] Could not save after removing GI and TL from Popochiu.'
	)

	# Copiar archivos y carpetas que las desarrolladoras podrán modificar
	_directory.rename(
		Constants.GRAPHIC_INTERFACE_SRC,
		Constants.GRAPHIC_INTERFACE_SCENE.get_base_dir()
	)
	_directory.rename(
		Constants.TRANSITION_LAYER_SRC,
		Constants.TRANSITION_LAYER_SCENE.get_base_dir()
	)
	
	# Refrescar el FileSystem
	_editor_file_system.scan()

	# Corregir problemas de dependencias
	yield(_editor_file_system, 'filesystem_changed')
	yield(_check_popochiu_dependencies(), 'completed')
	main_dock.hide_move_folders_button()



func _check_popochiu_dependencies() -> void:
	# Agregar la interfaz gráfica y la escena de transiciones a Popochiu
	var popochiu: Node = load(Constants.POPOCHIU_SCENE).instance()

	if not popochiu:
		printerr('[Popochiu] Popochius.tscn is broken.')
		return
	
	var save_popochiu := false

	if not popochiu.get_node_or_null('GraphicInterface'):
		# Actualizar dependencias de la GraphicInterface
		_fix_dependencies(
			_editor_file_system.get_filesystem_path(
				Constants.GRAPHIC_INTERFACE_SCENE.get_base_dir()
			)
		)
		yield(get_tree().create_timer(0.3), 'timeout')
		var gi: CanvasLayer = load(Constants.GRAPHIC_INTERFACE_SCENE).instance()
		popochiu.add_child(gi)
		gi.owner = popochiu

		save_popochiu = true
	
	if not popochiu.get_node_or_null('TransitionLayer'):
		# Actualizar dependencias de la TransitionLayer
		_fix_dependencies(
			_editor_file_system.get_filesystem_path(
				Constants.TRANSITION_LAYER_SCENE.get_base_dir()
			)
		)
		yield(get_tree().create_timer(0.3), 'timeout')
		var tl: CanvasLayer = load(Constants.TRANSITION_LAYER_SCENE).instance()
		popochiu.add_child(tl)
		tl.owner = popochiu

		save_popochiu = true
	
	if save_popochiu:
		var result := OK
		var new_popochiu: PackedScene = PackedScene.new()
		new_popochiu.pack(popochiu)
		# _editor_file_system.scan()
		result = ResourceSaver.save(Constants.POPOCHIU_SCENE, new_popochiu)
		assert(
			result == OK,
			'[Popochiu] Could not save Popochiu after fixing GI or TL dependencies.'
		)

		yield(_editor_file_system, 'filesystem_changed')
	
		prints('█████████████████████████████████████ Project structure ready ████')
	
	yield(get_tree(), 'idle_frame')


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


# Toggles Clickable helpers in order to show walk-to-point, baseline and dialog
# position (PopochiuCharacter) only when a node of that type is selected in the
# scene tree.
func _check_nodes() -> void:
	for n in _shown_helpers:
		if is_instance_valid(n):
			n.hide_helpers()
	
	_shown_helpers.clear()
	
	if not is_instance_valid(_editor_interface.get_selection()): return

	for n in _editor_interface.get_selection().get_selected_nodes():
		if n.has_method('show_helpers'):
			n.show_helpers()
			_shown_helpers.append(n)
