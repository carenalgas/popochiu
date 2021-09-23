tool
extends CreationPopup
# Permite crear una nueva Prop para una habitación. De tener interacción, se le
# asignará un script que quedará guardado en la carpeta Props de la carpeta de
# la habitación a la que pertenece.

const PROP_SCRIPT_TEMPLATE := 'res://addons/Popochiu/Engine/Templates/PropTemplate.gd'
const BASE_PROP_PATH := 'res://addons/Popochiu/Engine/Objects/Prop/Prop.tscn'

var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_prop_name := ''
var _new_prop_path := ''
var _prop_path_template: String
var _room_path: String
var _room_dir: String

onready var _interaction_checkbox: CheckBox = find_node('InteractionCheckbox')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_clear_fields()
	
	_interaction_checkbox.connect('toggled', self, '_interaction_toggled')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func set_main_dock(node: PopochiuDock) -> void:
	.set_main_dock(node)


func room_opened(r: Node2D) -> void:
	_room = r
	_room_path = _room.filename
	_room_dir = _room_path.get_base_dir()
	_prop_path_template = _room_dir + '/Props/%s/Prop%s'


func create() -> void:
	if not _new_prop_name:
		_error_feedback.show()
		return
	
	# TODO: Verificar si no hay ya una prop en el mismo PATH.
	# TODO: Eliminar archivos creados si la creación no se completa.
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el directorio donde se guardará la nueva prop
	assert(
		_main_dock.dir.make_dir_recursive(_new_prop_path.get_base_dir()) == OK,
		'No se pudo crear el directorio de Props de ' + _room_path.get_file()
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el script de la prop (si tiene interacción)
	if _interaction_checkbox.pressed:
		var prop_template := load(PROP_SCRIPT_TEMPLATE)
		if ResourceSaver.save(_new_prop_path + '.gd', prop_template) != OK:
			push_error('No se pudo crear el script: %s.gd' % _new_prop_name)
			# TODO: Mostrar retroalimentación en el mismo popup
			return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear la prop a agregar a la habitación
	var prop: Prop = ResourceLoader.load(BASE_PROP_PATH).instance()
	if _interaction_checkbox.pressed:
		prop.set_script(ResourceLoader.load(_new_prop_path + '.gd'))
	prop.name = _new_prop_name
	prop.script_name = _new_prop_name
	prop.description = _new_prop_name
	prop.clickable = _interaction_checkbox.pressed
	prop.cursor = Cursor.Type.USE
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Agregar la prop a su habitación
	_room.get_node('Props').add_child(prop)
	prop.owner = _room
	_main_dock.ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Actualizar la lista de props de la habitación
	room_tab.add_to_list(room_tab.Types.PROP, _new_prop_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir las propiedades de la prop creada en el Inspector
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.edit_node(prop)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Fin
	hide()

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _update_name(new_text: String) -> void:
	._update_name(new_text)

	if _name:
		_new_prop_name = _name
		_new_prop_path = _prop_path_template % [_new_prop_name, _new_prop_name]

		if _interaction_checkbox.pressed:
			_update_info()
	else:
		_info.clear()


func _clear_fields() -> void:
	._clear_fields()
	
	_new_prop_name = ''
	_new_prop_path = ''
	_interaction_checkbox.pressed = false


func _interaction_toggled(is_pressed: bool) -> void:
	if is_pressed and _name:
		_update_info()
	else:
		_info.clear()


func _update_info() -> void:
	_info.bbcode_text = (
		'En [b]%s[/b] se creará el archivo: [code]%s[/code]' \
		% [
			_new_prop_path.get_base_dir(),
			'Prop' + _new_prop_name + '.gd'
		]
	)
