class_name PopochiuHotspotFactory
extends PopochiuRoomObjFactory


#region Godot ######################################################################################
func _init() -> void:
	_type = PopochiuResources.Types.HOTSPOT
	_type_label = "hotspot"
	_type_method = PopochiuEditorHelper.is_hotspot
	_obj_room_group = "Hotspots"
	_path_template = "/hotspots/%s/hotspot_%s"


#endregion

#region Public #####################################################################################
func create(param: PopochiuHotspotFactoryParam) -> int:
	# If everything goes well, this won't change.
	var result_code := ResultCodes.SUCCESS
	
	if param.should_setup_room_and_name:
		_setup_room(param.room)
		_setup_name(param.obj_name)
	
	# Create the folder
	result_code = _create_obj_folder()
	if result_code != ResultCodes.SUCCESS: return result_code
	
	# Create the script
	if param.should_create_script:
		result_code = _copy_script_template()
		if result_code != ResultCodes.SUCCESS: return result_code

	# ---- LOCAL CODE ------------------------------------------------------------------------------
	# Create the instance
	var new_obj: PopochiuHotspot = _load_obj_base_scene()
	
	new_obj.set_script(ResourceLoader.load(_path_script))
	
	new_obj.name = _pascal_name
	new_obj.script_name = _pascal_name
	new_obj.description = _snake_name.capitalize()
	new_obj.cursor = PopochiuResources.CURSOR_TYPE.ACTIVE
	new_obj.interaction_polygon = param.interaction_polygon

	# Save the hostspot scene (.tscn) and put it into _scene class property
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
	var param := PopochiuHotspotFactoryParam.new()
	param.is_interactive = node.clickable
	# TODO: Remove this line once the last gizmos PR is merged
	param.interaction_polygon = node.interaction_polygon
	return param


#endregion

#region Subclass ###################################################################################
class PopochiuHotspotFactoryParam extends PopochiuRoomObjFactory.PopochiuRoomObjFactoryParam:
	var is_interactive := true


#endregion
