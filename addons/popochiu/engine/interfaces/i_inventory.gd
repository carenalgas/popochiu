# @popochiu-docs-category game-scripts-interfaces
class_name PopochiuIInventory
extends Node
## Provides access to [PopochiuInventoryItem] instances through the singleton [b]I[/b]
## (for example: [code]I.Key.add()[/code]).
##
## Use this interface to manage each character's inventory. Its script is [b]i_inventory.gd[/b].
## Each [PopochiuCharacter] has its own [member PopochiuCharacter.inventory] dictionary.
## Methods on this interface accept an optional [param character] parameter; when omitted,
## they default to the current player character ([code]C.player[/code]).
##
## Capabilities include:
##
## - Add or remove items from a character's inventory.[br]
## - Change the cursor to an inventory item's texture.[br]
## - Notify the GUI when items are added or removed.
##
## [b]Use examples:[/b]
## [codeblock]
## # Add the DeckOfCards item to the player's inventory.
## I.DeckOfCards.add()
##
## # Add the Key item to Popsy's inventory and make it the selected one.
## I.Key.add_as_active(1, C.Popsy)
##
## # Remove the Card item from the player's inventory.
## I.Card.remove()
##
## # Add the ToyCar item after some dialog lines.
## E.queue([
##     "Player: Oh, is the toy car I need",
##     I.ToyCar.queue_add(),
##     "Player: Now I will be able to enter the private club",
## ])
## [/codeblock]

## Emitted when [param item] is added to [param character]'s inventory.
signal item_added(item: PopochiuInventoryItem, character: PopochiuCharacter)
## Emitted when the [param item] has finished entering [param character]'s inventory (GUI
## animation completed).
signal item_add_done(item: PopochiuInventoryItem, character: PopochiuCharacter)
## Emitted when [param item] is removed from [param character]'s inventory.
signal item_removed(item: PopochiuInventoryItem, character: PopochiuCharacter)
## Emitted when the [param item] has finished leaving [param character]'s inventory (GUI
## animation completed).
signal item_remove_done(item: PopochiuInventoryItem, character: PopochiuCharacter)
## Emitted when [param item] is replaced in [param character]'s inventory by [param new_item].
## Useful for implementing item combinations.
signal item_replaced(
	item: PopochiuInventoryItem, new_item: PopochiuInventoryItem, character: PopochiuCharacter
)
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
## Emitted when the quantity of [param item] changes in [param character]'s inventory without the
## item being added to or removed from the inventory (i.e., when stacking or partially removing).
## [param new_quantity] is the updated count.
signal item_quantity_updated(
	item: PopochiuInventoryItem, new_quantity: int, character: PopochiuCharacter
)

## Provides access to the inventory item that is currently selected.
var active: PopochiuInventoryItem : set = set_active
## Provides access to the inventory item that was clicked.
var clicked: PopochiuInventoryItem
## When [code]true[/code], the inventory is being restored from a save file. GUI components
## should skip entrance/exit animations during restore.
var is_restoring := false
# ---- Used for saving/loading the game ------------------------------------------------------------
## @deprecated Use [member PopochiuCharacter.inventory] instead.
var items: Array : set = _set_items, get = _get_items
## Stores per-item state data for each [PopochiuInventoryItem] in the project. The key for each
## entry is the item's [member PopochiuInventoryItem.script_name].
var items_states := {}
# ------------------------------------------------------------ Used for saving/loading the game ----

var _item_instances := {}


#region Godot ######################################################################################
func _init() -> void:
	if not Engine.has_singleton(&"I"):
		Engine.register_singleton(&"I", self)


#endregion

#region Public #####################################################################################
## Removes all items from [param character]'s inventory (default: [member PopochiuICharacter.player]).
## When items are removed the GUI lifecycle gets triggered once for each item, so the GUI may play
## animations if necessary.
func clean_inventory(character: PopochiuCharacter = null) -> void:
	var target := _resolve_character(character)
	if not is_instance_valid(target):
		return
	
	# Remove each item through its full GUI lifecycle.
	for item_name: String in target.inventory.keys():
		var pii: PopochiuInventoryItem = target.inventory[item_name] as PopochiuInventoryItem
		if is_instance_valid(pii) and pii.quantity_owned > 0:
			await pii.remove()


