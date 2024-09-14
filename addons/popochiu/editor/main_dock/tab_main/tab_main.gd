@tool
extends VBoxContainer
## Acts like a HUD for working with Popochiu objects: Rooms, Characters, Inventory items, and Dialog
## trees.

const OBJECT_ROW_FOLDER = "res://addons/popochiu/editor/main_dock/popochiu_row/object_row/"
const POPOCHIU_OBJECT_ROW_SCENE = preload(OBJECT_ROW_FOLDER + "popochiu_object_row.tscn")
const POPOCHIU_ROOM_ROW_SCENE = preload(OBJECT_ROW_FOLDER + "room_row/popochiu_room_row.tscn")
const PopochiuObjectRow := preload(OBJECT_ROW_FOLDER + "popochiu_object_row.gd")
const PopochiuCharacterRow = preload(OBJECT_ROW_FOLDER + "character_row/popochiu_character_row.gd")
const PopochiuInventoryItemRow = preload(
	OBJECT_ROW_FOLDER + "inventory_item_row/popochiu_inventory_item_row.gd"
)
const PopochiuDialogRow = preload(OBJECT_ROW_FOLDER + "dialog_row/popochiu_dialog_row.gd")

var last_selected: PopochiuObjectRow = null

var _rows_paths := []
var _has_data := false

@onready var _types := {
	PopochiuResources.Types.ROOM: {
		path = PopochiuResources.ROOMS_PATH,
		group = find_child("RoomsGroup"),
		popup = PopochiuEditorHelper.CREATE_ROOM,
		scene = PopochiuResources.ROOMS_PATH.path_join("%s/room_%s.tscn")
	},
	PopochiuResources.Types.CHARACTER: {
		path = PopochiuResources.CHARACTERS_PATH,
		group = find_child("CharactersGroup"),
		popup = PopochiuEditorHelper.CREATE_CHARACTER,
		scene = PopochiuResources.CHARACTERS_PATH.path_join("%s/character_%s.tscn")
	},
	PopochiuResources.Types.INVENTORY_ITEM: {
		path = PopochiuResources.INVENTORY_ITEMS_PATH,
		group = find_child("ItemsGroup"),
		popup = PopochiuEditorHelper.CREATE_INVENTORY_ITEM,
		scene = PopochiuResources.INVENTORY_ITEMS_PATH.path_join("%s/inventory_item_%s.tscn")
	},
	PopochiuResources.Types.DIALOG: {
		path = PopochiuResources.DIALOGS_PATH,
		group = find_child("DialogsGroup"),
		popup = PopochiuEditorHelper.CREATE_DIALOG,
		scene = PopochiuResources.DIALOGS_PATH.path_join("%s/dialog_%s.tres")
	}
}

#region Godot ######################################################################################
func _ready() -> void:
	$PopochiuFilter.groups = _types
	
	for t in _types.values():
		t.group.create_clicked.connect(PopochiuEditorHelper.show_creation_popup.bind(t.popup))
	
	# Connect to helper signals
	PopochiuEditorHelper.signal_bus.main_scene_changed.connect(_set_main_scene)
	PopochiuEditorHelper.signal_bus.pc_changed.connect(_set_pc)
	PopochiuEditorHelper.signal_bus.main_object_added.connect(_add_to_list)


#endregion

#region Public #####################################################################################
func fill_data() -> void:
	# Search the FileSystem for Rooms, Characters, InventoryItems and Dialogs
	for type_key: int in _types:
		var resources := Array(DirAccess.get_directories_at(_types[type_key].path)).map(
			_get_popochiu_objects_resources.bind(type_key)
		)
		
		for resource: Resource in resources:
			_create_row(type_key, resource)


func check_data() -> void:
	if not _has_data:
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
	_types[PopochiuResources.Types.ROOM].group.clear_favs()


