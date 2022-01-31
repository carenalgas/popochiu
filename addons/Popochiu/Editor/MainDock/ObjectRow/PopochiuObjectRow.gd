tool
class_name PopochiuObjectRow
extends HBoxContainer
# NOTA: El icono para el menú contextual podría ser el icon_GUI_tab_menu_hl.svg
#		de los iconos de Godot.

signal clicked(node)

enum MenuOptions { ADD_TO_CORE, SET_AS_MAIN, DELETE }

const SELECTED_FONT_COLOR := Color('706deb')

var type := -1
var path := ''
var main_dock: Panel = null setget _set_main_dock
var is_main := false setget _set_is_main

var _delete_dialog: ConfirmationDialog
var _delete_all_checkbox: CheckBox

onready var _label: Label = find_node('Label')
onready var _dflt_font_color: Color = _label.get_color('font_color')
onready var _fav_icon: TextureRect = find_node('FavIcon')
onready var _menu_btn: MenuButton = find_node('MenuButton')
onready var _menu_popup: PopupMenu = _menu_btn.get_popup()
onready var _btn_open: Button = find_node('Open')
onready var _menu_cfg := [
	{
		id = MenuOptions.ADD_TO_CORE,
		icon = preload(\
		'res://addons/Popochiu/Editor/MainDock/ObjectRow/add_to_core.png'),
		label = 'Add to Popochiu',
		types = [
			main_dock.Types.ROOM,
			main_dock.Types.CHARACTER,
			main_dock.Types.INVENTORY_ITEM,
			main_dock.Types.DIALOG
		]
	},
	{
		id = MenuOptions.SET_AS_MAIN,
		icon = get_icon('Heart', 'EditorIcons'),
		label = 'Set as Main scene',
		types = [main_dock.Types.ROOM]
	},
	null,
	{
		id = MenuOptions.DELETE,
		icon = get_icon('Remove', 'EditorIcons'),
		label = 'Remove'
	}
]


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_label.text = name
	
	# Definir iconos
	_fav_icon.texture = get_icon('Heart', 'EditorIcons')
	_btn_open.icon = get_icon('InstanceOptions', 'EditorIcons')
	_menu_btn.icon = get_icon('GuiTabMenu', 'EditorIcons')
	
	# Crear menú contextual
	_create_menu()
	_menu_popup.set_item_disabled(MenuOptions.ADD_TO_CORE, true)
	
	# Ocultar cosas que se verán dependiendo de otras cosas
	_fav_icon.hide()
	
	if type >= 4:
		# Que no se muestre para objetos de habitación
		_btn_open.hide()
	
	connect('gui_input', self, 'select')
	_menu_popup.connect('id_pressed', self, '_menu_item_pressed')
	_btn_open.connect('pressed', self, '_open')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func select(event: InputEvent) -> void:
	var mouse_event: = event as InputEventMouseButton
	if mouse_event\
	and mouse_event.button_index == BUTTON_LEFT and mouse_event.pressed:
		emit_signal('clicked', self)
		_label.add_color_override('font_color', SELECTED_FONT_COLOR)


func unselect() -> void:
	_label.add_color_override('font_color', _dflt_font_color)


func show_add_to_core() -> void:
	_menu_popup.set_item_disabled(0, false)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _create_menu() -> void:
	_menu_popup.clear()
	
	for option in _menu_cfg:
		if option:
			if option.has('types') and not type in option.types: continue
			
			_menu_popup.add_icon_item(
				option.icon,
				option.label,
				option.id
			)
		else:
			_menu_popup.add_separator()


func _menu_item_pressed(id: int) -> void:
	match id:
		MenuOptions.ADD_TO_CORE:
			_add_object_to_core()
		MenuOptions.SET_AS_MAIN:
			main_dock.set_main_scene(path)
			self.is_main = true
		MenuOptions.DELETE:
			_ask_basic_delete()


# Agrega este objeto (representado por una fila en una de las categorías de la
# sección Main en el dock de Popochiu) al núcleo del plugin (Popochiu.tscn) para
# que pueda ser usado (p. ej. Que se pueda navegar a la habitación, que se pueda
# mostrar a un personaje en una habitación, etc.).
func _add_object_to_core() -> void:
	var popochiu: Popochiu = main_dock.get_popochiu()
	var target_array := ''
	var resource: Resource
	
	if path.find('.tscn') > -1:
		resource = load(path.replace('.tscn', '.tres'))
	else:
		resource = load(path)
	
	match type:
		main_dock.Types.ROOM:
			target_array = 'rooms'
		main_dock.Types.CHARACTER:
			target_array = 'characters'
		main_dock.Types.INVENTORY_ITEM:
			target_array = 'inventory_items'
		main_dock.Types.DIALOG:
			target_array = 'dialogs'
		_:
			# TODO: Mostrar un mensaje de error o algo.
			return
	
	if popochiu[target_array].empty():
		popochiu[target_array] = [resource]
	else:
		popochiu[target_array].append(resource)
	
	if main_dock.save_popochiu() != OK:
		push_error('[Popochiu] Could not add Object to Popochiu: %s' %\
		name)
		return
	
	_menu_popup.set_item_disabled(0, true)