## Removes all items from [param character]'s inventory (default: [member PopochiuICharacter.player])
## without triggering GUI lifecycle (useful during scene transitions).
func clean_inventory_bg(character: PopochiuCharacter = null) -> void:
	var target := _resolve_character(character)
	if not is_instance_valid(target):
		return
	
	# refs #349: In background mode, reset quantity_owned directly and clear the inventory dict
	# to avoid signal emissions and GUI awaits.
	for item_name: String in target.inventory.keys():
		var pii: PopochiuInventoryItem = target.inventory[item_name] as PopochiuInventoryItem
		if is_instance_valid(pii):
			pii.quantity_owned = 0
	target.inventory.clear()
	set_active_item(null)
	clicked = null


## Adds [param quantity] of [param item] to [param character]'s inventory (default:
## [member PopochiuICharacter.player]) and waits until any GUI transition has finished.
## Inventory capacity is slot-based: stacked quantities still occupy a single slot and
## count as [code]1[/code] against the inventory limit.
func add_item(item: PopochiuInventoryItem, quantity := 1, character: PopochiuCharacter = null) -> void:
	var target := _resolve_character(character)
	if not is_instance_valid(target):
		PopochiuUtils.print_warning(
			"Couldn't add %s. No valid character target." % item.script_name
		)
		await get_tree().process_frame
		return

	# Stop on negative or null quantities.
	if quantity <= 0:
		PopochiuUtils.print_warning(
			"Couldn't add %d of %s to %s. Quantity must be greater than 0."
			% [quantity, item.script_name, target.script_name]
		)
		await get_tree().process_frame
		return

	# If character doesn't own the item yet...
	if item.quantity_owned == 0:
		# Stop if the inventory is full.
		if is_full(target):
			PopochiuUtils.print_warning(
				"Couldn't add %s. %s's inventory is full." % [item.script_name, target.script_name]
			)
			await get_tree().process_frame
			return

		# Calculate the addable quantity for the first collection of this item.
		var actual := _get_addable_quantity(item, quantity, item.max_quantity)
		# Add the item to the inventory for the first time, and we're done!
		_apply_first_add(item, actual, target)
		item_added.emit(item, target)
		await item_add_done
		return

	# If we are here, we have at least one item in the inventory.
	# Stop if we can have only one (or less for good measure, but the value is forced by
	# a setter, so it should never be possible).
	if item.max_quantity <= 1:
		PopochiuUtils.print_warning(
			"Couldn't add %s. It is already in %s's inventory."
			% [item.script_name, target.script_name]
		)
		await get_tree().process_frame
		return

	var actual := _get_addable_quantity(item, quantity, item.max_quantity - item.quantity_owned)
	# Stop if there is no room left for this item.
	if actual <= 0:
		PopochiuUtils.print_warning(
			"Couldn't add %s to %s. Max quantity exceeded."
			% [item.script_name, target.script_name]
		)
		await get_tree().process_frame
		return

	# We're at the end, add the items and we're done.
	# Exceeding quantity is signaled by _apply_stack_add().
	_apply_stack_add(item, actual, target)



## Removes [param quantity] of [param item] from [param character]'s inventory (default:
## [member PopochiuICharacter.player]) and waits until any GUI transition has finished.
## Use [code]0[/code] to remove the full stack.
func remove_item(item: PopochiuInventoryItem, quantity: int = 0, character: PopochiuCharacter = null) -> void:
	var target := _resolve_character(character)
	if not is_instance_valid(target):
		PopochiuUtils.print_warning(
			"Couldn't remove %s. No valid character target." % item.script_name
		)
		await get_tree().process_frame
		return

	if quantity < 0:
		PopochiuUtils.print_warning(
			"Couldn't remove %d of %s from %s. Quantity must be 0 or greater."
			% [quantity, item.script_name, target.script_name]
		)
		await get_tree().process_frame
		return

	var qty_to_remove := quantity if quantity > 0 else item.quantity_owned
	if qty_to_remove >= item.quantity_owned:
		_apply_full_removal(item, target)
		item_removed.emit(item, target)
		await item_remove_done
		return

	_apply_partial_removal(item, qty_to_remove, target)

	await get_tree().process_frame


