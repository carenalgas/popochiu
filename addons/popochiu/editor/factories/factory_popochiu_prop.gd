extends 'res://addons/popochiu/editor/factories/factory_base_popochiu_room_obj.gd'
class_name PopochiuPropFactory

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_type = Constants.Types.PROP
	_obj_type_label = 'prop'
	_obj_room_group = 'Props'
	_obj_path_template = '/props/%s/prop_%s'


func create(obj_name: String, room: PopochiuRoom, is_interactive:bool = false) -> PopochiuProp:
	_setup_room(room)
	_setup_name(obj_name)

	# Create the folder for the Prop
	if _create_obj_folder() == ResultCodes.FAILURE: return

	# Create the script for the prop (if it has interaction)
	if is_interactive:
		if _copy_script_template() == ResultCodes.FAILURE: return
	
	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the prop instance (not in _obj, it will be set by _save_obj_scene()
	# at the end of the local code)
	var new_obj: PopochiuProp = _load_obj_base_scene()
	
	if is_interactive:
		new_obj.set_script(ResourceLoader.load(_obj_script_path))
	
	new_obj.name = _obj_name
	new_obj.script_name = _obj_name
	new_obj.description = _obj_script_name.capitalize()
	new_obj.cursor = Constants.CURSOR_TYPE.ACTIVE
	new_obj.clickable = is_interactive
	
	if _obj_script_name in ['bg', 'background']:
		new_obj.baseline =\
		-ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT) / 2.0
		new_obj.z_index = -1

	# Save the prop scene (.tscn) and put it into _obj class property
	if _save_obj_scene(new_obj) == ResultCodes.FAILURE: return

	# Add collision polygon to the prop if it's interactive
	if is_interactive:
		var collision := CollisionPolygon2D.new()
		collision.name = 'InteractionPolygon'
		_obj.add_child(collision)
	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

	# Add the prop to its room
	_add_resource_to_room()

	# This factory returns the object scene
	return _obj
