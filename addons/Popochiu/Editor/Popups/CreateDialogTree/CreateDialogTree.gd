tool
extends CreationPopup
# Permite crear un nuevo diálogo con los archivos necesarios para que funcione
# en el Popochiu: DialogDDD.gd, DialogDDD.tres.

const DIALOG_SCRIPT_TEMPLATE := 'res://script_templates/DialogTemplate.gd'

var _new_dialog_name := ''
var _new_dialog_path := ''
var _dialog_path_template: String


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func set_main_dock(node: PopochiuDock) -> void:
	.set_main_dock(node)
	# Por defecto: res://src/Dialogs
	_dialog_path_template = _main_dock.dialogs_path + '%s/Dialog%s'


func create() -> void:
	if not _new_dialog_name:
		_error_feedback.show()
		return
	
	# TODO: Verificar si no hay ya un diálogo en el mismo PATH.
	# TODO: Eliminar archivos creados si la creación no se completa.
	
	# Crear el directorio donde se guardará el nuevo diálogo -------------------
	_main_dock.dir.make_dir(_main_dock.dialogs_path + _new_dialog_name)

	# Crear el script del nuevo diálogo ----------------------------------------
	var dialog_template := load(DIALOG_SCRIPT_TEMPLATE)
	if ResourceSaver.save(_new_dialog_path + '.gd', dialog_template) != OK:
		push_error('No se pudo crear el script: %s.gd' % _new_dialog_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# Crear el Resource del diálogo --------------------------------------------
	var dialog_resource := PopochiuDialog.new()
	dialog_resource.set_script(load(_new_dialog_path + '.gd'))
	dialog_resource.script_name = _new_dialog_name
	dialog_resource.resource_name = _new_dialog_name
	if ResourceSaver.save(_new_dialog_path + '.tres', dialog_resource) != OK:
		push_error('No se pudo crear el Resource: %s' %_new_dialog_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return

	# Agregar el diálogo al Popochiu -------------------------------------------
	var gaq: Node = ResourceLoader.load(_main_dock.POPOCHIU_SCENE).instance()
	gaq.dialogs.append(ResourceLoader.load(_new_dialog_path + '.tres'))
	var new_gaq: PackedScene = PackedScene.new()
	new_gaq.pack(gaq)
	if ResourceSaver.save(_main_dock.POPOCHIU_SCENE, new_gaq) != OK:
		push_error('No se pudo agregar el diálogo a GAQ: %s' %\
		_new_dialog_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	_main_dock.ei.reload_scene_from_path(_main_dock.POPOCHIU_SCENE)
	
	# Actualizar la lista de habitaciones en el Dock ---------------------------
	_main_dock.add_to_list('dialog', _new_dialog_name)

	# Abrir el diálogo en el Inspector -----------------------------------------
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.select_file(_new_dialog_path + '.tres')
	_main_dock.ei.edit_resource(load(_new_dialog_path + '.tres'))

	# Fin
	hide()

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _update_name(new_text: String) -> void:
	._update_name(new_text)

	if _name:
		_new_dialog_name = _name
		_new_dialog_path = _dialog_path_template %\
		[_new_dialog_name, _new_dialog_name]

		_info.bbcode_text = (
			'En [b]%s[/b] se crearán los archivos:\n[code]%s y %s[/code]' \
			% [
				_main_dock.dialogs_path + _new_dialog_name,
				'Dialog' + _new_dialog_name + '.gd',
				'Dialog' + _new_dialog_name + '.tres'
			])
	else:
		_info.clear()


func _clear_fields() -> void:
	._clear_fields()
	
	_new_dialog_name = ''
	_new_dialog_path = ''
