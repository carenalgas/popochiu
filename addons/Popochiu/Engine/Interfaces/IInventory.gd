extends Node
# (I) Data and functions to work with inventory items.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

signal item_added(item, animate)
signal item_add_done(item)
signal item_removed(item)
signal item_remove_done(item)

export var always_visible := false

var _item_instances := []

var active: PopochiuInventoryItem
var show_anims := true

export(Array, PackedScene) var inventory_items
export var items := []


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	if not inventory_items.empty():
		for ii in inventory_items:
			var item_instance: PopochiuInventoryItem = ii.instance()
			_item_instances.append({
				script_name = item_instance.script_name,
				node = item_instance
			})


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Adds an item to the inventory. The item is added based on its script_name
# property.
func add_item(item_name: String, is_in_queue := true, animate := true) -> void:
	if is_in_queue: yield()
	
	var i: PopochiuInventoryItem = _get_item_instance(item_name)
	if is_instance_valid(i) and not i.in_inventory:
		i.in_inventory = true
		
		emit_signal('item_added', i, animate)
		
		return yield(self, 'item_add_done')
	
	yield(get_tree(), 'idle_frame')


# Adds an item to the inventory and make it the current selected item. That is,
# the cursor will thake the item's texture as its texture.
func add_item_as_active(item_name: String, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	var item: PopochiuInventoryItem = yield(add_item(item_name, false), 'completed')
	
	if is_instance_valid(item):
		set_active_item(item)


# Makes the cursor use the texture of an item in the inventory.
func set_active_item(item: PopochiuInventoryItem = null) -> void:
	if item:
		active = item
		Cursor.set_item_cursor((item as TextureRect).texture)
	else:
		active = null
		Cursor.remove_item_cursor()


# Removes an item from the inventory. Its instance will be kept in the
# _item_instances array.
func remove_item(item_name: String, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	var i: PopochiuInventoryItem = _get_item_instance(item_name)
	if is_instance_valid(i):
		i.in_inventory = false
		
		set_active_item(null)
		emit_signal('item_removed', i)
		
		yield(self, 'item_remove_done')


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
