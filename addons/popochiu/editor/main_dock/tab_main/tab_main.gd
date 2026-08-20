@tool
extends PopochiuTreeDock
# Acts like a HUD for working with Popochiu objects: Rooms, Characters, Inventory items, and Dialog
# trees. Uses a native [Tree] control to display the objects grouped by type.
#
# Ref: #558

const ADD_TO_CORE_ICON = preload(
	"res://addons/popochiu/editor/main_dock/popochiu_row/images/add_to_core.png"
)
const PLAYER_ICON = preload("res://addons/popochiu/icons/player_character.png")
const START_ICON = preload("res://addons/popochiu/icons/inventory_item_start.png")

enum MenuOptions {
	SEPARATOR = -1,
	DELETE,
	ADD_TO_CORE,
	SET_AS_MAIN,
	SET_AS_PC,
	START_WITH_IT,
}

enum Buttons {
	OPEN,
	SCRIPT,
	STATE,
	STATE_SCRIPT,
	PLAY,
}

var _rows_paths := []
var _has_data := false

var _types := {
	PopochiuResources.Types.ROOM: {
		path = PopochiuResources.ROOMS_PATH,
		group = null,
		popup = PopochiuEditorHelper.CREATE_ROOM,
		scene = PopochiuResources.ROOMS_PATH.path_join("%s/room_%s.tscn"),
		icon = preload("res://addons/popochiu/icons/room.png"),
		title = "Rooms",
		create_text = "Create room",
	},
	PopochiuResources.Types.CHARACTER: {
		path = PopochiuResources.CHARACTERS_PATH,
		group = null,
		popup = PopochiuEditorHelper.CREATE_CHARACTER,
		scene = PopochiuResources.CHARACTERS_PATH.path_join("%s/character_%s.tscn"),
		icon = preload("res://addons/popochiu/icons/character.png"),
		title = "Characters",
		create_text = "Create character",
	},
	PopochiuResources.Types.INVENTORY_ITEM: {
		path = PopochiuResources.INVENTORY_ITEMS_PATH,
		group = null,
		popup = PopochiuEditorHelper.CREATE_INVENTORY_ITEM,
		scene = PopochiuResources.INVENTORY_ITEMS_PATH.path_join("%s/inventory_item_%s.tscn"),
		icon = preload("res://addons/popochiu/icons/inventory_item.png"),
		title = "Inventory items",
		create_text = "Create inventory item",
	},
	PopochiuResources.Types.DIALOG: {
		path = PopochiuResources.DIALOGS_PATH,
		group = null,
		popup = PopochiuEditorHelper.CREATE_DIALOG,
		scene = PopochiuResources.DIALOGS_PATH.path_join("%s/dialog_%s.tres"),
		icon = preload("res://addons/popochiu/icons/dialog.png"),
		title = "Dialog trees",
		create_text = "Create dialog tree",
	},
}


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Create the groups for each object type
	for type_key: int in _types:
		var t: Dictionary = _types[type_key]
		t.group = create_group(t.title, t.icon, true, t.create_text, { "type": type_key })
	
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
	_clear_group_tags(_types[PopochiuResources.Types.ROOM].group, "is_main")


func _set_pc(script_name: String) -> void:
	if PopochiuResources.get_data_value("setup", "pc", "") == script_name:
		return
	
	assert(
		PopochiuResources.set_data_value("setup", "pc", script_name) == OK,
		"[Popochiu] Couldn't set %s as the Player-controlled Character (PC)" % script_name
	)
	
	_clear_group_tags(_types[PopochiuResources.Types.CHARACTER].group, "is_pc")
	
	var item := get_item(_types[PopochiuResources.Types.CHARACTER].group, script_name)
	if item:
		set_tag(item, PLAYER_ICON, true)
		item.get_metadata(COL_TEXT).is_pc = true


func _add_to_list(type: int, name_to_add: String) -> TreeItem:
	return _create_item(type, name_to_add)


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
	
	var item := _create_item(type_key, resource.script_name)
	var data := item.get_metadata(COL_TEXT)
	
	# Check if the object in the list is in its corresponding array in Popochiu (Popochiu.tscn)
	var is_in_core := true
	
	match type_key:
		PopochiuResources.Types.ROOM:
			is_in_core = PopochiuResources.has_data_value("rooms", resource.script_name)
			
			# Check if the room is the main scene
			var main_scene: String = ProjectSettings.get_setting(PopochiuResources.MAIN_SCENE)
			
			if main_scene == resource.scene:
				set_tag(item, get_theme_icon("Heart", "EditorIcons"), true)
				data.is_main = true
		PopochiuResources.Types.CHARACTER:
			is_in_core = PopochiuResources.has_data_value("characters", resource.script_name)
			
			if resource.script_name == PopochiuResources.get_data_value("setup", "pc", ""):
				set_tag(item, PLAYER_ICON, true)
				data.is_pc = true
		PopochiuResources.Types.INVENTORY_ITEM:
			is_in_core = PopochiuResources.has_data_value("inventory_items", resource.script_name)
			
			var items: Array = PopochiuConfig.get_inventory_items_on_start()
			
			if resource.script_name in items:
				set_tag(item, START_ICON, true)
				data.is_on_start = true
		PopochiuResources.Types.DIALOG:
			is_in_core = PopochiuResources.has_data_value("dialogs", resource.script_name)
	
	if not is_in_core:
		set_dimmed(item, true)
		data.in_core = false


