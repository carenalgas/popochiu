@tool
extends PopochiuTreeDock
# Acts like a HUD for working with Popochiu objects: Rooms, Characters, Inventory items, and Dialog
# trees. Uses a native [Tree] control to display the objects grouped by type.
#
# Each object type is handled by a specialized row class (see rows/), which knows how to create
# its group and items and how to handle clicks, buttons, and context-menu options.
#
# Ref: #558

const PLAYER_ICON = preload("res://addons/popochiu/icons/player_character.png")
const START_ICON = preload("res://addons/popochiu/icons/inventory_item_start.png")

var rows_paths := []
var has_data := false

var _rows := {
	PopochiuResources.Types.ROOM: PopochiuRoomRow,
	PopochiuResources.Types.CHARACTER: PopochiuCharacterRow,
	PopochiuResources.Types.INVENTORY_ITEM: PopochiuInventoryItemRow,
	PopochiuResources.Types.DIALOG: PopochiuDialogRow,
}
var _row_instances := {}


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Create the row instances and their groups for each object type
	for type_key: int in _rows:
		var row: PopochiuDockRow = _rows[type_key].new(self)
		_row_instances[type_key] = row
		row.create_group()
	
	# Connect to the base class signals
	item_clicked.connect(_on_item_clicked)
	button_clicked.connect(_on_item_button_clicked)
	menu_item_selected.connect(_on_menu_item_selected)
	create_clicked.connect(_on_create_clicked)
	
	# Connect to helper signals
	PopochiuEditorHelper.signal_bus.main_scene_changed.connect(_set_main_scene)
	PopochiuEditorHelper.signal_bus.pc_changed.connect(_set_pc)
	PopochiuEditorHelper.signal_bus.main_object_added.connect(_add_to_list)


#endregion

#region Public #####################################################################################
func fill_data() -> void:
	# Search the FileSystem for Rooms, Characters, InventoryItems and Dialogs
	for type_key: int in _rows:
		var row: PopochiuDockRow = _row_instances[type_key]
		var resources := Array(DirAccess.get_directories_at(row.get_folder_path())).map(
			_get_popochiu_objects_resources.bind(type_key)
		)
		
		for resource: Resource in resources:
			row.create_row(resource)


func check_data() -> void:
	if not has_data:
		# Try to load the Main tab data in case they couldn't be loaded while
		# opening the engine
		fill_data()


#endregion

#region Private ####################################################################################
func _set_main_scene(path: String) -> void:
	ProjectSettings.set_setting(PopochiuResources.MAIN_SCENE, path)
	assert(
		ProjectSettings.save() == OK,
		"[Popochiu] Couldn't set %s as the Main Scene in Project Settings" % path
	)
	_clear_group_tags(_row_instances[PopochiuResources.Types.ROOM].group, "is_main")


func _set_pc(script_name: String) -> void:
	if PopochiuResources.get_data_value("setup", "pc", "") == script_name:
		return
	
	assert(
		PopochiuResources.set_data_value("setup", "pc", script_name) == OK,
		"[Popochiu] Couldn't set %s as the Player-controlled Character (PC)" % script_name
	)
	
	_clear_group_tags(_row_instances[PopochiuResources.Types.CHARACTER].group, "is_pc")
	
	var item := get_item(_row_instances[PopochiuResources.Types.CHARACTER].group, script_name)
	if item:
		set_tag(item, PLAYER_ICON, true)
		item.get_metadata(COL_TEXT).is_pc = true


func _add_to_list(type: int, name_to_add: String) -> TreeItem:
	return _row_instances[type].create_item(name_to_add)


func _get_popochiu_objects_resources(
	dir_name: String, type_key: PopochiuResources.Types
) -> Resource:
	var resource_filesystem := EditorInterface.get_resource_filesystem()
	var dir_path := (_row_instances[type_key].get_folder_path() as String).path_join(dir_name)
	
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.get_extension() != "tres": continue
		
		var resource: Resource = load(dir_path.path_join(file_name))
		if (
			resource is PopochiuRoomData
			or resource is PopochiuCharacterData
			or resource is PopochiuInventoryItemData
			or resource is PopochiuDialog
		):
			return resource
	
	PopochiuUtils.print_error("No data file (.tres) found for [b]%s[/b]" % dir_path)
	return null


func _clear_group_tags(group: TreeItem, flag: String) -> void:
	for child in group.get_children():
		child.set_icon(COL_TAG, null)
		child.get_metadata(COL_TEXT)[flag] = false


func _on_item_clicked(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	_row_instances[data.type].on_item_clicked(item)


func _on_item_button_clicked(item: TreeItem, id: int) -> void:
	var data := item.get_metadata(COL_TEXT)
	_row_instances[data.type].on_button_clicked(item, id)


func _on_menu_item_selected(item: TreeItem, id: int) -> void:
	var data := item.get_metadata(COL_TEXT)
	_row_instances[data.type].on_menu_item_selected(item, id)


func _on_create_clicked(group_item: TreeItem) -> void:
	var type_key: int = group_item.get_metadata(COL_TEXT).type
	PopochiuEditorHelper.show_creation_popup(_row_instances[type_key].get_popup())


func _get_menu_cfg(item: TreeItem) -> Array:
	var data := item.get_metadata(COL_TEXT)
	return _row_instances[data.type].get_menu_cfg(item)


func _remove_from_core(item: TreeItem, should_save_and_delete := true) -> void:
	var data := item.get_metadata(COL_TEXT)
	_row_instances[data.type].remove_from_core(item, should_save_and_delete)


#endregion