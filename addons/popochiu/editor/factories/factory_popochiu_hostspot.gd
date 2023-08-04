extends 'res://addons/popochiu/editor/factories/factory_base_popochiu_room_obj.gd'
class_name PopochiuHotspotFactory

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func _init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_type = Constants.Types.HOTSPOT
	_obj_type_label = 'hotspot'
	_obj_room_group = 'Hotspots'
	_obj_path_template = '/hotspots/%s/hotspot_%s'


func create(obj_name: String, room: PopochiuRoom) -> int:
	# If everything goes well, this won't change.
	var result_code := ResultCodes.SUCCESS

	_setup_room(room)
	_setup_name(obj_name)
	
	# Create the folder
	result_code = _create_obj_folder()
	if result_code != ResultCodes.SUCCESS: return result_code
	
	# Create the script
	result_code = _copy_script_template()
	if result_code != ResultCodes.SUCCESS: return result_code

	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the instance
	var new_obj: PopochiuHotspot = _load_obj_base_scene()

	new_obj.name = _obj_pascal_name
	new_obj.script_name = _obj_pascal_name
	new_obj.description = _obj_snake_name.capitalize()
	new_obj.cursor = Constants.CURSOR_TYPE.ACTIVE

	# Save the hostspot scene (.tscn) and put it into _obj_scene class property
	result_code = _save_obj_scene(new_obj)
	if result_code != ResultCodes.SUCCESS: return result_code

	# Create a collision polygon as a child in the room scene
	var collision := CollisionPolygon2D.new()
	collision.name = 'InteractionPolygon'
	collision.modulate = Color.BLUE
	_add_visible_child(collision)
	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

	# Add the object to its room
	_add_resource_to_room()

	return result_code