#	_btn_add.hide()


# Selecciona el archivo principal del objeto en el FileSystem y lo abre para que
# pueda ser editado.
func _open() -> void:
	main_dock.ei.select_file(path)
	if path.find('.tres') < 0:
		main_dock.ei.open_scene_from_path(path)
	else:
		main_dock.ei.edit_resource(load(path))


# Abre un popup de confirmación para saber si la desarrolladora quiere eliminar
# el objeto del núcleo del plugin y del sistema.
func _ask_basic_delete() -> void:
	# Escanear la carpeta en busca de archivos de audio y AudioCues para informar
	# a la desarrolladora que también se eliminarán archivos de audio.
	var audio_files := _search_audio_files(
		main_dock.fs.get_filesystem_path(path.get_base_dir())
	)
	
	main_dock.show_confirmation(
		'Remove %s from Popochiu' % name,
		'This will remove the [b]%s[/b] resource in Popochiu.' % name +\
		' Uses of this object in scripts will not work anymore.' +\
		' This action cannot be reversed. Continue?',
		'Delete [b]%s[/b] folder too?' % path.get_base_dir() +\
		(' ([b]%d[/b] audio files will be deleted' % audio_files.size()\
		if audio_files.size() > 0\
		else '') +\
		' (cannot be reversed))'
	)
	
	_delete_dialog.connect('confirmed', self, '_delete_from_core')
	_delete_dialog.get_cancel().connect('pressed', self, '_disconnect_popup')
	_delete_dialog.get_close_button().connect(
		'pressed', self, '_disconnect_popup'
	)


func _search_audio_files(dir: EditorFileSystemDirectory) -> Array:
	var files := []
#	var paths_to_erase := []
	
	for idx in dir.get_subdir_count():
		files.append_array(_search_audio_files(dir.get_subdir(idx)))
	
	for idx in dir.get_file_count():
		match dir.get_file_type(idx):
			'AudioStreamOGGVorbis', 'AudioStreamMP3', 'AudioStreamSample':
				files.append(dir.get_file_path(idx))
#			'Resource':
#				var resource: Resource = load(dir.get_file_path(idx))
#				if resource is AudioCue:
#					files.append(dir.get_file_path(idx))
#					paths_to_erase.append(resource.audio.resource_path)
	
#	if path in paths_to_erase:
#		files.erase(path)
	
	return files


func _delete_from_core() -> void:
	# Eliminar el objeto de Popochiu -------------------------------------------
	var popochiu: Popochiu = main_dock.get_popochiu()
	
	match type:
		main_dock.Types.ROOM:
			for r in popochiu.rooms:
				if (r as PopochiuRoomData).script_name == name:
					popochiu.rooms.erase(r)
					break
		main_dock.Types.CHARACTER:
			for c in popochiu.characters:
				if (c as PopochiuCharacterData).script_name == name:
					popochiu.characters.erase(c)
					break
		main_dock.Types.INVENTORY_ITEM:
			for ii in popochiu.inventory_items:
				if (ii as PopochiuInventoryItemData).script_name == name:
					popochiu.inventory_items.erase(ii)
					break
		main_dock.Types.DIALOG:
			for d in popochiu.dialogs:
				if (d as PopochiuDialog).script_name == name:
					popochiu.dialogs.erase(d)
					break
	
	if main_dock.save_popochiu() != OK:
		push_error('[Popochiu] Could not remove Object from Popochiu: %s' %\
		name)
		# TODO: Mostrar retroalimentación en el mismo popup
	
	if _delete_all_checkbox.pressed:
		_delete_from_file_system()
	else:
		show_add_to_core()
	
	_disconnect_popup()