## Replaces [param item] in [param character]'s inventory (default:
## [member PopochiuICharacter.player]) with [param new_item] and waits until the GUI swap has
## finished. Replacing removes the whole collected quantity of [param item] and adds exactly one
## quantity of [param new_item].
func replace_item(item: PopochiuInventoryItem, new_item: PopochiuInventoryItem, character: PopochiuCharacter = null) -> void:
	var target := _resolve_character(character)
	if not is_instance_valid(target):
		PopochiuUtils.print_warning(
			"Couldn't replace %s. No valid character target." % item.script_name
		)
		await get_tree().process_frame
		return

	if not _can_replace_item(item, new_item, target):
		await get_tree().process_frame
		return

	_apply_full_removal(item, target)

	if new_item.quantity_owned == 0:
		_apply_first_add(new_item, 1, target)
	else:
		_apply_stack_add(new_item, 1, target)

	item_replaced.emit(item, new_item, target)
	await item_replace_done


## Registers an inventory item that is already present in a GUI scene without running the full
## add-item flow. Associates it with [param character]'s inventory (default:
## [member PopochiuICharacter.player]).
func register_existing_item(item: PopochiuInventoryItem, character: PopochiuCharacter = null) -> void:
	var target := _resolve_character(character)
	if not is_instance_valid(target) or not is_instance_valid(item):
		return

	if item.quantity_owned == 0:
		_apply_first_add(item, 1, target)
		return

	item.ever_collected = true
	_register_item(item, target)


## Applies the deprecated [member PopochiuInventoryItem.in_inventory] setter semantics without
## emitting inventory signals or awaiting GUI transitions. Use [method add_item] and
## [method remove_item] for normal gameplay flow.
func set_item_in_inventory_bg(item: PopochiuInventoryItem, value: bool, character: PopochiuCharacter = null) -> void:
	var target := _resolve_character(character)
	if not is_instance_valid(target) or not is_instance_valid(item):
		return

	if value:
		if item.quantity_owned == 0:
			_apply_first_add(item, 1, target)
			return

		item.ever_collected = true
		_register_item(item, target)
		return

	_apply_full_removal(item, target)


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


## Returns [code]true[/code] if the item identified by [param item_name] is currently in
## [param character]'s inventory (default: [member PopochiuICharacter.player]).
func is_item_in_inventory(item_name: String, character: PopochiuCharacter = null) -> bool:
	var target := _resolve_character(character)
	if not is_instance_valid(target):
		return false
	return target.inventory.has(item_name)


## Returns [code]true[/code] if the item identified by [param item_name] is in any character's
## inventory. Used for props with [member PopochiuProp.link_to_item].
func is_item_in_any_inventory(item_name: String) -> bool:
	for c_name: String in PopochiuUtils.c.characters_states:
		var c: PopochiuCharacter = PopochiuUtils.c.get_character(c_name)
		if is_instance_valid(c) and c.inventory.has(item_name):
			return true
	return false


## Returns [code]true[/code] if the item identified by [param item_name] has ever been collected
## by any character.
func has_item_been_collected(item_name: String) -> bool:
	var i: PopochiuInventoryItem = get_item_instance(item_name)
	return is_instance_valid(i) and i.ever_collected


## Returns [code]true[/code] if [param character]'s inventory (default:
## [member PopochiuICharacter.player]) has reached the inventory limit configured in the
## project settings. The limit counts occupied slots, not total owned quantity, so a stacked item
## still occupies a single slot and counts as [code]1[/code].
func is_full(character: PopochiuCharacter = null) -> bool:
	var target := _resolve_character(character)
	if not is_instance_valid(target):
		return false
	return (
		PopochiuUtils.e.settings.inventory_limit > 0
		and PopochiuUtils.e.settings.inventory_limit == target.inventory.size()
	)


## Deselects the [member active] item.
func deselect_active() -> void:
	active = null


## Returns the number of [param item_name] currently owned by [param character] (default:
## [member PopochiuICharacter.player]).
## Returns [code]0[/code] if the item is not in the inventory.
func get_item_quantity(item_name: String, character: PopochiuCharacter = null) -> int:
	var target := _resolve_character(character)
	if not is_instance_valid(target):
		return 0
	var item: PopochiuInventoryItem = target.inventory.get(item_name, null) as PopochiuInventoryItem
	return item.quantity_owned if is_instance_valid(item) else 0


#endregion

#region SetGet #####################################################################################
func set_active(value: PopochiuInventoryItem) -> void:
	if is_instance_valid(active):
		active.unselected.emit()
	
	active = value
	
	item_selected.emit(active)


