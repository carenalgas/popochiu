@tool
extends "res://addons/popochiu/editor/popups/create_object/create_object.gd"
## Creates a new [PopochiuDialog].
## 
## It creates all the necessary files to make a [PopochiuDialog] to work:
## - dialog_xxx.gd (The script where the behavior for each dialog option is defined)
## - dialog_xxx.tres (The Resource file used to create the dialog options in the Inspector)

var _new_dialog_name := ""
var _factory: PopochiuDialogFactory


#region Godot ######################################################################################
func _ready() -> void:
	_info_files = "[code]- &t_&n.gd\n- &t_&n.tres[/code]"
	_info_files = _info_files.replace("&t", "dialog")
	
	super()


#endregion

#region Virtual ####################################################################################
func _create() -> Object:
	if _new_dialog_name.is_empty():
		error_feedback.show()
		return null
	
	# Setup the prop helper and use it to create the prop ------------------------------------------
	_factory = PopochiuDialogFactory.new()
	if _factory.create(_new_dialog_name) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return null
	await get_tree().create_timer(0.1).timeout
	
	return _factory.get_obj_resource()


func _set_info_text() -> void:
	_new_dialog_name = _name.to_snake_case()
	_target_folder = PopochiuResources.DIALOGS_PATH.path_join(_new_dialog_name)
	
	info.text = (_info_text % _target_folder).replace("&n", _new_dialog_name)


#endregion