func _create_item(type: int, name_to_add: String) -> TreeItem:
	var group: TreeItem = _types[type].group
	var path: String = _types[type].scene.replace("%s", name_to_add.to_snake_case())
	var data := {
		"type": type,
		"path": path,
		"script_name": name_to_add,
		"in_core": true,
	}
	
	var item := add_item(group, name_to_add, _types[type].icon, data)
	
	# Add the action buttons
	add_button(item, get_theme_icon("InstanceOptions", "EditorIcons"), Buttons.OPEN, "Open in Editor")
	add_button(item, get_theme_icon("Script", "EditorIcons"), Buttons.SCRIPT, "Open in Script")
	add_button(item, get_theme_icon("Object", "EditorIcons"), Buttons.STATE, "Open state")
	add_button(item, get_theme_icon("GDScript", "EditorIcons"), Buttons.STATE_SCRIPT, "Open state Script")
	
	if type == PopochiuResources.Types.ROOM:
		add_button(item, get_theme_icon("MainPlay", "EditorIcons"), Buttons.PLAY, "Play scene")
	
	add_menu_button(item)
	
	_rows_paths.append(path)
	_has_data = true
	
	return item


func _clear_group_tags(group: TreeItem, flag: String) -> void:
	for child in group.get_children():
		child.set_icon(COL_TAG, null)
		child.get_metadata(COL_TEXT)[flag] = false


func _on_item_clicked(item: TreeItem) -> void:
	EditorInterface.select_file(item.get_metadata(COL_TEXT).path)


func _on_item_button_clicked(item: TreeItem, id: int) -> void:
	match id:
		Buttons.OPEN:
			_open(item)
		Buttons.SCRIPT:
			_open_script(item)
		Buttons.STATE:
			_edit_state(item)
		Buttons.STATE_SCRIPT:
			_open_state_script(item)
		Buttons.PLAY:
			_play(item)


func _on_menu_item_selected(item: TreeItem, id: int) -> void:
	match id:
		MenuOptions.DELETE:
			_remove_object(item)
		MenuOptions.ADD_TO_CORE:
			_add_object_to_core(item)
		MenuOptions.SET_AS_MAIN:
			_set_main(item, true)
		MenuOptions.SET_AS_PC:
			_set_pc_item(item, true)
		MenuOptions.START_WITH_IT:
			_toggle_start_with_it(item)


func _on_create_clicked(group_item: TreeItem) -> void:
	var type_key: int = group_item.get_metadata(COL_TEXT).type
	PopochiuEditorHelper.show_creation_popup(_types[type_key].popup)


func _get_menu_cfg(item: TreeItem) -> Array:
	var data := item.get_metadata(COL_TEXT)
	var type: int = data.type
	var cfg := []
	
	match type:
		PopochiuResources.Types.ROOM:
			cfg.append({
				id = MenuOptions.SET_AS_MAIN,
				icon = get_theme_icon("Heart", "EditorIcons"),
				label = "Set as Main scene",
				disabled = data.get("is_main", false),
			})
		PopochiuResources.Types.CHARACTER:
			cfg.append({
				id = MenuOptions.SET_AS_PC,
				icon = PLAYER_ICON,
				label = "Set as Player-controlled Character (PC)",
				disabled = data.get("is_pc", false),
			})
		PopochiuResources.Types.INVENTORY_ITEM:
			var items: Array = PopochiuConfig.get_inventory_items_on_start()
			var inventory_limit := PopochiuConfig.get_inventory_limit()
			# Disable the option when the inventory limit has been reached and the item is not
			# already in the starting inventory
			var should_disable: bool = (
				inventory_limit > 0
				and items.size() >= inventory_limit
				and data.script_name not in items
			)
			cfg.append({
				id = MenuOptions.START_WITH_IT,
				icon = START_ICON,
				label = "Start with it",
				disabled = should_disable,
			})
	
	cfg.append({
		id = MenuOptions.ADD_TO_CORE,
		icon = ADD_TO_CORE_ICON,
		label = "Add to Popochiu",
		disabled = data.get("in_core", true),
	})
	cfg.append(MenuOptions.SEPARATOR)
	cfg.append({
		id = MenuOptions.DELETE,
		icon = get_theme_icon("Remove", "EditorIcons"),
		label = "Remove",
	})
	
	return cfg