func _set_pc(script_name: String) -> void:
	if PopochiuResources.get_data_value("setup", "pc", "") == script_name:
		return
	
	assert(
		PopochiuResources.set_data_value("setup", "pc", script_name) == OK,
		"[Popochiu] Couldn't set %s as the Player-controlled Character (PC)" % script_name
	)
	
	var characters_group: PopochiuGroup = _types[PopochiuResources.Types.CHARACTER].group
	characters_group.clear_favs()
	(characters_group.get_by_name(script_name) as PopochiuCharacterRow).is_pc = true


func _add_to_list(type: int, name_to_add: String) -> PopochiuObjectRow:
	var row := _create_object_row(type, name_to_add)
	_types[type].group.add(row)
	return row


func _get_popochiu_objects_resources(
	dir_name: String, type_key: PopochiuResources.Types
) -> Resource:
	var resource_filesystem := EditorInterface.get_resource_filesystem()
	var dir_path := (_types[type_key].path as String).path_join(dir_name)
	
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


func _create_row(type_key: int, resource: Resource) -> void:
	if _types[type_key].scene.replace("%s", resource.resource_name) in _rows_paths: return
	
	var row: PopochiuObjectRow = _create_object_row(type_key, resource.script_name)
	_types[type_key].group.add(row)
	
	# Check if the object in the list is in its corresponding array in Popochiu (Popochiu.tscn)
	var is_in_core := true
	var has_state_script: bool = FileAccess.file_exists(row.path.replace(".tscn", "_state.gd"))
	
	match type_key:
		PopochiuResources.Types.ROOM:
			is_in_core = PopochiuResources.has_data_value("rooms", resource.script_name)
			
			# Check if the room is the main scene
			var main_scene: String = ProjectSettings.get_setting(PopochiuResources.MAIN_SCENE)
			
			if main_scene == resource.scene:
				row.is_main = true
		PopochiuResources.Types.CHARACTER:
			is_in_core = PopochiuResources.has_data_value("characters", resource.script_name)
			
			if resource.script_name == PopochiuResources.get_data_value("setup", "pc", ""):
				row.is_pc = true
		PopochiuResources.Types.INVENTORY_ITEM:
			is_in_core = PopochiuResources.has_data_value("inventory_items", resource.script_name)
			
			var items: Array = PopochiuConfig.get_inventory_items_on_start()
			
			if resource.script_name in items:
				row.is_on_start = true
		PopochiuResources.Types.DIALOG:
			is_in_core = PopochiuResources.has_data_value("dialogs", resource.script_name)
	
	if not is_in_core:
		row.show_as_not_in_core()


func _create_object_row(type: int, name_to_add: String) -> PopochiuObjectRow:
	var new_obj: PopochiuObjectRow = null
	
	match type:
		PopochiuResources.Types.ROOM:
			new_obj = POPOCHIU_ROOM_ROW_SCENE.instantiate()
		PopochiuResources.Types.CHARACTER:
			new_obj = POPOCHIU_OBJECT_ROW_SCENE.instantiate()
			new_obj.set_script(PopochiuCharacterRow)
		PopochiuResources.Types.INVENTORY_ITEM:
			new_obj = POPOCHIU_OBJECT_ROW_SCENE.instantiate()
			new_obj.set_script(PopochiuInventoryItemRow)
		PopochiuResources.Types.DIALOG:
			new_obj = POPOCHIU_OBJECT_ROW_SCENE.instantiate()
			new_obj.set_script(PopochiuDialogRow)
	
	new_obj.name = name_to_add
	new_obj.type = type
	new_obj.path = _types[type].scene.replace("%s", name_to_add.to_snake_case())
	new_obj.clicked.connect(_select_object)
	
	_rows_paths.append(new_obj.path)
	_has_data = true
	
	return new_obj


func _select_object(por: PopochiuObjectRow) -> void:
	if last_selected and last_selected != por:
		last_selected.deselect()
	
	last_selected = por


#endregion
