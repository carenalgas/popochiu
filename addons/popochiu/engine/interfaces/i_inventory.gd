# (I) Data and functions to work with inventory items.
extends Node

signal item_added(item, animate)
signal item_add_done(item)
signal item_removed(item, animate)
signal item_remove_done(item)
signal item_discarded(item)
signal inventory_show_requested(time)
signal inventory_shown
signal inventory_hide_requested(use_anim)

var active: PopochiuInventoryItem
# -- Used for saving the game -------- 
var items := []
var items_states := {}
# -------- Used for saving the game --

var _item_instances := []


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func clean_inventory(in_bg := false) -> void:
	items.clear()
	
	for instance in _item_instances:
		var pii: PopochiuInventoryItem = instance
		
		if not pii.in_inventory: continue
		if not in_bg: pii.on_discard()
		
		item_discarded.emit(pii)
		pii.remove(!in_bg)


func queue_show_inventory(time := 1.0) -> Callable:
	return func (): await show_inventory(time)


# Notifies that the inventory should appear.
func show_inventory(time := 1.0) -> void:
	if E.cutscene_skipped:
		await get_tree().process_frame
		return
	
	inventory_show_requested.emit(time)
	
	await self.inventory_shown


func queue_hide_inventory(use_anim := true) -> Callable:
	return func (): await hide_inventory(use_anim)


func hide_inventory(use_anim := true) -> void:
	inventory_hide_requested.emit(use_anim)
	
	await get_tree().process_frame


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func get_item_instance(item_name: String) -> PopochiuInventoryItem:
	for ii in _item_instances:
		var ii_name: String = ii.script_name
		if ii_name.to_lower() == item_name.to_lower():
			return ii as PopochiuInventoryItem
	
	# If the item is not in the list of items, then instantiate it based checked
	# the list of items (Resource) in Popochiu
	var new_intentory_item: PopochiuInventoryItem =\
	E.get_inventory_item_instance(item_name)
	
	if new_intentory_item:
		_item_instances.append(new_intentory_item)
		return new_intentory_item
	
	return null


# Makes the cursor use the texture of an item in the inventory.
# If `ignore_block` is `true` the cursor texture will change no matter the
# graphic interface is blocked (that is when, by default, the cursor texture is
# an hourglass).
func set_active_item(
	item: PopochiuInventoryItem = null,
	ignore_block := false
) -> void:
	if is_instance_valid(item):
		active = item
		Cursor.set_cursor_texture((item as TextureRect).texture, ignore_block)
	else:
		active = null
		Cursor.remove_cursor_texture()


func is_item_in_inventory(item_name: String) -> bool:
	var i: PopochiuInventoryItem = get_item_instance(item_name)
	return is_instance_valid(i) and i.in_inventory


func is_full() -> bool:
	return E.settings.inventory_limit > 0\
	and E.settings.inventory_limit == items.size()
