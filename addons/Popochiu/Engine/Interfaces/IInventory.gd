extends Node
# (I) Data and functions to work with inventory items.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

signal item_added(item, animate)
signal item_add_done(item)
signal item_removed(item, animate)
signal item_remove_done(item)
signal item_discarded(item)
signal inventory_show_requested(time)
signal inventory_shown
signal inventory_hide_requested(use_anim)


var active: PopochiuInventoryItem
# Used for saving the game
var items := []
var items_states := {}

var _item_instances := []


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func add_item(item_name: String, animate := true) -> Callable:
	return func (): await add_item_no_run(item_name, animate)

# Adds an item to the inventory. The item is added based checked its script_name
# property.
func add_item_no_run(item_name: String, animate := true) -> PopochiuInventoryItem:
	if E.settings.inventory_limit > 0\
	and items.size() == E.settings.inventory_limit:
		prints(
			'[Popochiu] Could not add %s to the inventory because it is full.' %\
			item_name
		)
		
		await get_tree().process_frame
		return
	
	var i: PopochiuInventoryItem = _get_item_instance(item_name)
	if is_instance_valid(i) and not i.in_inventory:
		items.append(item_name)
		
		item_added.emit(i, animate)
		i.in_inventory = true
		
		await self.item_add_done
		return i
	
	await get_tree().process_frame
	return null


func add_item_as_active(item_name: String, animate := true) -> Callable:
	return func (): await add_item_as_active_no_run(item_name, animate)


# Adds an item to the inventory and make it the current selected item. That is,
# the cursor will thake the item's texture as its texture.
func add_item_as_active_no_run(
	item_name: String, animate := true
) -> PopochiuInventoryItem:
	var item: PopochiuInventoryItem = await add_item_no_run(item_name, animate)
	
	if is_instance_valid(item):
		set_active_item(item, E.in_no_run())
	
	return item


# Makes the cursor use the texture of an item in the inventory.
func set_active_item(
	item: PopochiuInventoryItem = null,
	ignore_block := false
) -> void:
	if item:
		active = item
		Cursor.set_cursor_texture((item as TextureRect).texture, ignore_block)
	else:
		active = null
		Cursor.remove_cursor_texture()


func remove_item(item_name: String, animate := true) -> Callable:
	return func (): await remove_item_no_run(item_name, animate)


# Removes an item from the inventory. Its instance will be kept in the
# _item_instances array.
func remove_item_no_run(item_name: String, animate := true) -> void:
	var i: PopochiuInventoryItem = _get_item_instance(item_name)
	if is_instance_valid(i):
		i.in_inventory = false
		items.erase(item_name)
		
		set_active_item(null)
		
		# TODO: Maybe this signal should be triggered once the await has finished
		item_removed.emit(i, animate)
		
		await self.item_remove_done


func is_item_in_inventory(item_name: String) -> bool:
	var i: PopochiuInventoryItem = _get_item_instance(item_name)
	return is_instance_valid(i) and i.in_inventory


func is_full() -> bool:
	return E.settings.inventory_limit > 0\
	and E.settings.inventory_limit == items.size()


func discard_item(item_name: String) -> Callable:
	return func (): await discard_item_no_run(item_name)


func discard_item_no_run(item_name: String) -> void:
	var i: PopochiuInventoryItem = _get_item_instance(item_name)
	
	if is_instance_valid(i):
		i.on_discard()
		items.erase(item_name)
		
		# TODO: Maybe this signal should be triggered once the await has finished
		item_discarded.emit(i)
		
		await remove_item(item_name)


func clean_inventory(in_bg := false) -> void:
	items.clear()
	
	for ii in _item_instances:
		if not ii.in_inventory: continue
		
		if not in_bg:
			ii.on_discard()
		
		item_discarded.emit(ii)
		
		remove_item_no_run(ii.script_name, !in_bg)


func show_inventory(time := 1.0) -> Callable:
	return func (): await show_inventory_no_run(time)


# Notifies that the inventory should appear.
func show_inventory_no_run(time := 1.0) -> void:
	if E.cutscene_skipped:
		await get_tree().process_frame
		return
	
	inventory_show_requested.emit(time)
	
	await self.inventory_shown


func hide_inventory(use_anim := true) -> Callable:
	return func (): await hide_inventory_no_run(use_anim)


func hide_inventory_no_run(use_anim := true) -> void:
	inventory_hide_requested.emit(use_anim)
	
	await get_tree().process_frame


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _get_item_instance(item_name: String) -> PopochiuInventoryItem:
	for ii in _item_instances:
		var ii_name: String = ii.script_name
		if ii_name.to_lower() == item_name.to_lower():
			return ii as PopochiuInventoryItem
	
	# If the item is not in the list of items, then instantiate it based checked the
	# list of items (Resource) in Popochiu
	var new_intentory_item: PopochiuInventoryItem = E.get_inventory_item_instance(
		item_name
	)
	if new_intentory_item:
		_item_instances.append(new_intentory_item)
		return new_intentory_item
	
	return null
