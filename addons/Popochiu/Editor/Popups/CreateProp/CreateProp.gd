@tool
extends 'res://addons/Popochiu/Editor/Popups/CreationPopup.gd'
# Permite crear una nueva Prop para una habitación. De tener interacción, se le
# asignará un script que quedará guardado en la carpeta Props de la carpeta de
# la habitación a la que pertenece.

const PROP_SCRIPT_TEMPLATE := 'res://addons/Popochiu/Engine/Templates/PropTemplate.gd'
const BASE_PROP_PATH := 'res://addons/Popochiu/Engine/Objects/Prop/PopochiuProp.tscn'
const Constants := preload('res://addons/Popochiu/PopochiuResources.gd')

var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_prop_name := ''
var _new_prop_path := ''
var _prop_path_template: String
var _room_path: String
var _room_dir: String

@onready var _interaction_checkbox: CheckBox = find_child('InteractionCheckbox')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()
	
	_interaction_checkbox.toggled.connect(_interaction_toggled)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func set_main_dock(node: Panel) -> void:
	super(node)


func room_opened(r: Node2D) -> void:
	_room = r
	_room_path = _room.scene_file_path
	_room_dir = _room_path.get_base_dir()
	_prop_path_template = _room_dir + '/Props/%s/Prop%s'


func create() -> void:
	if _new_prop_name.is_empty():
		_error_feedback.show()
		return
	
	# TODO: Check if another Prop was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	var script_path := _new_prop_path + '.gd'
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	if _interaction_checkbox.button_pressed:
		# Create the folder for the Prop
		assert(\
		DirAccess.make_dir_recursive_absolute(_new_prop_path.get_base_dir()) == OK,\
		'[Popochiu] Could not create Prop folder for ' + _new_prop_name\
		)
	elif not DirAccess.dir_exists_absolute(_room_dir + '/Props/'):
		# If the Prop doesn't have interaction, just try to create the Props
		# folder to store there the assets that will be used by the Prop
		assert(\
		DirAccess.make_dir_recursive_absolute(_room_dir + '/Props/_NoInteraction') == OK,\
		'[Popochiu] Could not create Props folder for ' + _room_path.get_file()\
		)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el script de la prop (si tiene interacción)
	if _interaction_checkbox.button_pressed:
		var prop_template := load(PROP_SCRIPT_TEMPLATE)
		if ResourceSaver.save(prop_template, script_path) != OK:
			push_error('[Popochiu] Could not create script: %s.gd' % _new_prop_name)
			# TODO: Show feedback in the popup
			return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear la prop a agregar a la habitación
	var prop: PopochiuProp = ResourceLoader.load(BASE_PROP_PATH).instantiate()
	
	if _interaction_checkbox.button_pressed:
		prop.set_script(ResourceLoader.load(script_path))
	
	prop.name = _new_prop_name
	prop.script_name = _new_prop_name
	prop.description = _new_prop_name
	prop.clickable = _interaction_checkbox.button_pressed
	prop.cursor = Constants.CURSOR_TYPE.ACTIVE
	
	if _new_prop_name in ['Bg', 'Background']:
		prop.baseline =\
		-ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT) / 2.0
		prop.z_index = -1
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Agregar la prop a su habitación
	_room.get_node('Props').add_child(prop)
	prop.owner = _room
	prop.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0
	
	if _interaction_checkbox.button_pressed:
		var collision := CollisionPolygon2D.new()
		collision.name = 'InteractionPolygon'
		prop.add_child(collision)
		collision.owner = _room
	
	_main_dock.ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of Props in the Room tab
	room_tab.add_to_list(
		Constants.Types.PROP,
		_new_prop_name,
		script_path if _interaction_checkbox.button_pressed else _room_dir + '/Props'
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir las propiedades de la prop creada en el Inspector
	_main_dock.fs.scan()
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.edit_node(prop)
	
	if _interaction_checkbox.button_pressed:
		_main_dock.ei.select_file(script_path)
	else:
		_main_dock.ei.get_file_system_dock().navigate_to_path(
			_room_dir + '/Props/_NoInteraction'
		)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Fin
	hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_prop_name = _name
		_new_prop_path = _prop_path_template % [_new_prop_name, _new_prop_name]

		if _interaction_checkbox.button_pressed:
			_update_info()
	else:
		_info.clear()


func _clear_fields() -> void:
	super()
	
	_new_prop_name = ''
	_new_prop_path = ''
	_interaction_checkbox.button_pressed = false


func _interaction_toggled(is_pressed: bool) -> void:
	if is_pressed and not _name.is_empty():
		_update_info()
	else:
		_info.clear()


func _update_info() -> void:
	_info.text = (
		'In [b]%s[/b] the following file will be created: [code]%s[/code]' \
		% [
			_new_prop_path.get_base_dir(),
			'Prop' + _new_prop_name + '.gd'
		]
	)
