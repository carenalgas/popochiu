@tool
extends "res://addons/popochiu/editor/main_dock/popochiu_row/object_row/popochiu_object_row.gd"


#region Private ####################################################################################
func _remove_from_core() -> void:
	# Delete the object from Popochiu
	PopochiuResources.remove_autoload_obj(PopochiuResources.D_SNGL, name)
	PopochiuResources.erase_data_value("dialogs", str(name))
	
	# Continue with the deletion flow
	super()


#endregion
