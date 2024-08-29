class_name PopochiuMarkerFactory
extends PopochiuRoomObjFactory

#region Godot ######################################################################################
func _init() -> void:
	_type = PopochiuResources.Types.MARKER
	_type_label = "marker"
	_type_method = PopochiuEditorHelper.is_marker
	_obj_room_group = "Markers"
	_path_template = "/markers/%s/marker_%s"


#endregion
#region Public #####################################################################################
func create(param: PopochiuRoomObjFactoryParam) -> int:
	# If everything goes well, this won't change.
	var result_code := ResultCodes.SUCCESS
	
	if param.should_setup_room_and_name:
		_setup_room(param.room)
		_setup_name(param.obj_name)

	# Create the folder
	result_code = _create_obj_folder()
	if result_code != ResultCodes.SUCCESS: return result_code

	# ---- LOCAL CODE ------------------------------------------------------------------------------
	# Create the instance
	var new_obj: Marker2D = Marker2D.new()
	new_obj.name = _pascal_name

	# Save the marker scene (.tscn) and put it into _scene class property
	result_code = _save_obj_scene(new_obj)
	if result_code != ResultCodes.SUCCESS: return result_code
	# ---- END OF LOCAL CODE -----------------------------------------------------------------------
	
	if param.should_add_to_room:
		# Add the object to its room
		_add_resource_to_room()

	return result_code


#endregion
