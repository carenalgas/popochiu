extends 'res://addons/popochiu/editor/factories/factory_base_popochiu_room_obj.gd'
class_name PopochiuHotspotFactory

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func _init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_type = Constants.Types.HOTSPOT
	_obj_type_label = 'hotspot'
	_obj_room_group = 'Hotspots'
	_obj_path_template = '/hotspots/%s/hotspot_%s'


func create(obj_name: String, room: PopochiuRoom) -> PopochiuHotspot:
	_setup_room(room)
	_setup_name(obj_name)
	
	# Create the folder for the Hotspot
	if _create_obj_folder() == ResultCodes.FAILURE: return
	
	# Create the script for the Hotspot
	if _copy_script_template() == ResultCodes.FAILURE: return

	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the hotspot instance
	var new_obj: PopochiuHotspot = _load_obj_base_scene()

	new_obj.name = _obj_pascal_name
	new_obj.script_name = _obj_pascal_name
	new_obj.description = _obj_snake_name.capitalize()
	new_obj.cursor = Constants.CURSOR_TYPE.ACTIVE

	# Save the hostspot scene (.tscn) and put it into _obj class property
	if _save_obj_scene(new_obj) == ResultCodes.FAILURE: return

	# Create the collision polygon for the hotspot
	var collision := CollisionPolygon2D.new()
	collision.name = 'InteractionPolygon'
	collision.modulate = Color.BLUE
	_obj.add_child(collision)
	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

	# Add the prop to its room
	_add_resource_to_room()

	# This factory returns the object scene
	return _obj
