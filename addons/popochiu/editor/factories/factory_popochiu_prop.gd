class_name PopochiuPropFactory
extends PopochiuRoomObjFactory


#region Godot ######################################################################################
func _init() -> void:
	_type = PopochiuResources.Types.PROP
	_type_label = "prop"
	_type_method = PopochiuEditorHelper.is_prop
	_obj_room_group = "Props"
	_path_template = "/props/%s/prop_%s"


#endregion

#region Public #####################################################################################
func create(param: PopochiuPropFactoryParam) -> int:
	# If everything goes well, this won't change.
	var result_code := ResultCodes.SUCCESS
	
	if param.should_setup_room_and_name:
		_setup_room(param.room)
		_setup_name(param.obj_name)

	# Create the folder
	result_code = _create_obj_folder()
	if result_code != ResultCodes.SUCCESS: return result_code

	# Create the script (if the prop is interactive)
	if param.should_create_script:
		result_code = _copy_script_template()
		if result_code != ResultCodes.SUCCESS: return result_code
		
	# ---- LOCAL CODE ------------------------------------------------------------------------------
	# Create the instance
	var new_obj: PopochiuProp = _load_obj_base_scene()
	
	new_obj.set_script(ResourceLoader.load(_path_script))
	
	new_obj.name = _pascal_name
	new_obj.script_name = _pascal_name
	new_obj.description = _snake_name.capitalize()
	new_obj.cursor = PopochiuResources.CURSOR_TYPE.ACTIVE
	new_obj.clickable = param.is_interactive
	new_obj.visible = param.is_visible
	new_obj.interaction_polygon = param.interaction_polygon

	if PopochiuConfig.is_pixel_art_textures():
		new_obj.get_node("Sprite2D").texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	if _snake_name in ["bg", "background"]:
		new_obj.baseline =\
		-ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT) / 2.0
		new_obj.z_index = -1

	# Save the scene (.tscn) and put it into _scene class property
	result_code = _save_obj_scene(new_obj)
	if result_code != ResultCodes.SUCCESS: return result_code
	# ---- END OF LOCAL CODE -----------------------------------------------------------------------
	
	if param.should_add_to_room:
		# Add the object to its room
		_add_resource_to_room()
	
	return result_code


#endregion

#region Private ####################################################################################
func _get_param(node: Node) -> PopochiuRoomObjFactoryParam:
	var param := PopochiuPropFactoryParam.new()
	param.is_interactive = node.clickable
	# TODO: Remove this line once the last gizmos PR is merged
	param.interaction_polygon = node.interaction_polygon
	return param


#endregion

#region Subclass ###################################################################################
class PopochiuPropFactoryParam extends PopochiuRoomObjFactory.PopochiuRoomObjFactoryParam:
	var is_interactive := false


#endregion
