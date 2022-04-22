tool
extends 'res://addons/Popochiu/Editor/Popups/CreationPopup.gd'
# Permite crear una nueva Prop para una habitación. De tener interacción, se le
# asignará un script que quedará guardado en la carpeta Props de la carpeta de
# la habitación a la que pertenece.

const PROP_SCRIPT_TEMPLATE := 'res://addons/Popochiu/Engine/Templates/PropTemplate.gd'
const BASE_PROP_PATH := 'res://addons/Popochiu/Engine/Objects/Prop/PopochiuProp.tscn'
const Constants := preload('res://addons/Popochiu/Constants.gd')

var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_prop_name := ''
var _new_prop_path := ''
var _prop_path_template: String
var _room_path: String
var _room_dir: String

onready var _interaction_checkbox: CheckBox = find_node('InteractionCheckbox')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
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
	
	# TODO: Check if another Prop was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	var script_path := _new_prop_path + '.gd'
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	if _interaction_checkbox.pressed:
		# Create the folder for the Prop
		assert(
			_main_dock.dir.make_dir_recursive(_new_prop_path.get_base_dir()) == OK,
			'[Popochiu] Could not create Prop folder for ' + _new_prop_name
		)
	elif not _main_dock.dir.dir_exists(_room_dir + '/Props/'):
		# If the Prop doesn't have interaction, just try to create the Props
		# folder to store there the assets that will be used by the Prop
		assert(
			_main_dock.dir.make_dir_recursive(_room_dir + '/Props/') == OK,
			'[Popochiu] Could not create Props folder for ' + _room_path.get_file()
		)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el script de la prop (si tiene interacción)
	if _interaction_checkbox.pressed:
		var prop_template := load(PROP_SCRIPT_TEMPLATE)
		if ResourceSaver.save(script_path, prop_template) != OK:
			push_error('[Popochiu] Could not create script: %s.gd' % _new_prop_name)
			# TODO: Mostrar retroalimentación en el mismo popup
			return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear la prop a agregar a la habitación
	var prop: PopochiuProp = ResourceLoader.load(BASE_PROP_PATH).instance()
	if _interaction_checkbox.pressed:
		prop.set_script(ResourceLoader.load(script_path))
	prop.name = _new_prop_name
	prop.script_name = _new_prop_name
	prop.description = _new_prop_name
	prop.clickable = _interaction_checkbox.pressed
	prop.cursor = Constants.CURSOR_TYPE.ACTIVE
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Agregar la prop a su habitación
	_room.get_node('Props').add_child(prop)
	prop.owner = _room
	_main_dock.ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of Props in the Room tab
	if _interaction_checkbox.pressed:
		room_tab.add_to_list(
			Constants.Types.PROP,
			_new_prop_name,
			script_path
		)
	else:
		room_tab.add_to_list(Constants.Types.PROP, _new_prop_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir las propiedades de la prop creada en el Inspector
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.edit_node(prop)
	
	if _interaction_checkbox.pressed:
		_main_dock.ei.select_file(script_path)
	else:
		_main_dock.ei.select_file(_room_path)
	
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
		'In [b]%s[/b] the following file will be created: [code]%s[/code]' \
		% [
			_new_prop_path.get_base_dir(),
			'Prop' + _new_prop_name + '.gd'
		]
	)
