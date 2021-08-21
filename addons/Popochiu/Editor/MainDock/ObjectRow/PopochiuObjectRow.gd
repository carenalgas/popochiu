tool
class_name PopochiuObjectRow
extends HBoxContainer

var type := ''
var path := ''
var main_dock setget _set_main_dock

var _confirmation_dialog: ConfirmationDialog
var _delete_all_checkbox: CheckBox

onready var _label: Label = find_node('Label')
onready var _add_to_core: Button = find_node('AddToCore')
onready var _open: Button = find_node('Open')
onready var _delete_from_core: Button = find_node('Delete')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_label.text = name
	_add_to_core.hide()
	
	_add_to_core.connect('pressed', self, '_add_object_to_core')
	_open.connect('pressed', self, '_open')
	_delete_from_core.connect('pressed', self, '_ask_basic_delete')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func show_add_to_core() -> void:
	_add_to_core.show()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
# Agrega este objeto (representado por una fila en una de las categorías de la
# sección Main en el dock de Popochiu) al núcleo del plugin (Popochiu.tscn) para
# que pueda ser usado (p. ej. Que se pueda navegar a la habitación, que se pueda
# mostrar a un personaje en una habitación, etc.).
func _add_object_to_core() -> void:
	var popochiu: Popochiu = main_dock.get_popochiu()
	
	match type:
		'character', 'room', 'inventory_item':
			if popochiu.characters.empty():
				popochiu.characters = [load(path.replace('.tscn', '.tres'))]
			else:
				popochiu.characters.append(load(path.replace('.tscn', '.tres')))
		'dialog':
			if popochiu.dialogs.empty():
				popochiu.dialogs = [load(path)]
			else:
				popochiu.dialogs.append(load(path))
	
	if main_dock.save_popochiu() != OK:
		push_error('No se pudo agregar el objeto a Popochiu: %s' %\
		name)
		return
	
	_add_to_core.hide()


# Selecciona el archivo principal del objeto en el FileSystem y lo abre para que
# pueda ser editado.
func _open() -> void:
	main_dock.ei.select_file(path)
	if path.find('.tres') < 0:
		main_dock.ei.open_scene_from_path(path)
	else:
		main_dock.ei.edit_resource(load(path))


# Crea un popup de confirmación para saber si la desarrolladora quiere eliminar
# el objeto del núcleo del plugin y del sistema.
func _ask_basic_delete() -> void:
	main_dock.show_confirmation(
		'Se eliminará a %s de Popochiu' % name,
		'Esto eliminará la referencia de [b]%s[/b] en Popochiu.' % name +\
		' Los usos de este objeto dentro de los scripts dejarán de funcionar.' +\
		' Esta acción no se puede revertir. ¿Quiere continuar?',
		'Eliminar también la carpeta [b]%s[/b]' % path.get_base_dir() +\
		' (no se puede revertir)'
	)
	
	_confirmation_dialog.get_cancel().connect('pressed', self, '_remove_popup')
	_confirmation_dialog.connect('confirmed', self, '_delete_from_core')


func _delete_from_core() -> void:
	_confirmation_dialog.disconnect('confirmed', self, '_delete_from_core')
	
	# Eliminar el objeto de Popochiu -------------------------------------------
	var popochiu: Popochiu = main_dock.get_popochiu()
	
	match type:
		'room':
			for r in popochiu.rooms:
				if (r as PopochiuRoomData).script_name == name:
					popochiu.rooms.erase(r)
					break
		'character':
			for c in popochiu.characters:
				if (c as PopochiuCharacterData).script_name == name:
					popochiu.characters.erase(c)
					break
		'inventory_item':
			for ii in popochiu.inventory_items:
				if (ii as PopochiuInventoryItemData).script_name == name:
					popochiu.inventory_items.erase(ii)
					break
		'dialog':
			for d in popochiu.dialogs:
				if (d as PopochiuDialog).script_name == name:
					popochiu.dialogs.erase(d)
					break
	
	if main_dock.save_popochiu() != OK:
		push_error('No se pudo eliminar el objeto de Popochiu: %s' %\
		name)
		# TODO: Mostrar retroalimentación en el mismo popup
	
	if _delete_all_checkbox.pressed:
		_delete_from_file_system()


