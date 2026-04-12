# @popochiu-docs-category game-objects
@icon("res://addons/popochiu/icons/inventory_item.png")
class_name PopochiuInventoryItem
extends TextureRect
## Represents an item that can be collected, stored in the inventory, and used on objects.
##
## Inventory items can handle click interactions and be combined with other items or used on
## [PopochiuClickable] objects.

## Used to allow devs to define the cursor type for the clickable.
const CURSOR := preload("res://addons/popochiu/engine/cursor/cursor.gd")

## Emitted when the item is selected. 
signal selected(item)
## Emitted when the item is unselected (in most GUIs, this happens when right-clicking anywhere on
## the screen).
signal unselected

## The identifier of the item used in scripts.
@export var script_name := ""
## The text shown to players when the cursor hovers the item.
@export var description := "" : get = get_description
## The cursor to use when the mouse hovers the object.
@export var cursor: CURSOR.Type = CURSOR.Type.USE
## The maximum number of this item the player can own at one time.[br]
## Defaults to [code]1[/code], which preserves the legacy single-item behaviour.
## Cannot be set below [code]1[/code]: a value of zero or less would make the item permanently
## un-addable and break the first-add vs. stacking logic inside [method add].
@export var max_quantity := 1 : set = set_max_quantity


## The number of this item the player currently owns. Use this property to check ownership and
## stack sizes.
var quantity_owned := 0
# @deprecated: Use [member quantity_owned] instead. Kept for backward compatibility
#
## Reading returns [code]true[/code] if [member quantity_owned] is greater than [code]0[/code].[br]
## Setting [code]true[/code] ensures [member quantity_owned] is at least [code]1[/code].[br]
## Setting [code]false[/code] sets [member quantity_owned] to [code]0[/code].[br]
## [b]Warning:[/b] Unlike [method add] and [method remove], this setter does not emit inventory
## signals and does not update the inventory GUI. Use [method add] and [method remove] instead.
var in_inventory: bool :
	get: return quantity_owned > 0
	set(value): _set_in_inventory(value)
## Whether this item has ever been in the inventory. Once true, it stays true.
var ever_collected := false : set = set_ever_collected
## Stores the last [enum MouseButton] pressed on this object.
var last_click_button := -1 # NOTE Don't know if this will make sense, or if it this object should
# emit a signal about the click (command execution)

# Dictionary storing command usage counts {command_id (Commands): count (int)}
var _command_usage_count := {}


#region Godot ######################################################################################
func _ready():
	mouse_entered.connect(_toggle_description.bind(true))
	mouse_exited.connect(_toggle_description.bind(false))
	gui_input.connect(_on_gui_input)


#endregion

#region Virtual ####################################################################################
## Called when the item is clicked in the inventory GUI.[br]
## Override this to define what happens when the item is clicked.
func _on_click() -> void:
	pass


## Called when the item is right-clicked in the inventory GUI.[br]
## Override this to define what happens when the item is right-clicked.
func _on_right_click() -> void:
	pass


## Called when the item is middle-clicked in the inventory GUI.[br]
## Override this to define what happens when the item is middle-clicked.
func _on_middle_click() -> void:
	pass


## Called when this item is clicked while another [param item] is selected.[br]
## Override this to define what happens when this item is used on another item.
func _on_item_used(item: PopochiuInventoryItem) -> void:
	pass


## Called after the item is added to the inventory.[br]
## Override this to implement custom behavior (e.g. playing a sound).
func _on_added_to_inventory() -> void:
	pass


## Called when the item is discarded from the inventory.[br]
## Override this to implement custom behavior (e.g. playing a sound).
func _on_discard() -> void:
	pass


## Called when [member quantity_owned] changes due to stacking or partial removal — i.e., when
## the item slot stays in the inventory but the count changes.[br]
## Override this to react to quantity changes (e.g. play a different sound for 1 vs. many coins).
func _on_quantity_changed(_old_qty: int, _new_qty: int) -> void:
	pass


#endregion

#region Public #####################################################################################
## Adds [param quantity] of this item to the inventory. If [param animate] is [code]true[/code],
## the inventory GUI shows an animation for the first add only; subsequent stack additions do not
## animate. [param quantity] defaults to [code]1[/code].
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
##
## Example:
## [codeblock]
## func on_click() -> void:
##     E.queue([
##         C.queue_walk_to_clicked(),
##         "Player: I'm gonna take this with me",
##         I.Key.queue_add()
##     ])
## [/codeblock]
func queue_add(quantity := 1, animate := true) -> Callable:
	return func (): await add(quantity, animate)


