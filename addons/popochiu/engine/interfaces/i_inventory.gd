# @popochiu-docs-category game-scripts-interfaces
class_name PopochiuIInventory
extends Node
## Provides access to [PopochiuInventoryItem] instances through the singleton [b]I[/b]
## (for example: [code]I.Key.add()[/code]).
##
## Use this interface to manage the game's inventory. Its script is [b]i_inventory.gd[/b].
##
## Capabilities include:
##
## - Add or remove items from the inventory.[br]
## - Change the cursor to an inventory item's texture.[br]
## - Notify the GUI when items are added or removed.
##
## [b]Use examples:[/b]
## [codeblock]
## # Add the DeckOfCards item to the inventory.
## I.DeckOfCards.add()
##
## # Add the Key item to the inventory and make it the selected one.
## I.Key.add_as_active()
##
## # Remove the Card item from the inventory.
## I.Card.remove()
##
## # Add the ToyCar item after some dialog lines.
## E.queue([
##     "Player: Oh, is the toy car I need",
##     I.ToyCar.queue_add(),
##     "Player: Now I will be able to enter the private club",
## ])
## [/codeblock]

## Emitted when [param item] is added to the inventory. [param animate] may be used by the GUI
## to animate the item entering the inventory.
signal item_added(item: PopochiuInventoryItem, animate: bool)
## Emitted when the [param item] has finished entering the inventory (GUI animation completed).
signal item_add_done(item: PopochiuInventoryItem)
## Emitted when [param item] is removed from the inventory. [param animate] may be used by the
## GUI to animate the item leaving the inventory.
signal item_removed(item: PopochiuInventoryItem, animate: bool)
## Emitted when the [param item] has finished leaving the inventory (GUI animation completed).
signal item_remove_done(item: PopochiuInventoryItem)
## Emitted when [param item] is replaced in the inventory by [param new_item]. Useful for
## implementing item combinations.
signal item_replaced(item: PopochiuInventoryItem, new_item: PopochiuInventoryItem)
## Emitted when an item replacement has finished.
signal item_replace_done
## Emitted when the [param item] has been discarded (GUI animation finished).
signal item_discarded(item: PopochiuInventoryItem)
## Emitted when [param item] is selected in the inventory.
signal item_selected(item: PopochiuInventoryItem)
## Emitted when the inventory is requested to be shown. [param time] sets how long it should remain
## visible (in seconds).
signal inventory_show_requested(time: float)
## Emitted when the inventory-show animation has finished.
signal inventory_shown
## Emitted when the inventory is requested to hide. [param use_anim] indicates whether the GUI
## should use an animation.
signal inventory_hide_requested(use_anim: bool)

## Provides access to the inventory item that is currently selected.
var active: PopochiuInventoryItem : set = set_active
## Provides access to the inventory item that was clicked.
var clicked: PopochiuInventoryItem
# ---- Used for saving/loading the game ------------------------------------------------------------
## [Array] containing instances of the currently held [PopochiuInventoryItem]s.
var items := []
## Stores per-item state data for each [PopochiuInventoryItem] in the project. The key for each
## entry is the item's [member PopochiuInventoryItem.script_name].
var items_states := {}
# ------------------------------------------------------------ Used for saving/loading the game ----

var _item_instances := {}


#region Godot ######################################################################################
func _init() -> void:
	Engine.register_singleton(&"I", self)


#endregion

#region Public #####################################################################################
## Removes all items currently in the inventory. If [param in_bg] is [code]true[/code], items are
## removed in background without calling [method PopochiuInventoryItem.discard].
func clean_inventory(in_bg := false) -> void:
	items.clear()
	
	for instance in _item_instances:
		var pii: PopochiuInventoryItem = _item_instances[instance]
		
		if not pii.in_inventory: continue
		if not in_bg: await pii.discard()
		
		pii.remove(!in_bg)


## Shows the inventory for [param time] seconds.
func show_inventory(time := 1.0) -> void:
	if PopochiuUtils.e.cutscene_skipped:
		await get_tree().process_frame
		return
	
	inventory_show_requested.emit(time)
	
	await self.inventory_shown


## Shows the inventory for [param time] seconds.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_show_inventory(time := 1.0) -> Callable:
	return func (): await show_inventory(time)


## Hides the inventory. If [param use_anim] is [code]true[/code], the GUI may play an animation.
func hide_inventory(use_anim := true) -> void:
	inventory_hide_requested.emit(use_anim)
	
	await get_tree().process_frame


## Hides the inventory. If [param use_anim] is [code]true[/code], the GUI may play an animation.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_hide_inventory(use_anim := true) -> Callable:
	return func (): await hide_inventory(use_anim)


## Returns the instance of the [PopochiuInventoryItem] identified by [param item_name], or
## [code]null[/code] if it does not exist.
##
## Used by [b]res://game/autoloads/i.gd[/b] to instantiate item variables at runtime for
## autocompletion.
func get_item_instance(item_name: String) -> PopochiuInventoryItem:
	var item: PopochiuInventoryItem = null
	
	if _item_instances.has(item_name):
		item = _item_instances[item_name]
	else:
		# If the item is not in the list of items, then try to instantiate it
		item = get_instance(item_name)
		
		if item:
			_item_instances[item.script_name] = item
			set(item.script_name, item)
	
	return item


## Instantiates and returns the [PopochiuInventoryItem] resource referenced by [param script_name]
## from project data. Logs an error and returns [code]null[/code] if not found.
func get_instance(script_name: String) -> PopochiuInventoryItem:
	var tres_path: String = PopochiuResources.get_data_value("inventory_items", script_name, "")
	
	if not tres_path:
		PopochiuUtils.print_error(
			"Inventory item [b]%s[/b] doesn't exist in the project" % script_name
		)
		return null
	
	return load(load(tres_path).scene).instantiate()


## Sets the cursor to use the texture of [param item].
func set_active_item(item: PopochiuInventoryItem = null) -> void:
	if is_instance_valid(item):
		active = item
	else:
		active = null


## Returns [code]true[/code] if the item identified by [param item_name] is currently in the
## inventory.
func is_item_in_inventory(item_name: String) -> bool:
	var i: PopochiuInventoryItem = get_item_instance(item_name)
	return is_instance_valid(i) and i.in_inventory


## Returns [code]true[/code] if the item identified by [param item_name] has ever been collected.
func has_item_been_collected(item_name: String) -> bool:
	var i: PopochiuInventoryItem = get_item_instance(item_name)
	return is_instance_valid(i) and i.ever_collected


## Returns [code]true[/code] if the inventory has reached the inventory limit
## configured in the project settings.
func is_full() -> bool:
	return (
		PopochiuUtils.e.settings.inventory_limit > 0
		and PopochiuUtils.e.settings.inventory_limit == items.size()
	)


## Deselects the [member active] item.
func deselect_active() -> void:
	active = null


#endregion

#region SetGet #####################################################################################
func set_active(value: PopochiuInventoryItem) -> void:
	if is_instance_valid(active):
		active.unselected.emit()
	
	active = value
	
	item_selected.emit(active)


#endregion
