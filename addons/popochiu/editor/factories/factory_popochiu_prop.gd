class_name PopochiuPropFactory
extends 'res://addons/popochiu/editor/factories/factory_base_popochiu_room_obj.gd'


#region Public #####################################################################################
func _init(_main_dock: Panel) -> void:
	super(_main_dock)
	
	_type = Constants.Types.PROP
	_type_label = 'prop'
	_obj_room_group = 'Props'
	_path_template = '/props/%s/prop_%s'


func create(
	obj_name: String, room: PopochiuRoom, is_interactive:bool = false, is_visible:bool = true
) -> int:
	# If everything goes well, this won't change.
	var result_code := ResultCodes.SUCCESS

	_setup_room(room)
	_setup_name(obj_name)

	# Create the folder
	result_code = _create_obj_folder()
	if result_code != ResultCodes.SUCCESS: return result_code

	# Create the script (if the prop is interactive)
	result_code = _copy_script_template()
	if result_code != ResultCodes.SUCCESS: return result_code
		
	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the instance
	var new_obj: PopochiuProp = _load_obj_base_scene()
	
	new_obj.set_script(ResourceLoader.load(_path_script))
	
	new_obj.name = _pascal_name
	new_obj.script_name = _pascal_name
	new_obj.description = _snake_name.capitalize()
	new_obj.cursor = Constants.CURSOR_TYPE.ACTIVE
	new_obj.clickable = is_interactive
	new_obj.visible = is_visible

	if PopochiuResources.get_settings().is_pixel_art_game:
		new_obj.get_node("Sprite2D").texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	if _snake_name in ['bg', 'background']:
		new_obj.baseline =\
		-ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT) / 2.0
		new_obj.z_index = -1

	# Save the scene (.tscn) and put it into _scene class property
	result_code = _save_obj_scene(new_obj)
	if result_code != ResultCodes.SUCCESS: return result_code
	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

	# Add the object to its room
	_add_resource_to_room()

	return result_code


#endregion
