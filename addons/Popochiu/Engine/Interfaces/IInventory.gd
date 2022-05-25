extends Node
# (I) Data and functions to work with inventory items.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

signal item_added(item, animate)
signal item_add_done(item)
signal item_removed(item)
signal item_remove_done(item)
#signal item_discarded(item)
signal inventory_show_requested(time)
signal inventory_shown


var active: PopochiuInventoryItem

var _item_instances := []
var _items_count := 0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Adds an item to the inventory. The item is added based on its script_name
# property.
func add_item(item_name: String, is_in_queue := true, animate := true) -> void:
	if is_in_queue: yield()
	
	if E.inventory_limit > 0 and _items_count == E.inventory_limit:
		prints(
			'[Popochiu] Could not add %s to the inventory because it is full' %\
			item_name
		)
		
		return yield(get_tree(), 'idle_frame')
	
	var i: PopochiuInventoryItem = _get_item_instance(item_name)
	if is_instance_valid(i) and not i.in_inventory:
		i.in_inventory = true
		_items_count += 1
		
		emit_signal('item_added', i, animate)
		
		return yield(self, 'item_add_done')
	
	return yield(get_tree(), 'idle_frame')


# Adds an item to the inventory and make it the current selected item. That is,
# the cursor will thake the item's texture as its texture.
func add_item_as_active(\
item_name: String, is_in_queue := true, animate := true) -> void:
	if is_in_queue: yield()
	
	var item: PopochiuInventoryItem = yield(
		add_item(item_name, false, animate),
		'completed'
	)
	
	if is_instance_valid(item):
		set_active_item(item)
	
	return item


# Makes the cursor use the texture of an item in the inventory.
func set_active_item(item: PopochiuInventoryItem = null) -> void:
	if item:
		active = item
		Cursor.set_cursor_texture((item as TextureRect).texture)
	else:
		active = null
		Cursor.remove_cursor_texture()


# Removes an item from the inventory. Its instance will be kept in the
# _item_instances array.
func remove_item(item_name: String, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	var i: PopochiuInventoryItem = _get_item_instance(item_name)
	if is_instance_valid(i):
		i.in_inventory = false
		_items_count -= 1
		
		set_active_item(null)
		emit_signal('item_removed', i)
		
		yield(self, 'item_remove_done')


func is_item_in_inventory(item_name: String) -> bool:
	var i: PopochiuInventoryItem = _get_item_instance(item_name)
	return is_instance_valid(i) and i.in_inventory


func is_full() -> bool:
	return E.inventory_limit > 0 and E.inventory_limit == _items_count


#func discard_item(item_name: String, is_in_queue := true) -> void:
#	if is_in_queue: yield()
#	var i: PopochiuInventoryItem = _get_item_instance(item_name)
#	if is_instance_valid(i):
#		i.on_discard()
#		emit_signal('item_discarded', i)
#		yield(self.remove_item(item_name, is_in_queue), 'completed')
#
#
#func clean_inventory() -> void:
#	for ii in _item_instances:
#		ii.on_discard()
#		emit_signal('item_discarded', ii)
#		self.remove_item(ii.script_name, false)


# Notifies that the inventory should appear.
func show_inventory(time := 1.0, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	if E.cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return
	
	emit_signal('inventory_show_requested', time)
	yield(self, 'inventory_shown')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _get_item_instance(item_name: String) -> PopochiuInventoryItem:
	for ii in _item_instances:
		var ii_name: String = ii.script_name
		if ii_name.to_lower() == item_name.to_lower():
			return ii as PopochiuInventoryItem
	
	# If the item is not in the list of items, then instantiate it based on the
	# list of items (Resource) in Popochiu
	var new_intentory_item: PopochiuInventoryItem = E.get_inventory_item_instance(
		item_name
	)
	if new_intentory_item:
		_item_instances.append(new_intentory_item)
		return new_intentory_item
	
	return null
