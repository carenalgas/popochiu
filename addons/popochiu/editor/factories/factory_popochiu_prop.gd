extends 'res://addons/popochiu/editor/factories/factory_base_popochiu_room_obj.gd'
class_name PopochiuPropFactory

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func _init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_type = Constants.Types.PROP
	_obj_type_label = 'prop'
	_obj_room_group = 'Props'
	_obj_path_template = '/props/%s/prop_%s'


func create(obj_name: String, room: PopochiuRoom, is_interactive:bool = false) -> int:
	# If everything goes well, this won't change.
	var result_code := ResultCodes.SUCCESS

	_setup_room(room)
	_setup_name(obj_name)

	# Create the folder for the Prop
	result_code = _create_obj_folder()
	if result_code != ResultCodes.SUCCESS: return result_code

	# Create the script for the prop (if it has interaction)
	if is_interactive:
		result_code = _copy_script_template()
		if result_code != ResultCodes.SUCCESS: return result_code
		
	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the prop instance
	var new_obj: PopochiuProp = _load_obj_base_scene()
	
	if is_interactive:
		new_obj.set_script(ResourceLoader.load(_obj_path_script))
	
	new_obj.name = _obj_pascal_name
	new_obj.script_name = _obj_pascal_name
	new_obj.description = _obj_snake_name.capitalize()
	new_obj.cursor = Constants.CURSOR_TYPE.ACTIVE
	new_obj.clickable = is_interactive
	
	if _obj_snake_name in ['bg', 'background']:
		new_obj.baseline =\
		-ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT) / 2.0
		new_obj.z_index = -1

	# Save the prop scene (.tscn) and put it into _obj_scene class property
	result_code = _save_obj_scene(new_obj)
	if result_code != ResultCodes.SUCCESS: return result_code

	# TODO: Introduce here the logic to handle children in scene
	# Add collision polygon to the prop if it's interactive
	if is_interactive:
		var collision := CollisionPolygon2D.new()
		collision.name = 'InteractionPolygon'
		_add_visible_child(collision)

	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

	# Add the prop to its room
	_add_resource_to_room()

	return result_code
