extends 'res://addons/popochiu/editor/factories/factory_base_popochiu_room_obj.gd'
class_name PopochiuRegionFactory

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func _init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_type = Constants.Types.REGION
	_obj_type_label = 'region'
	_obj_room_group = 'Regions'
	_obj_path_template = '/regions/%s/region_%s'


func create(obj_name: String, room: PopochiuRoom) -> PopochiuRegion:
	_setup_room(room)
	_setup_name(obj_name)

	# Create the folder for the Region
	if _create_obj_folder() == ResultCodes.FAILURE: return
	
	# Create the script for the Region
	if _copy_script_template() == ResultCodes.FAILURE: return

	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the region instance
	var new_obj: PopochiuRegion = _load_obj_base_scene()

	new_obj.name = _obj_name
	new_obj.script_name = _obj_name
	new_obj.description = _obj_script_name.capitalize()

	# Save the region scene (.tscn) and put it into _obj class property
	if _save_obj_scene(new_obj) == ResultCodes.FAILURE: return

	var collision := CollisionPolygon2D.new()
	collision.name = 'InteractionPolygon'
	collision.modulate = Color.CYAN
	_obj.add_child(collision)
	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

	# Add the hotspot to its room
	_add_resource_to_room()

	# This factory returns the object itself
	return _obj