# Elimina el directorio del objeto del sistema.
func _delete_from_file_system() -> void:
	# Eliminar la carpeta del disco y todas sus subcarpetas y archivos si la
	# desarrolladora así lo quiso
	var object_dir: EditorFileSystemDirectory = \
		main_dock.fs.get_filesystem_path(path.get_base_dir())
	
	# Eliminar primero los archivos y subcarpetas (con sus respectivos archivos)
	assert(
		_recursive_delete(object_dir) == OK,
		'[Popochiu] Error in recursive elimination of %s' % path.get_base_dir()
	)
	
	# Eliminar la carpeta del objeto
	assert(
		main_dock.dir.remove(path.get_base_dir()) == OK,
		'[Popochiu] Could not delete folder: %s' % path.get_base_dir()
	)

	# Forzar que se actualice la estructura de archivos en el EditorFileSystem
	main_dock.fs.scan()
	main_dock.fs.scan_sources()
	
	assert(
		main_dock.save_popochiu() == OK,
		'[Popochiu] Could not delete directory in filesystem: %s' % path.get_base_dir()
	)

	# Eliminar el objeto de su lista -------------------------------------------
	queue_free()


# Elimina un directorio del sistema. Para que Godot pueda eliminar un directorio,
# este tiene que estar vacío, por eso este método elimina primero los archivos
# del directorio y cada uno de sus subdirectorios.
func _recursive_delete(dir: EditorFileSystemDirectory) -> int:
	if dir.get_subdir_count() > 0:
		for folder_idx in dir.get_subdir_count():
			var subfolder := dir.get_subdir(folder_idx)
			
			# Ver si hay más carpetas dentro de la carpeta, o borrar los archivos
			# dentro de esta para luego sí eliminar la carpeta
			_recursive_delete(subfolder)
			
			# Eliminar la carpeta
			var err: int = main_dock.dir.remove(subfolder.get_path())
			if err != OK:
				push_error('[Popochiu(err_code:%d)] Could not delete subdirectory %s' %\
				[err, subfolder.get_path()])
				return err
	
	return _delete_files(dir)


# Elimina los archivos dentro de un directorio. Primero se obtienen las rutas
# (path) a cada archivo y luego se van eliminando, uno a uno, y llamando a
# EditorFileSystem.update_file(path: String) para que, en caso de que sea un
# archivo importado, se elimine su .import.
func _delete_files(dir: EditorFileSystemDirectory) -> int:
	# Este arreglo guardará las rutas de los archivos a eliminar.
	var files_paths := []
	var deleted_audios := []
	
	for file_idx in dir.get_file_count():
		match dir.get_file_type(file_idx):
			'AudioStreamOGGVorbis', 'AudioStreamMP3', 'AudioStreamSample':
				deleted_audios.append(dir.get_file_path(file_idx))
			'Resource':
				var resource: Resource = load(dir.get_file_path(file_idx))
				if resource is AudioCue:
					deleted_audios.append(resource.audio.resource_path)
					
					# Si el archivo es un AudioCue, hay que primero sacarlo del
					# AudioManager
					var am: Node = main_dock.get_audio_tab().get_audio_manager()
					
					if am.mx_cues.has(resource):
						am.mx_cues.erase(resource)
					elif am.sfx_cues.has(resource):
						am.sfx_cues.erase(resource)
					elif am.vo_cues.has(resource):
						am.vo_cues.erase(resource)
					elif am.ui_cues.has(resource):
						am.ui_cues.erase(resource)
					
					assert(
						main_dock.get_audio_tab().save_audio_manager() == OK,
						'[Popochiu] Could not save AudioManager after' +\
						' attempting to delete AudioCue during deletion of' +\
						' directory %s.' % dir.get_path()
					)
		
		files_paths.append(dir.get_file_path(file_idx))
	
	for fp in files_paths:
		# Así es como se hace en el código fuente del motor para que se eliminen
		# también los .import asociados a los archivos importados. ------------
		var err: int = main_dock.dir.remove(fp)
		main_dock.fs.update_file(fp)
		# ---------------------------------------------------------------------
		if err != OK:
			push_error('[Popochiu(err_code:%d)] Could not delete file %s' %\
			[err, fp])
			return err
	
	# Eliminar las filas en la pestaña de Audio de los archivos de audio y los
	# AudioCue eliminados.
	if not deleted_audios.empty():
		main_dock.get_audio_tab().delete_rows(deleted_audios)
	
	return OK


# Se desconecta de las señales del popup utilizado para configurar la eliminación.
func _disconnect_popup() -> void:
	_delete_dialog.disconnect('confirmed', self, '_delete_from_core')
	_delete_dialog.get_cancel().disconnect('pressed', self, '_disconnect_popup')
	_delete_dialog.get_close_button().disconnect(
		'pressed', self, '_disconnect_popup'
	)


func _set_main_dock(value: Panel) -> void:
	main_dock = value
	_delete_dialog = main_dock.delete_dialog
	_delete_all_checkbox = _delete_dialog.find_node('CheckBox')


func _set_is_main(value: bool) -> void:
	is_main = value
	_fav_icon.visible = value
	_menu_popup.set_item_disabled(MenuOptions.SET_AS_MAIN, value)