## Adds [param quantity] of this item to the inventory. [param quantity] defaults to [code]1[/code].
## If [param animate] is [code]true[/code], the inventory GUI shows an animation (only on the first
## add; subsequent stack additions only emit [signal PopochiuIInventory.item_quantity_updated]).
##
## Example:
## [codeblock]
## func on_click() -> void:
##     await C.walk_to_clicked()
##     await C.player.say("I'm gonna take this with me")
##     await I.Key.add()
##     # Add three coins at once:
##     await I.Coin.add(3)
## [/codeblock]
func add(quantity := 1, animate := true) -> void:
	if quantity_owned == 0:
		# --- First add: create the inventory slot and run the full GUI lifecycle ---
		if PopochiuUtils.i.is_full():
			PopochiuUtils.print_error("Couldn't add %s. Inventory is full." % script_name)
			
			await get_tree().process_frame
			return
		
		PopochiuUtils.g.block()
		
		PopochiuUtils.i.items.append(script_name)
		
		PopochiuUtils.i.item_added.emit(self, animate)
		# Assign quantity_owned directly — do NOT go through the in_inventory setter here.
		# add() is the lifecycle owner for first-add: it has already handled g.block(),
		# item_added, and the await sequence below. Going through the setter would call
		# _on_added_to_inventory() a second time and cannot represent a quantity > 1.
		# Clamp to max_quantity even on first add: the caller may request more than allowed.
		var clamped_qty := mini(quantity, max_quantity)
		if clamped_qty < quantity:
			PopochiuUtils.print_warning(
				"Couldn't add all %d of %s. Capped at max_quantity of %d."
				% [quantity, script_name, max_quantity]
			)
		quantity_owned = clamped_qty
		ever_collected = true
		_on_added_to_inventory()

		await PopochiuUtils.i.item_add_done

		PopochiuUtils.g.unblock(true)
		return
	
	if max_quantity > 1:
		# --- Stack add: increase quantity without touching the inventory slot ---
		var clamped_qty := mini(quantity, max_quantity - quantity_owned)
		
		if clamped_qty < quantity:
			PopochiuUtils.print_warning(
				"Couldn't add all %d of %s. Capped at max_quantity of %d."
				% [quantity, script_name, max_quantity]
			)
		
		if clamped_qty > 0:
			var old_qty := quantity_owned
			quantity_owned += clamped_qty
			_on_quantity_changed(old_qty, quantity_owned)
			PopochiuUtils.i.item_quantity_updated.emit(self, quantity_owned)
		
		await get_tree().process_frame
		return
	
	# --- Silent no-op for max_quantity == 1 ---
	# Back-compat guarantee: games with max_quantity = 1 (the default) often call add() from
	# multiple code paths and expect redundant calls on an already-held item to silently do nothing.
	await get_tree().process_frame


## Adds [param quantity] of this item to the inventory and makes it the active item (cursor shows
## the item's texture). Pass [param animate] as [code]false[/code] to skip the inventory GUI
## animation.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_add_as_active(quantity := 1, animate := true) -> Callable:
	return func (): await add_as_active(quantity, animate)


## Adds [param quantity] of this item to the inventory and makes it the active item (cursor shows
## the item's texture). Pass [param animate] as [code]false[/code] to skip the inventory GUI
## animation.
func add_as_active(quantity := 1, animate := true) -> void:
	await add(quantity, animate)
	
	PopochiuUtils.i.set_active_item(self)


## Removes [param quantity] of this item from the inventory (instance is kept in memory).
## Call without params or pass [param quantity] as [code]0[/code] (the default) to remove the full stack.
## Pass [param animate] as [code]true[/code] to animate the removal in the inventory GUI.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
##
## Example:
## [codeblock]
## func on_item_used(item: PopochiuInventoryItem) -> void:
##     if item == I.ToyCar:
##         E.queue([
##             "Player: Here is your toy car",
##             I.ToyCar.queue_remove()
##         ])
## [/codeblock]
func queue_remove(quantity: int = 0, animate := false) -> Callable:
	return func (): await remove(quantity, animate)


