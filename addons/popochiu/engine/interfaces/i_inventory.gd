class_name PopochiuIInventory
extends Node
## Provides access to the [PopochiuInventoryItem]s in the game. Access with [b]I[/b] (e.g.,
## [code]I.Key.add()[/code]).
##
## Use it to manage the inventory. Its script is [b]i_inventory.gd[/b].[br][br]
##
## Some things you can do with it:[br][br]
## [b]•[/b] Add and remove items in the inventory.[br]
## [b]•[/b] Change the cursor to the appearance of an inventory item.[br]
## [b]•[/b] Detect when an item has been added or removed.[br][br]
##
## Examples:
## [codeblock]
## # Add the DeckOfCards item to the inventory.
## I.DeckOfCards.add_now(false)
##
## # Add the Key item to the inventory and make it the selected one.
## I.Key.add_as_active()
##
## # Remove the Card item from the inventory. Inside an E.run([])
## I.Card.remove()
##
## # Add the ToyCar item after some dialog lines
## E.queue([
##     "Player: Oh, is the toy car I need",
##     I.ToyCar.queue_add(),
##     "Player: Now I will be able to enter the private club",
## ])
## [/codeblock]

## Emitted when [param item] is added to the inventory. [param animate] can be utilized by the GUI
## to display an animation of the item entering the inventory.
signal item_added(item: PopochiuInventoryItem, animate: bool)
## Emitted when the [param item] has completed entering the inventory, signifying the end of the GUI
## animation.
signal item_add_done(item: PopochiuInventoryItem)
## Emitted when [param item] is removed from the inventory. [param animate] can be employed by the
## GUI to display an animation of the item leaving the inventory.
signal item_removed(item: PopochiuInventoryItem, animate: bool)
## Emitted when the [param item] has completed leaving the inventory, indicating the end of the GUI
## animation.
signal item_remove_done(item: PopochiuInventoryItem)
## Emitted when [param item] is replaced in the inventory by [param new_item]. Useful for handling
## inventory item combinations.
signal item_replaced(item: PopochiuInventoryItem, new_item: PopochiuInventoryItem)
## Emitted when an item replacement has finished.
signal item_replace_done
## Emitted when the [param item] has finished leaving the inventory (i.e. when the GUI animation
## is complete).
signal item_discarded(item: PopochiuInventoryItem)
## Emitted when [param item] is selected in the inventory.
signal item_selected(item: PopochiuInventoryItem)
## Emitted when the inventory is about to be displayed. You can specify the duration it remains
## visible with [param time] in seconds.
signal inventory_show_requested(time: float)
## Emitted once the animation that displays the inventory has finished.
signal inventory_shown
## Emitted when you want to hide the inventory. [param use_anim] can be used to determine whether or
## not to use an animation in the GUI.
signal inventory_hide_requested(use_anim: bool)

## Provides access to the inventory item that is currently selected.
var active: PopochiuInventoryItem : set = set_active
## Provides access to the inventory item that was clicked.
var clicked: PopochiuInventoryItem
# ---- Used for saving/loading the game ------------------------------------------------------------
## [Array] containing instances of the currently held [PopochiuInventoryItem]s.
var items := []
## Stores data about the state of each [PopochiuInventoryItem] in the game. The key of each entry is
## the [member PopochiuInventoryItem.script_name] of the item.
var items_states := {}
# ------------------------------------------------------------ Used for saving/loading the game ----

var _item_instances := {}


#region Godot ######################################################################################
func _init() -> void:
	Engine.register_singleton(&"I", self)


#endregion

#region Public #####################################################################################
## Removes all the items that are currently in the inventory. If [param in_bg] is [code]true[/code],
## then the items are removed without calling [method PopochiuInventoryItem.discard] for each item.
func clean_inventory(in_bg := false) -> void:
	items.clear()
	
	for instance in _item_instances:
		var pii: PopochiuInventoryItem = _item_instances[instance]
		
		if not pii.in_inventory: continue
		if not in_bg: await pii.discard()
		
		pii.remove(!in_bg)


## Displays the inventory for a duration of [param time] seconds.
func show_inventory(time := 1.0) -> void:
	if PopochiuUtils.e.cutscene_skipped:
		await get_tree().process_frame
		return
	
	inventory_show_requested.emit(time)
	
	await self.inventory_shown


## Displays the inventory for a duration of [param time] seconds.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_show_inventory(time := 1.0) -> Callable:
	return func (): await show_inventory(time)


## Hides the inventory. If [param use_anim] is set to [code]true[/code], a GUI animation is applied.
func hide_inventory(use_anim := true) -> void:
	inventory_hide_requested.emit(use_anim)
	
	await get_tree().process_frame


## Hides the inventory. If [param use_anim] is set to [code]true[/code], a GUI animation is applied.
## [br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_hide_inventory(use_anim := true) -> Callable:
	return func (): await hide_inventory(use_anim)


## Returns the instance of the [PopochiuInventoryItem] identified with [param item_name]. If the
## item doesn't exists, then [code]null[/code] is returned.[br][br]
## This method is used by [b]res://game/autoloads/i.gd[/b] to load the instace of each item
## (present in that script as a variable for code autocompletion) in runtime.
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


## Gets the instance of the [PopochiuInventoryItem] identified with [param script_name].
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


## Verifies if the item identified as [param item_name] is in the inventory.
func is_item_in_inventory(item_name: String) -> bool:
	var i: PopochiuInventoryItem = get_item_instance(item_name)
	return is_instance_valid(i) and i.in_inventory


## Checks whether the inventory has reached its limit.
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
