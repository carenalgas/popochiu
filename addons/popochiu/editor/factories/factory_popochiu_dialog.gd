extends 'res://addons/popochiu/editor/factories/factory_base_popochiu_obj.gd'
class_name PopochiuDialogFactory

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func _init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_type = Constants.Types.DIALOG
	_obj_type_label = 'dialog'
	_obj_type_target = 'dialogs'
	_obj_path_template = _main_dock.DIALOGS_PATH + '%s/dialog_%s'


func create(obj_name: String) -> int:
	# If everything goes well, this won't change.
	var result_code := ResultCodes.SUCCESS

	# Setup the class variables that depends on the object name
	_setup_name(obj_name)

	# Create the folder for the dialog
	result_code = _create_obj_folder()
	if result_code != ResultCodes.SUCCESS: return result_code

	# Create the script for the dialog
	result_code = _copy_script_template()
	if result_code != ResultCodes.SUCCESS: return result_code

	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create dialog resource (not a scene, so we don't invoke _load_base_scene()
	# and _save_obj_scene(). We work directly on _obj_scene class property.
	var new_obj := PopochiuDialog.new()
	new_obj.set_script(load(_obj_path_script))
	
	new_obj.script_name = _obj_pascal_name
	new_obj.resource_name = _obj_pascal_name
	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

	# Save dialog resource (dialogs are not scenes)
	result_code = _save_obj_resource(new_obj)
	if result_code != ResultCodes.SUCCESS: return result_code

	# Add the object to Popochiu dock list, plus open it in the editor
	_add_resource_to_popochiu()
	
	return result_code