# Elimina el directorio del objeto del sistema.
func _delete_from_file_system() -> void:
#	_confirmation_dialog.disconnect('confirmed', self, '_delete_from_file_system')
	
	# Eliminar la carpeta del disco y todas sus subcarpetas y archivos si la
	# desarrolladora así lo quiso
	var object_dir: EditorFileSystemDirectory = \
		main_dock.fs.get_filesystem_path(path.get_base_dir())
	
	if _recursive_delete(object_dir) != OK:
		push_error('Hubo un error en la eliminación recursiva de %s' \
		% path.get_base_dir())
		return

	# Eliminar la carpeta del objeto
	if main_dock.dir.remove(path.get_base_dir()) != OK:
		push_error('No se pudo eliminar la carpeta: %s' %\
		main_dock.characters_path + name)
		return

	# Forzar que se actualice la estructura de archivos en el EditorFileSystem
	main_dock.fs.scan()
	main_dock.fs.scan_sources()

	# Eliminar el objeto de su lista -------------------------------------------
	_remove_popup()
	queue_free()


# Elimina un directorio del sistema. Para que Godot pueda eliminar un directorio,
# este tiene que estar vacío, por eso este método elimina primero los archivos
# del directorio y cada uno de sus subdirectorios.
func _recursive_delete(dir: EditorFileSystemDirectory) -> int:
	if dir.get_subdir_count():
		for folder_idx in dir.get_subdir_count():
			var subfolder := dir.get_subdir(folder_idx)

			_recursive_delete(subfolder)

			var err: int = main_dock.dir.remove(subfolder.get_path())
			if err != OK:
				push_error('[%d] No se pudo eliminar el subdirectorio %s' %\
				[err, subfolder.get_path()])
				return err
	
	return _delete_files(dir)


# Elimina los archivos dentro de un directorio. Primero se obtienen las rutas
# (path) a cada archivo y luego se van eliminando, uno a uno, y llamando a
# EditorFileSystem.update_file(path: String) para que, en caso de que sea un
# archivo importado, se elimine su .import.
func _delete_files(dir: EditorFileSystemDirectory) -> int:
	var files_paths := []
	
	for file_idx in dir.get_file_count():
		files_paths.append(dir.get_file_path(file_idx))

	for fp in files_paths:
		# Así es como se hace en el código fuente del motor para que se eliminen
		# también los .import asociados a los archivos importados. ------------
		var err: int = main_dock.dir.remove(fp)
		main_dock.fs.update_file(fp)
		# ---------------------------------------------------------------------
		if err != OK:
			push_error('[%d] No se pudo eliminar el archivo %s' %\
			[err, fp])
			return err

	main_dock.fs.scan()
	main_dock.fs.scan_sources()

	return OK


# Elimina el popup de confirmación creado para verificar que la desarrolladora
# está segura de eliminar lo que quiere eliminar.
func _remove_popup() -> void:
	if _confirmation_dialog.is_connected('confirmed', self, '_delete_from_core'):
		_confirmation_dialog.disconnect('confirmed', self, '_delete_from_core')
	
	if _confirmation_dialog.is_connected('confirmed', self, '_delete_from_file_system'):
		# Se canceló la eliminación de los archivos en disco
		_add_to_core.show()
		_confirmation_dialog.disconnect('confirmed', self, '_delete_from_file_system')


func _set_main_dock(value: Panel) -> void:
	main_dock = value
	_confirmation_dialog = value.delete_confirmation
	_delete_all_checkbox = _confirmation_dialog.find_node('CheckBox')
