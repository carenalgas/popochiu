class_name PopochiuWalkableAreaFactory
extends 'res://addons/popochiu/editor/factories/factory_base_popochiu_room_obj.gd'


#region Public #####################################################################################
func _init(_main_dock: Panel) -> void:
	super(_main_dock)
	_type = Constants.Types.WALKABLE_AREA
	_type_label = 'walkable_area'
	_obj_room_group = 'WalkableAreas'
	_path_template = '/walkable_areas/%s/walkable_area_%s'


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
	var new_obj: PopochiuWalkableArea = _load_obj_base_scene()
	
	new_obj.set_script(ResourceLoader.load(_path_script))

	new_obj.name = _pascal_name
	new_obj.script_name = _pascal_name
	new_obj.description = _snake_name.capitalize()

	# Save the scene (.tscn) and put it into _scene class property
	result_code = _save_obj_scene(new_obj)
	if result_code != ResultCodes.SUCCESS: return result_code

	# Create a NavigationRegion2D with its polygon as a child in the room scene
	var perimeter := NavigationRegion2D.new()
	perimeter.name = 'Perimeter'
	
	var polygon := NavigationPolygon.new()
	polygon.add_outline(PackedVector2Array([
		Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)
	]))
	polygon.make_polygons_from_outlines()
	polygon.agent_radius = 0.0
	
	perimeter.navpoly = polygon
	perimeter.modulate = Color.GREEN
	
	_add_visible_child(perimeter)
	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

	# Add the object to its room
	_add_resource_to_room()

	return result_code


#endregion
