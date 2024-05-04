extends "res://addons/popochiu/editor/factories/factory_base_popochiu_obj.gd"
class_name PopochiuDialogFactory

#region Godot ######################################################################################
func _init() -> void:
	_type = PopochiuResources.Types.DIALOG
	_type_label = "dialog"
	_type_target = "dialogs"
	_path_template = PopochiuResources.DIALOGS_PATH.path_join("%s/dialog_%s")


#endregion

#region Public #####################################################################################
func create(obj_name: String) -> int:
	# If everything goes well, this won't change.
	var result_code := ResultCodes.SUCCESS

	# Setup the class variables that depends on the object name
	_setup_name(obj_name)

	# Create the folder
	result_code = _create_obj_folder()
	if result_code != ResultCodes.SUCCESS: return result_code

	# Create the script
	result_code = _copy_script_template()
	if result_code != ResultCodes.SUCCESS: return result_code

	# ---- LOCAL CODE ------------------------------------------------------------------------------
	# Create the resource (dialogs are not scenes)
	var new_obj := PopochiuDialog.new()
	new_obj.set_script(load(_path_script))
	
	new_obj.script_name = _pascal_name
	new_obj.resource_name = _pascal_name
	# ---- END OF LOCAL CODE -----------------------------------------------------------------------

	# Save resource (dialogs are not scenes)
	result_code = _save_obj_resource(new_obj)
	if result_code != ResultCodes.SUCCESS: return result_code

	# Add the object to Popochiu dock list, plus open it in the editor
	_add_resource_to_popochiu()
	
	return result_code


#endregion