## @deprecated Use [member PopochiuCharacter.inventory] instead.
func _get_items() -> Array:
	PopochiuUtils.print_warning(
		"I.items is deprecated. Use C.player.inventory.keys() instead."
	)
	return PopochiuUtils.c.player.inventory.keys() if is_instance_valid(PopochiuUtils.c.player) else []


func _set_items(_value: Array) -> void:
	PopochiuUtils.print_warning(
		"I.items is deprecated and read-only. Use add()/remove() instead."
	)


#endregion

#region Private ####################################################################################
# Resolves the target character for inventory operations.
# Returns [param character] if valid, otherwise returns the player character.
# If neither is available, returns null.
func _resolve_character(character: PopochiuCharacter) -> PopochiuCharacter:
	if is_instance_valid(character):
		return character
	if is_instance_valid(PopochiuUtils.c.player):
		return PopochiuUtils.c.player
	return null
func _get_addable_quantity(
	item: PopochiuInventoryItem, requested: int, available_limit: int
) -> int:
	var actual := mini(requested, available_limit)
	if actual < requested:
		PopochiuUtils.print_warning(
			"Couldn't add all %d of %s. Capped at max_quantity of %d."
			% [requested, item.script_name, item.max_quantity]
		)

	return actual


func _can_replace_item(item: PopochiuInventoryItem, new_item: PopochiuInventoryItem, character: PopochiuCharacter) -> bool:
	var item_name := item.script_name if is_instance_valid(item) else "<invalid item>"
	var new_item_name := new_item.script_name if is_instance_valid(new_item) else "<invalid item>"

	if not is_instance_valid(item) or item.quantity_owned <= 0:
		PopochiuUtils.print_warning(
			"Couldn't replace %s. Item is not in %s's inventory." % [item_name, character.script_name]
		)
		return false

	if not is_instance_valid(new_item):
		PopochiuUtils.print_warning(
			"Couldn't replace %s. Replacement item is invalid." % item_name
		)
		return false

	if item == new_item:
		PopochiuUtils.print_warning(
			"Couldn't replace %s with itself." % item_name
		)
		return false

	if new_item.quantity_owned == 0:
		return true

	if new_item.max_quantity > 1 and new_item.quantity_owned < new_item.max_quantity:
		return true

	PopochiuUtils.print_warning(
		"Couldn't replace %s with %s. Replacement item can't receive one more unit."
		% [item_name, new_item_name]
	)
	return false


func _register_item(item: PopochiuInventoryItem, character: PopochiuCharacter) -> void:
	if not character.inventory.has(item.script_name):
		character.inventory[item.script_name] = item


func _apply_first_add(item: PopochiuInventoryItem, quantity: int, character: PopochiuCharacter) -> void:
	_register_item(item, character)
	item.quantity_owned = quantity
	item.ever_collected = true
	# Also mark the global cached instance so has_item_been_collected() works globally.
	var global_instance: PopochiuInventoryItem = _item_instances.get(item.script_name, null)
	if is_instance_valid(global_instance) and global_instance != item:
		global_instance.ever_collected = true
	character.inventory_item_added.emit(item, quantity)
	item._on_added_to_inventory() # Call to Virtual, not Private


func _apply_stack_add(item: PopochiuInventoryItem, quantity: int, character: PopochiuCharacter) -> void:
	var old_qty := item.quantity_owned
	item.quantity_owned += quantity
	item._on_quantity_changed(old_qty, item.quantity_owned)  # Call to Virtual, not Private
	character.inventory_item_quantity_updated.emit(item, old_qty, item.quantity_owned)
	item_quantity_updated.emit(item, item.quantity_owned, character)


func _apply_full_removal(item: PopochiuInventoryItem, character: PopochiuCharacter) -> void:
	item.quantity_owned = 0
	character.inventory.erase(item.script_name)
	character.inventory_item_removed.emit(item, 0)
	set_active_item(null)


func _apply_partial_removal(item: PopochiuInventoryItem, quantity: int, character: PopochiuCharacter) -> void:
	var old_qty := item.quantity_owned
	item.quantity_owned -= quantity
	item._on_quantity_changed(old_qty, item.quantity_owned) # Call to Virtual, not Private
	character.inventory_item_quantity_updated.emit(item, old_qty, item.quantity_owned)
	item_quantity_updated.emit(item, item.quantity_owned, character)


#endregion
