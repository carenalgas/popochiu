tool
class_name PopochiuObjectRow
extends HBoxContainer

var type := ''
var path := ''
var main_dock
var confirmation_dialog: ConfirmationDialog

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
func _add_object_to_core() -> void:
#	var popochiu: Popochiu = main_dock.get_popochiu()
	var popochiu: Popochiu = load(main_dock.POPOCHIU_SCENE).instance()
	
	match type:
		'character':
			if popochiu.characters.empty():
				popochiu.characters = [load(path.replace('.tscn', '.tres'))]
			else:
				popochiu.characters.append(load(path.replace('.tscn', '.tres')))
		'dialog':
			if popochiu.dialogs.empty():
				popochiu.dialogs = [load(path)]
			else:
				popochiu.dialogs.append(load(path))

	var new_popochiu: PackedScene = PackedScene.new()
	new_popochiu.pack(popochiu)
	if ResourceSaver.save(main_dock.POPOCHIU_SCENE, new_popochiu) != OK:
		push_error('No se pudo agregar el objeto a Popochiu: %s' %\
		name)
		return
	main_dock.ei.reload_scene_from_path(main_dock.POPOCHIU_SCENE)
	
#	if main_dock.save_popochiu() != OK:
#		push_error('No se pudo agregar el objeto a Popochiu: %s' %\
#		name)
#		return
	
	_add_to_core.hide()


func _open() -> void:
	main_dock.ei.select_file(path)
	if path.find('.tres') < 0:
		main_dock.ei.open_scene_from_path(path)
	else:
		main_dock.ei.edit_resource(load(path))


func _ask_basic_delete() -> void:
	confirmation_dialog = ConfirmationDialog.new()

	confirmation_dialog.window_title = 'Se eliminará a %s de Popochiu' % name
	confirmation_dialog.dialog_text = \
	'Esto sólo eliminará la referencia en Popochiu. Los usos de este objeto ' +\
	'dentro de los scripts dejarán de funcionar.\n' +\
	'Esta acción no se puede revertir. ¿Quiere continuar?'
	confirmation_dialog.dialog_autowrap = true

	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered_clamped(Vector2(640, 180))
	confirmation_dialog.get_cancel().connect('pressed', self, '_remove_popup')
	confirmation_dialog.connect('confirmed', self, '_delete_from_core')


func _delete_from_core() -> void:
	confirmation_dialog.disconnect('confirmed', self, '_delete_from_core')
	
	# Eliminar el objeto de Popochiu -------------------------------------------
	var popochiu: Popochiu = main_dock.get_popochiu()
	
	match type:
		'character':
			for c in popochiu.characters:
				if (c as PopochiuCharacterData).script_name == name:
					popochiu.characters.erase(c)
					break
	
	if main_dock.save_popochiu() != OK:
		push_error('No se pudo eliminar el objeto de Popochiu: %s' %\
		name)
		# TODO: Mostrar retroalimentación en el mismo popup
	
	confirmation_dialog.window_title = 'Se eliminará la carpeta %s' % path.get_base_dir()
	confirmation_dialog.dialog_text = \
	'Esto eliminará todas las subcarpetas y archivos en %s.\n' +\
	'Esta acción no se puede revertir. ¿Quiere continuar?'
	
	confirmation_dialog.connect('confirmed', self, '_delete_from_file_system')
	confirmation_dialog.popup_centered_clamped(Vector2(640, 180))
	


func _delete_from_file_system() -> void:
	confirmation_dialog.disconnect('confirmed', self, '_delete_from_file_system')
#	yield(get_tree().create_timer(0.1), 'timeout')
	
	# Eliminar la carpeta del disco y todos sus archivos si la usuario así lo
	# quiso
	match type:
		'character':
			# Eliminar todos los archivos dentro de la carpeta
			var object_dir: EditorFileSystemDirectory = \
				main_dock.fs.get_filesystem_path(path.get_base_dir())
			
			if object_dir.get_subdir_count():
				pass

				# Ir por las subcarpetas eliminando los archivos
	#			for idx in object_dir.get_subdir_count():
	#				var dir: EditorFileSystemDirectory = type_dir.get_subdir(idx)
	#
	#				for f in dir.get_file_count():
			else:
				for file_idx in object_dir.get_file_count():
					var path: String = object_dir.get_file_path(file_idx)
					main_dock.dir.remove(path)

			# Eliminar la carpeta del objeto
			if main_dock.dir.remove(path.get_base_dir()) != OK:
				push_error('No se pudo eliminar la carpeta: %s' %\
				main_dock.characters_path + name)
				return

	# Forzar que se actualice la estructura de archivos en el EditorFileSystem
	main_dock.fs.scan()

	# Eliminar el objeto de su lista -------------------------------------------
	_remove_popup()
	queue_free()


func _remove_popup() -> void:
	if confirmation_dialog.is_connected('confirmed', self, '_delete_from_core'):
		confirmation_dialog.disconnect('confirmed', self, '_delete_from_core')
	
	if confirmation_dialog.is_connected('confirmed', self, '_delete_from_file_system'):
		# Se canceló la eliminación de los archivos en disco
		_add_to_core.show()
		confirmation_dialog.disconnect('confirmed', self, '_delete_from_file_system')
	
	confirmation_dialog.queue_free()
