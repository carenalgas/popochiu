@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'
# Permite crear una nueva Region para una habitación.

const SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/region_template.gd'
const REGION_SCENE := 'res://addons/popochiu/engine/objects/region/popochiu_region.tscn'
const Constants := preload('res://addons/popochiu/popochiu_resources.gd')

var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_region_name := ''
var _new_region_path := ''
var _region_path_template := ''
var _room_path := ''
var _room_dir := ''
var _pascal_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _create() -> void:
	if _new_region_name.is_empty():
		_error_feedback.show()
		return
	
	# TODO: Check if another Region was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	var script_path := _new_region_path + '.gd'
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the Region
	assert(
		DirAccess.make_dir_recursive_absolute(
			_new_region_path.get_base_dir()
		) == OK,
		'[Popochiu] Could not create region folder for ' + _new_region_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el script de la región
	var region_template := load(SCRIPT_TEMPLATE)
	if ResourceSaver.save(region_template, script_path) != OK:
		push_error(
			"[Popochiu] Couldn't create script: %s.gd" % _new_region_name
		)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear la región a agregar a la habitación
	var region: PopochiuRegion = ResourceLoader.load(REGION_SCENE).instantiate()
	region.set_script(ResourceLoader.load(script_path))
	region.name = _pascal_name
	region.script_name = _pascal_name
	region.description = _new_region_name.capitalize()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Agregar la región a su habitación
	_room.get_node('Regions').add_child(region)
	region.owner = _room
	region.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0
	
	var collision := CollisionPolygon2D.new()
	collision.name = 'InteractionPolygon'
	region.add_child(collision)
	collision.owner = _room
	collision.modulate = Color.CYAN
	
	_main_dock.ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of Regions in the Room tab
	room_tab.add_to_list(
		Constants.Types.REGION,
		_pascal_name,
		script_path
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir las propiedades de la región creada en el Inspector
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.edit_node(region)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Fin
	hide()


func _clear_fields() -> void:
	_new_region_name = ''
	_new_region_path = ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func room_opened(r: Node2D) -> void:
	_room = r
	_room_path = _room.scene_file_path
	_room_dir = _room_path.get_base_dir()
	_region_path_template = _room_dir + '/regions/%s/region_%s'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_region_name = _name.to_snake_case()
		_pascal_name = _name
		_new_region_path = _region_path_template %\
		[_new_region_name, _new_region_name]

		_info.text = (
			'In [b]%s[/b] the following files will be created:\n[code]%s[/code]' \
			% [
				_room_dir + '/regions',
				'region_' + _new_region_name + '.gd'
			]
		)
		_info.show()
	else:
		_info.clear()
		_info.hide()
