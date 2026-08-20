class_name PopochiuDialogRow
extends PopochiuDockRow
# Row for Dialog trees in the Main tab.
#
# Ref: #558

func _init(dock: PopochiuTreeDock) -> void:
	super(dock, PopochiuResources.Types.DIALOG)
	_title = "Dialog trees"
	_icon = preload("res://addons/popochiu/icons/dialog.png")
	_create_text = "Create dialog tree"
	_popup = PopochiuEditorHelper.CREATE_DIALOG
	_folder_path = PopochiuResources.DIALOGS_PATH
	_scene_template = PopochiuResources.DIALOGS_PATH.path_join("%s/dialog_%s.tres")


#region Row #######################################################################################
func create_row(resource) -> TreeItem:
	if get_scene_template().replace("%s", resource.resource_name) in dock.rows_paths: return null
	
	var item := create_item(resource.script_name)
	var data := item.get_metadata(dock.COL_TEXT)
	
	# Check if the dialog is in the dialogs array in Popochiu (Popochiu.tscn)
	var is_in_core := PopochiuResources.has_data_value("dialogs", resource.script_name)
	
	if not is_in_core:
		dock.set_dimmed(item, true)
		data.in_core = false
	
	return item


func _remove_from_data(name: String) -> void:
	PopochiuResources.remove_autoload_obj(PopochiuResources.D_SNGL, name)
	PopochiuResources.erase_data_value("dialogs", name)


func _get_target_array() -> String:
	return "dialogs"


#endregion