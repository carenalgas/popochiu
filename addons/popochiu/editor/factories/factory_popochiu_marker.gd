class_name PopochiuMarkerFactory
extends 'res://addons/popochiu/editor/factories/factory_base_popochiu_room_obj.gd'


#region Public #####################################################################################
func _init(_main_dock: Panel) -> void:
	super(_main_dock)
	_type = Constants.Types.MARKER
	_type_label = 'marker'
	_obj_room_group = 'Markers'
	_path_template = '/markers/%s/marker_%s'


func create(obj_name: String, room: PopochiuRoom) -> int:
	# If everything goes well, this won't change.
	var result_code := ResultCodes.SUCCESS

	_setup_room(room)
	_setup_name(obj_name)

	# Create the folder
	result_code = _create_obj_folder()
	if result_code != ResultCodes.SUCCESS: return result_code

	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the instance
	var new_obj: Marker2D = Marker2D.new()
	new_obj.name = _pascal_name

	# Save the marker scene (.tscn) and put it into _scene class property
	result_code = _save_obj_scene(new_obj)
	if result_code != ResultCodes.SUCCESS: return result_code
	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

	# Add the object to its room
	_add_resource_to_room()

	return result_code


#endregion