func _set_main(item: TreeItem, value: bool) -> void:
	if value:
		# Call this first since the favs will be cleared
		PopochiuEditorHelper.signal_bus.main_scene_changed.emit(item.get_metadata(COL_TEXT).path)
	
	set_tag(item, get_theme_icon("Heart", "EditorIcons"), value)
	item.get_metadata(COL_TEXT).is_main = value


func _set_pc_item(item: TreeItem, value: bool) -> void:
	if value:
		# Call this first since the favs will be cleared
		PopochiuEditorHelper.signal_bus.pc_changed.emit(item.get_metadata(COL_TEXT).script_name)
	
	set_tag(item, PLAYER_ICON, value)
	item.get_metadata(COL_TEXT).is_pc = value


func _toggle_start_with_it(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	var items: Array = PopochiuConfig.get_inventory_items_on_start()
	var script_name: String = data.script_name
	
	if script_name in items:
		items.erase(script_name)
	else:
		items.append(script_name)
	
	PopochiuConfig.set_inventory_items_on_start(items)
	
	var is_on_start := script_name in items
	set_tag(item, START_ICON, is_on_start)
	data.is_on_start = is_on_start


func _edit_state(item: TreeItem) -> void:
	var path: String = item.get_metadata(COL_TEXT).path
	EditorInterface.select_file(path.replace(".tscn", ".tres"))
	EditorInterface.edit_resource(load(path.replace(".tscn", ".tres")))


func _open_state_script(item: TreeItem) -> void:
	var path: String = item.get_metadata(COL_TEXT).path
	var state := load(path.replace(".tscn", ".tres"))
	
	EditorInterface.select_file(state.get_script().resource_path)
	EditorInterface.set_main_screen_editor("Script")
	EditorInterface.edit_resource(state.get_script())


func _play(item: TreeItem) -> void:
	var path: String = item.get_metadata(COL_TEXT).path
	EditorInterface.select_file(path)
	EditorInterface.play_custom_scene(path)


func _add_object_to_core(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	var type: int = data.type
	var path: String = data.path
	var target_array := ""
	var resource: Resource
	
	if ".tscn" in path:
		resource = load(path.replace(".tscn", ".tres"))
	else:
		resource = load(path)
	
	match type:
		PopochiuResources.Types.ROOM:
			target_array = "rooms"
		PopochiuResources.Types.CHARACTER:
			target_array = "characters"
		PopochiuResources.Types.INVENTORY_ITEM:
			target_array = "inventory_items"
		PopochiuResources.Types.DIALOG:
			target_array = "dialogs"
	
	if PopochiuEditorHelper.add_resource_to_popochiu(target_array, resource) != OK:
		PopochiuUtils.print_error("Couldn't add Object [b]%s[/b] to Popochiu." % item.get_text(COL_TEXT))
		return
	
	# Add the object to its corresponding singleton
	PopochiuResources.update_autoloads(true)
	
	set_dimmed(item, false)
	data.in_core = true


func _remove_from_core(item: TreeItem, should_save_and_delete := true) -> void:
	var data := item.get_metadata(COL_TEXT)
	var type: int = data.type
	var path: String = data.path
	var name: String = item.get_text(COL_TEXT)
	
	# Remove the object from Popochiu data and its corresponding autoload
	match type:
		PopochiuResources.Types.ROOM:
			PopochiuResources.remove_autoload_obj(PopochiuResources.R_SNGL, name)
			PopochiuResources.erase_data_value("rooms", name)
		PopochiuResources.Types.CHARACTER:
			PopochiuResources.remove_autoload_obj(PopochiuResources.C_SNGL, name)
			PopochiuResources.erase_data_value("characters", name)
		PopochiuResources.Types.INVENTORY_ITEM:
			PopochiuResources.remove_autoload_obj(PopochiuResources.I_SNGL, name)
			PopochiuResources.erase_data_value("inventory_items", name)
		PopochiuResources.Types.DIALOG:
			PopochiuResources.remove_autoload_obj(PopochiuResources.D_SNGL, name)
			PopochiuResources.erase_data_value("dialogs", name)
	
	# Check if the files should be deleted in the file system
	if _delete_dialog.check_box.button_pressed:
		_delete_from_file_system(path)
	elif type in PopochiuResources.MAIN_TYPES:
		set_dimmed(item, true)
		data.in_core = false
	
	var edited_scene: Node = EditorInterface.get_edited_scene_root()
	if edited_scene and edited_scene.get("script_name") and edited_scene.script_name == name:
		# If the open scene matches the object being deleted, skip saving the scene
		remove_item(item)
		return
	
	# Fix #438: Do not save and free the row always. When this function is called from the
	# popochiu_room_object_row script, saving the scene is handled there, and deleting the row
	# is not needed.
	if should_save_and_delete:
		EditorInterface.save_scene()
		remove_item(item)


#endregion