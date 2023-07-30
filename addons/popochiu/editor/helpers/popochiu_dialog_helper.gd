extends 'res://addons/popochiu/editor/helpers/popochiu_obj_base_helper.gd'
class_name PopochiuDialogHelper

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_type = Constants.Types.DIALOG
	_obj_type_label = 'dialog'
	_obj_type_target = 'dialogs'
	_obj_path_template = _main_dock.DIALOGS_PATH + '%s/dialog_%s'


func create(obj_name: String) -> PopochiuDialog:
	# Setup the class variables that depends on the object name
	_setup_name(obj_name)

	# Create the folder for the dialog
	if _create_obj_folder() == ResultCodes.FAILURE: return

	# Create the script for the dialog
	if _copy_script_template() == ResultCodes.FAILURE: return

	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create dialog resource (not a scene, so we don't invoke _load_base_scene()
	# and _save_obj_scene(). We work directly on _obj class property.
	var _obj := PopochiuDialog.new()
	_obj.set_script(load(_obj_path + '.gd'))
	
	_obj.script_name = _obj_name
	_obj.resource_name = _obj_name
	
	# Save dialog resource (local code because it's not a scene)
	if ResourceSaver.save(_obj, _obj_path + '.tres') != OK:
		push_error(
			"[Popochiu] Couldn't create %s: %s" %
			[_obj_type_label, _obj_name]
		)
		# TODO: Show feedback in the popup via signals/signalbus
		return
	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

	# Add the object to Popochiu dock list, plus open it in the editor
	_add_resource_to_popochiu()
	
	return load(_obj_path + '.tres')