## Removes [param quantity] of this item from the inventory (instance is kept in memory).
## Call without params or pass [param quantity] as [code]0[/code] (the default) to remove the full stack.
## Pass [param animate] as [code]true[/code] to animate the removal in the inventory GUI.
##
## Example:
## [codeblock]
## func on_item_used(item: PopochiuInventoryItem) -> void:
##     if item == I.ToyCar:
##         await C.player.say("Here is your toy car")
##         await I.ToyCar.remove()
## [/codeblock]
func remove(quantity: int = 0, animate := false) -> void:
	var qty_to_remove := quantity if quantity > 0 else quantity_owned
	
	if quantity_owned - qty_to_remove > 0:
		# --- Partial removal: reduce quantity without removing the inventory slot ---
		var old_qty := quantity_owned
		quantity_owned -= qty_to_remove
		_on_quantity_changed(old_qty, quantity_owned)
		PopochiuUtils.i.item_quantity_updated.emit(self, quantity_owned)
		
		await get_tree().process_frame
		return
	
	# --- Full removal: tear down the inventory slot and run the full GUI lifecycle ---
	# Assign quantity_owned directly — do NOT go through the in_inventory setter here.
	# remove() is the lifecycle owner for full removal: it must control signal sequencing and
	# handle g.unblock(). The setter does not emit item_removed or call g.unblock().
	quantity_owned = 0
	
	PopochiuUtils.i.items.erase(script_name)
	PopochiuUtils.i.set_active_item(null)
	# TODO: Maybe this signal should be triggered once the await has finished
	PopochiuUtils.i.item_removed.emit(self, animate)
	
	await PopochiuUtils.i.item_remove_done
	
	PopochiuUtils.g.unblock()


## Replaces this inventory item with [param new_item]. Useful when combining items.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
##
## Example:
## [codeblock]
## # This is the script of the InventoryItemHook.gd (I.Hook)
## func on_item_used(item: PopochiuInventoryItem) -> void:
##     if item == I.Rope:
##         E.queue([
##             I.Rope.queue_remove(),
##             queue_replace(I.RopeWithHook)
##         ])
## [/codeblock]
func queue_replace(new_item: PopochiuInventoryItem) -> Callable:
	return func (): await replace(new_item)


## Replaces this inventory item with [param new_item]. Useful when combining items.
##
## Example:
## [codeblock]
## # This is the script of the InventoryItemHook.gd (I.Hook)
## func on_item_used(item: PopochiuInventoryItem) -> void:
##     if item == I.Rope:
##         await I.Rope.remove()
##         await replace(I.RopeWithHook)
## [/codeblock]
func replace(new_item: PopochiuInventoryItem) -> void:
	# Assign quantity_owned directly on both items; do NOT call add(), remove(), or go through
	# the in_inventory setter. replace() orchestrates its own atomic GUI flow (item_replaced ->
	# await item_replace_done -> g.unblock()) in a single sequence. Routing through add() would
	# trigger a second g.block(), item_added signal, and await item_add_done, corrupting that
	# sequence. The setter would call _on_added_to_inventory() on new_item before the GUI
	# replacement animation is complete.
	quantity_owned = 0
	
	PopochiuUtils.i.items.erase(script_name)
	PopochiuUtils.i.set_active_item(null)
	PopochiuUtils.i.items.append(new_item.script_name)
	new_item.quantity_owned = 1
	
	PopochiuUtils.i.item_replaced.emit(self, new_item)
	
	await PopochiuUtils.i.item_replace_done
	
	# NOTE: Inventory items should not be in charge of handling the GUI unblock. This should be
	# 		done by the GUI itself.
	PopochiuUtils.g.unblock()


# NOTE: Maybe this is not necessary since we can have the same with [method queue_remove].
## Removes the item from the inventory without destroying the instance. Pass [param animate] as
## [code]true[/code] to animate the removal in the inventory GUI.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_discard(animate := false) -> Callable:
	return func (): await discard(animate)


# NOTE: Maybe this is not necessary since we can have the same with [method remove].
## Removes the item from the inventory without destroying the instance. Pass [param animate] as
## [code]true[/code] to animate the removal in the inventory GUI.
func discard(animate := false) -> void:
	_on_discard()
	
	# refs #349: The manual items.erase() that was here has been removed. It was a latent bug:
	# remove() already erases this item from items[] as part of its own lifecycle, so the
	# double-erase was causing item_removed to be emitted before the GUI animation had a
	# chance to complete. This is a more robust fix than the original workaround.
	PopochiuUtils.i.item_discarded.emit(self)
	
	await remove(0, animate)


## Makes this item the current active item (the cursor will look like the item's texture).
func set_active(_ignore_block := false) -> void:
	selected.emit(self)


## Called when the item is clicked in the inventory.
func on_click() -> void:
	await _on_click()


## Called when the item is right clicked in the inventory.
func on_right_click() -> void:
	await _on_right_click()


## Called when the item is middle clicked in the inventory.
func on_middle_click() -> void:
	await _on_middle_click()


## Called when the item is clicked and there is another [param item] currently selected.
func on_item_used(item: PopochiuInventoryItem) -> void:
	await _on_item_used(item)
	# after item has been used return to normal state
	PopochiuUtils.i.active = null


