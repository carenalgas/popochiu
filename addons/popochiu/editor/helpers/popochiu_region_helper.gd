extends 'res://addons/popochiu/editor/helpers/popochiu_room_obj_base_helper.gd'
class_name PopochiuRegionHelper

const BASE_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/region_template.gd'
const BASE_OBJ_PATH := 'res://addons/popochiu/engine/objects/region/popochiu_region.tscn'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_path_template = '/regions/%s/region_%s'


func create(obj_name: String, room: PopochiuRoom) -> PopochiuRegion:
	_open_room(room)
	_setup_name(obj_name)

	# TODO: Check if another Region was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	var script_path := _obj_path + '.gd'
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the Region
	assert(
		DirAccess.make_dir_recursive_absolute(
			_obj_path.get_base_dir()
		) == OK,
		'[Popochiu] Could not create region folder for ' + _obj_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el script de la región
	var obj_template := load(BASE_SCRIPT_TEMPLATE)

	if ResourceSaver.save(obj_template, script_path) != OK:
		push_error(
			"[Popochiu] Couldn't create script: %s.gd" % _obj_name
		)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear la región a agregar a la habitación
	var obj: PopochiuRegion = ResourceLoader.load(BASE_OBJ_PATH).instantiate()
	obj.set_script(ResourceLoader.load(script_path))
	obj.name = _obj_name
	obj.script_name = _obj_name
	obj.description = _obj_script_name.capitalize()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Agregar la región a su habitación
	_room.get_node('Regions').add_child(obj)
	obj.owner = _room
	obj.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0
	
	var collision := CollisionPolygon2D.new()
	collision.name = 'InteractionPolygon'
	obj.add_child(collision)
	collision.owner = _room
	collision.modulate = Color.CYAN
	
	_ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of Regions in the Room tab
	(_room_tab as TabRoom).add_to_list(
		Constants.Types.REGION,
		_obj_name,
		script_path
	)

	return obj
