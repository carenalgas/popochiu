class_name PopochiuWalkableAreaFactory
extends PopochiuRoomObjFactory


#region Godot ######################################################################################
func _init() -> void:
	_type = PopochiuResources.Types.WALKABLE_AREA
	_type_label = "walkable_area"
	_type_method = PopochiuEditorHelper.is_walkable_area
	_obj_room_group = "WalkableAreas"
	_path_template = "/walkable_areas/%s/walkable_area_%s"


#endregion

#region Public #####################################################################################
func create(param: PopochiuWalkableAreaFactoryParam) -> int:
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
	var new_obj: PopochiuWalkableArea = _load_obj_base_scene()
	
	new_obj.set_script(ResourceLoader.load(_path_script))

	new_obj.name = _pascal_name
	new_obj.script_name = _pascal_name
	new_obj.description = _snake_name.capitalize()

	# Find the NavigationRegion2D for the WA and populate it with a default rectangle polygon
	var perimeter := new_obj.find_child("Perimeter")
	var polygon := NavigationPolygon.new()
	polygon.add_outline(PackedVector2Array([
		Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)
	]))
	NavigationServer2D.bake_from_source_geometry_data(
		polygon, NavigationMeshSourceGeometryData2D.new()
	)
	polygon.agent_radius = 0.0
	perimeter.navigation_polygon = polygon
	
	if not param.navigation_polygon.is_empty():
		new_obj.interaction_polygon = param.navigation_polygon
		new_obj.clear_and_bake(perimeter.navigation_polygon)

	# Show the WA perimeter, depending on user prefs
	perimeter.visible = PopochiuEditorConfig.get_editor_setting(
		PopochiuEditorConfig.GIZMOS_ALWAYS_SHOW_WA
	)

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
	var param := PopochiuWalkableAreaFactoryParam.new()
	param.navigation_polygon = node.interaction_polygon
	
	return param


#endregion

#region Subclass ###################################################################################
class PopochiuWalkableAreaFactoryParam extends PopochiuRoomObjFactory.PopochiuRoomObjFactoryParam:
	var navigation_polygon := []


#endregion