## Triggers the proper GUI command for the clicked mouse button identified with [param button_idx],
## which can be [enum MouseButton].MOUSE_BUTTON_LEFT, [enum MouseButton].MOUSE_BUTTON_RIGHT or
## [enum MouseButton].MOUSE_BUTTON_MIDDLE.
func handle_command(button_idx: int) -> void:
	var command: String = PopochiuUtils.e.get_current_command_name().to_snake_case()
	var suffix := "click"
	var prefix := "on_%s"
	
	match button_idx:
		MOUSE_BUTTON_RIGHT:
			suffix = "right_" + suffix
		MOUSE_BUTTON_MIDDLE:
			suffix = "middle_" + suffix
	
	if not command.is_empty():
		var command_method := suffix.replace("click", command)
		
		if has_method(prefix % command_method):
			suffix = command_method
	
	PopochiuUtils.e.add_history({
		action = suffix if command.is_empty() else command,
		target = description
	})
	
	await call(prefix % suffix)

	# Track command usage
	_increment_command_count(PopochiuUtils.e.current_command)


## Deselects this item if it is the current [member PopochiuIInventory.active] item.
func deselect() -> void:
	if PopochiuUtils.i.active and PopochiuUtils.i.active == self:
		PopochiuUtils.i.active = null


## Returns [code]true[/code] if the [param command] has ever been invoked on this object.
## This function is typically used in a command handler to provide different behaviors
## depending on whether the command has been used before or not.
func ever_invoked(command: int) -> bool:
	return _command_usage_count.has(command) and _command_usage_count[command] > 0


## Returns [code]true[/code] if this is the first time the [param command] is being invoked on this object.
## This function is typically used in a command handler to provide different behaviors
## depending on whether the command has been used before or not.
func first_invoked(command: int) -> bool:
	return not ever_invoked(command)


## Returns the number of times the [param command] has been invoked on this object.
func count_invoked(command: int) -> int:
	return _command_usage_count.get(command, 0)


#endregion

#region SetGet #####################################################################################
func set_max_quantity(value: int) -> void:
	# Clamp to a minimum of 1: a value below 1 would make the item permanently un-addable
	# and break the first-add vs. stacking logic inside add().
	max_quantity = max(1, value)


func set_ever_collected(value: bool) -> void:
	# Once true, ever_collected can never be false again
	if ever_collected:
		return
	
	ever_collected = value


func get_description() -> String:
	if Engine.is_editor_hint():
		if description.is_empty():
			description = name
		return description
	return PopochiuUtils.e.get_text(description)


#endregion

#region Private ####################################################################################
# This setter MUST NOT call add() or any other public method. GUI components
# inventory_bar.gd and simple_click_bar.gd both assign in_inventory = true during scene
# _ready() to re-register items that were placed in the scene manually. Those calls expect
# zero side-effects: no g.block(), no item_added signal, no await item_add_done. Routing
# through add() here would corrupt GUI state during initialisation.
func _set_in_inventory(value: bool) -> void:
	if value:
		if quantity_owned == 0:
			quantity_owned = 1
			_on_added_to_inventory()
	else:
		quantity_owned = 0


# Increments the usage count for the specified command
func _increment_command_count(command_id: int) -> void:
	_command_usage_count.get_or_add(command_id, 0)
	_command_usage_count[command_id] += 1


func _toggle_description(is_hover: bool) -> void:
	if is_hover:
		PopochiuUtils.g.mouse_entered_inventory_item.emit(self)
	else:
		last_click_button = -1
		
		PopochiuUtils.g.mouse_exited_inventory_item.emit(self)


func _on_gui_input(event: InputEvent) -> void: 
	if not PopochiuUtils.is_click_or_touch_pressed(event): return
	
	var event_index := PopochiuUtils.get_click_or_touch_index(event)
	
	# Fix #224 Clean E.clicked when an inventory item is clicked to ensure that the event is not
	# mishandled by the GUI
	if PopochiuUtils.e.clicked:
		PopochiuUtils.e.clicked = null
	
	PopochiuUtils.i.clicked = self
	last_click_button = event_index
	
	match event_index:
		MOUSE_BUTTON_LEFT:
			if PopochiuUtils.i.active:
				await on_item_used(PopochiuUtils.i.active)
			else:
				if DisplayServer.is_touchscreen_available():
					PopochiuUtils.g.mouse_entered_inventory_item.emit(self)
				
				await handle_command(event_index)
		MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
			if not PopochiuUtils.i.active:
				await handle_command(event_index)
	
	PopochiuUtils.i.clicked = null


#endregion
