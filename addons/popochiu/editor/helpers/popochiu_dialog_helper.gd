extends 'res://addons/popochiu/editor/helpers/popochiu_obj_base_helper.gd'
class_name PopochiuDialogHelper

const BASE_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/dialog_template.gd'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_path_template = _main_dock.DIALOGS_PATH + '%s/dialog_%s'
	_obj_type = Constants.Types.DIALOG
	_obj_type_label = 'dialog'
	_obj_type_target = 'dialogs'

func create(obj_name: String) -> PopochiuDialog:
	# TODO: Check if another Prop was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	_setup_name(obj_name)

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the item
	DirAccess.make_dir_absolute(_main_dock.DIALOGS_PATH + _obj_script_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the new dialog
	var obj_script: Script = load(BASE_SCRIPT_TEMPLATE).duplicate()
	
	if ResourceSaver.save(obj_script, _obj_path + '.gd') != OK:
		push_error("[Popochiu] Couldn't create script: %s" % _obj_name)
		# TODO: Show feedback in the popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create dialog Resource
	var obj_resource := PopochiuDialog.new()
	obj_resource.set_script(load(_obj_path + '.gd'))
	
	obj_resource.script_name = _obj_name
	obj_resource.resource_name = _obj_name
	
	if ResourceSaver.save(obj_resource, _obj_path + '.tres') != OK:
		push_error("[Popochiu] Couldn't create dialog: %s" %_obj_name)
		# TODO: Show feedback in the popup
		return

	# Keep the returning value name coherent (TODO refactor this eyesore)
	var obj_instance: PopochiuDialog = load(_obj_path + '.tres')

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the object to Popochiu dock list, plus open it in the editor
	_add_resource_to_popochiu()
	
	return obj_instance
