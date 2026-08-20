class_name PopochiuInventoryItemRow
extends PopochiuDockRow
# Row for Inventory items in the Main tab. An item can be set to start in the player's inventory.
#
# Ref: #558

const START_ICON = preload("res://addons/popochiu/icons/inventory_item_start.png")

func _init(dock: PopochiuTreeDock) -> void:
	super(dock, PopochiuResources.Types.INVENTORY_ITEM)
	_title = "Inventory items"
	_icon = preload("res://addons/popochiu/icons/inventory_item.png")
	_create_text = "Create inventory item"
	_popup = PopochiuEditorHelper.CREATE_INVENTORY_ITEM
	_folder_path = PopochiuResources.INVENTORY_ITEMS_PATH
	_scene_template = PopochiuResources.INVENTORY_ITEMS_PATH.path_join("%s/inventory_item_%s.tscn")


#region Row #######################################################################################
func create_row(resource) -> TreeItem:
	if get_scene_template().replace("%s", resource.resource_name) in dock.rows_paths: return null
	
	var item := create_item(resource.script_name)
	var data := item.get_metadata(dock.COL_TEXT)
	
	# Check if the item is in the inventory_items array in Popochiu (Popochiu.tscn)
	var is_in_core := PopochiuResources.has_data_value("inventory_items", resource.script_name)
	
	# Check if the item starts in the player's inventory
	var items: Array = PopochiuConfig.get_inventory_items_on_start()
	if resource.script_name in items:
		dock.set_tag(item, START_ICON, true)
		data.is_on_start = true
	
	if not is_in_core:
		dock.set_dimmed(item, true)
		data.in_core = false
	
	return item


func get_menu_cfg(item: TreeItem) -> Array:
	var data := item.get_metadata(dock.COL_TEXT)
	var items: Array = PopochiuConfig.get_inventory_items_on_start()
	var inventory_limit := PopochiuConfig.get_inventory_limit()
	# Disable the option when the inventory limit has been reached and the item is not
	# already in the starting inventory
	var should_disable: bool = (
		inventory_limit > 0
		and items.size() >= inventory_limit
		and data.script_name not in items
	)
	var cfg := [
		{
			id = MenuOptions.START_WITH_IT,
			icon = START_ICON,
			label = "Start with it",
			disabled = should_disable,
		},
	]
	cfg.append_array(super.get_menu_cfg(item))
	return cfg


func on_menu_item_selected(item: TreeItem, id: int) -> void:
	match id:
		MenuOptions.START_WITH_IT:
			toggle_start_with_it(item)
		_:
			super.on_menu_item_selected(item, id)


func toggle_start_with_it(item: TreeItem) -> void:
	var data := item.get_metadata(dock.COL_TEXT)
	var items: Array = PopochiuConfig.get_inventory_items_on_start()
	var script_name: String = data.script_name
	
	if script_name in items:
		items.erase(script_name)
	else:
		items.append(script_name)
	
	PopochiuConfig.set_inventory_items_on_start(items)
	
	var is_on_start := script_name in items
	dock.set_tag(item, START_ICON, is_on_start)
	data.is_on_start = is_on_start


func _remove_from_data(name: String) -> void:
	PopochiuResources.remove_autoload_obj(PopochiuResources.I_SNGL, name)
	PopochiuResources.erase_data_value("inventory_items", name)


func _get_target_array() -> String:
	return "inventory_items"


#endregion