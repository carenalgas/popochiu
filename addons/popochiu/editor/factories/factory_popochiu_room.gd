extends "res://addons/popochiu/editor/factories/factory_base_popochiu_obj.gd"
class_name PopochiuRoomFactory

#region Godot ######################################################################################
func _init() -> void:
	_type = PopochiuResources.Types.ROOM
	_type_label = "room"
	_type_target = "rooms"
	_path_template = PopochiuResources.ROOMS_PATH.path_join("%s/room_%s")


#endregion

#region Public #####################################################################################
func create(obj_name: String, set_as_main := false) -> int:
	# If everything goes well, this won't change.
	var result_code := ResultCodes.SUCCESS

	# Setup the class variables that depends on the object name
	_setup_name(obj_name)

	# Create the folder
	result_code = _create_obj_folder()
	if result_code != ResultCodes.SUCCESS: return result_code
	
	# Create the state Resource and a script
	# so devs can add extra properties to that state
	result_code = _create_state_resource()
	if result_code != ResultCodes.SUCCESS: return result_code
		
	# Create the script populating the template with the right references
	result_code = _create_script_from_template()
	if result_code != ResultCodes.SUCCESS: return result_code

	# ---- LOCAL CODE ------------------------------------------------------------------------------
	# Create the instance
	var new_obj: PopochiuRoom = _load_obj_base_scene()
	
	new_obj.name = "Room" + _pascal_name
	new_obj.script_name = _pascal_name
	new_obj.width = ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH)
	new_obj.height = ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	# ---- END OF LOCAL CODE -----------------------------------------------------------------------
	
	# Save the scene (.tscn)
	result_code = _save_obj_scene(new_obj)
	if result_code != ResultCodes.SUCCESS: return result_code

	# Add the object to Popochiu dock list, plus open it in the editor
	_add_resource_to_popochiu()
	
	# ---- LOCAL CODE ------------------------------------------------------------------------------
	# Set as main room
	# Changed _set_as_main_check.pressed to _set_as_main_check.button_pressed
	# in order to fix #56
	if set_as_main:
		PopochiuEditorHelper.signal_bus.main_scene_changed.emit(_scene.scene_file_path)
	# ---- END OF LOCAL CODE -----------------------------------------------------------------------

	return result_code


#endregion
