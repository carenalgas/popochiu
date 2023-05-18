@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'
# Permite crear un nuevo Hotspot para una habitación.

const SCRIPT_TEMPLATE :=\
'res://addons/popochiu/engine/templates/hotspot_template.gd'
const HOTSPOT_SCENE :=\
'res://addons/popochiu/engine/objects/hotspot/popochiu_hotspot.tscn'
const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const TabRoom := preload("res://addons/popochiu/editor/main_dock/tab_room.gd")

var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_hotspot_name := ''
var _new_hotspot_path := ''
var _hotspot_path_template := ''
var _room_path := ''
var _room_dir := ''
var _pascal_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _create() -> void:
	if _new_hotspot_name.is_empty():
		_error_feedback.show()
		return
	
	# TODO: Check if another Hotspot was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	var script_path := _new_hotspot_path + '.gd'
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the Hotspot
	assert(
		DirAccess.make_dir_recursive_absolute(
			_new_hotspot_path.get_base_dir()
		) == OK,
		'[Popochiu] Could not create Hotspot folder for ' + _new_hotspot_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el script de el hotspot (si tiene interacción)
	var hotspot_template := load(SCRIPT_TEMPLATE)
	if ResourceSaver.save(hotspot_template, script_path) != OK:
		push_error('[Popochiu] Could not create: %s.gd' % _new_hotspot_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el hotspot a agregar a la habitación
	var hotspot: PopochiuHotspot = ResourceLoader.load(HOTSPOT_SCENE).instantiate()
	hotspot.set_script(ResourceLoader.load(script_path))
	hotspot.name = _pascal_name
	hotspot.script_name = _pascal_name
	hotspot.description = _new_hotspot_name.capitalize()
	hotspot.cursor = Constants.CURSOR_TYPE.ACTIVE
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Agregar el hotspot a su habitación
	_room.get_node('Hotspots').add_child(hotspot)
	
	hotspot.owner = _room
	hotspot.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0
	
	var collision := CollisionPolygon2D.new()
	collision.name = 'InteractionPolygon'
	hotspot.add_child(collision)
	collision.owner = _room
	collision.modulate = Color.BLUE
	
	_main_dock.ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of Hotspots in the Room tab
	(room_tab as TabRoom).add_to_list(
		Constants.Types.HOTSPOT,
		_pascal_name,
		script_path
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir las propiedades del hotspot creado en el Inspector
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.edit_node(hotspot)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Fin
	hide()


func _clear_fields() -> void:
	_new_hotspot_name = ''
	_new_hotspot_path = ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func room_opened(r: Node2D) -> void:
	_room = r
	_room_path = _room.scene_file_path
	_room_dir = _room_path.get_base_dir()
	_hotspot_path_template = _room_dir + '/hotspots/%s/hotspot_%s'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_hotspot_name = _name.to_snake_case()
		_pascal_name = _name
		_new_hotspot_path = _hotspot_path_template %\
		[_new_hotspot_name, _new_hotspot_name]

		_info.text = (
			'In [b]%s[/b] the following file will be created:\n[code]%s[/code]'\
			% [
				_new_hotspot_path.get_base_dir(),
				'hotspot_' + _new_hotspot_name + '.gd'
			]
		)
		_info.show()
	else:
		_info.clear()
		_info.hide()
