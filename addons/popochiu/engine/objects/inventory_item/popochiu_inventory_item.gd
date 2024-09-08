@icon("res://addons/popochiu/icons/inventory_item.png")
class_name PopochiuInventoryItem
extends TextureRect
## An inventory item.
##
## Characters can collect these items and use them on things. They can also handle interactions and
## be used on other objects (i.e. [PopochiuClickable] or other inventory items).

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


## Whether this item is actually inside the inventory GUI.
var in_inventory := false : set = set_in_inventory
## Stores the last [enum MouseButton] pressed on this object.
var last_click_button := -1 # NOTE Don't know if this will make sense, or if it this object should
# emit a signal about the click (command execution)


#region Godot ######################################################################################
func _ready():
	mouse_entered.connect(_toggle_description.bind(true))
	mouse_exited.connect(_toggle_description.bind(false))
	gui_input.connect(_on_gui_input)


#endregion

#region Virtual ####################################################################################
## Called when the item is clicked in the inventory GUI.
## [i]Virtual[/i].
func _on_click() -> void:
	pass


## Called when the item is right clicked in the inventory GUI.
## [i]Virtual[/i].
func _on_right_click() -> void:
	pass


## Called when the item is middle clicked in the inventory GUI.
## [i]Virtual[/i].
func _on_middle_click() -> void:
	pass


## When the item is clicked and there is another [param item] currently selected.
## [i]Virtual[/i].
func _on_item_used(item: PopochiuInventoryItem) -> void:
	pass


## Called after the item is added to the inventory.
## [i]Virtual[/i].
func _on_added_to_inventory() -> void:
	pass


## Called when the item is discarded from the inventory.
## [i]Virtual[/i].
func _on_discard() -> void:
	pass


#endregion

#region Public #####################################################################################
## Adds this item to the inventory. If [param animate] is [code]true[/code], the inventory GUI will
## show an animation as a feedback of this action. It will depend on the implementation of the
## inventory in the GUI.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
## [br][br]Example of how to use it when interacting with a [PopochiuProp]:
## [codeblock]
## func on_click() -> void:
##     E.queue([
##         C.queue_walk_to_clicked(),
##         "Player: I'm gonna take this with me",
##         I.Key.queue_add()
##     ])
## [/codeblock]
func queue_add(animate := true) -> Callable:
	return func (): await add(animate)


## Adds this item to the inventory. If [param animate] is [code]true[/code], the inventory GUI will
## show an animation as a feedback of this action. It will depend on the implementation of the
## inventory in the GUI.
## [br][br]Example of how to use it when interacting with a [PopochiuProp]:
## [codeblock]
## func on_click() -> void:
##     await C.walk_to_clicked()
##     await C.player.say("I'm gonna take this with me")
##     await I.Key.add()
## [/codeblock]
func add(animate := true) -> void:
	if I.is_full():
		PopochiuUtils.print_error("Couldn't add %s. Inventory is full." % script_name)
		
		await get_tree().process_frame
		return
	
	if not in_inventory:
		G.block()

		I.items.append(script_name)
		
		I.item_added.emit(self, animate)
		in_inventory = true
		
		await I.item_add_done

		G.unblock(true)

		return
	
	await get_tree().process_frame


## Adds this item to the inventory and makes it the current selected item (the cursor will look like
## the item's texture). Pass [param animate] as [code]false[/code] if you do not want the inventory
## GUI to animate when the item is added.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_add_as_active(animate := true) -> Callable:
	return func (): await add_as_active(animate)


## Adds this item to the inventory and makes it the current selected item (the cursor will look like
## the item's texture). Pass [param animate] as [code]false[/code] if you do not want the inventory
## GUI to animate when the item is added.
func add_as_active(animate := true) -> void:
	await add(animate)
	
	I.set_active_item(self)


## Removes the item from the inventory (its instance will be kept in memory). Pass [param animate]
## as [code]true[/code] if you want the inventory GUI to animate when the item is removed.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
## [br][br]Example of how to use it when using an item on a [PopochiuProp]:
## [codeblock]
## func on_item_used(item: PopochiuInventoryItem) -> void:
##     if item == I.ToyCar:
##         E.queue([
##             "Player: Here is your toy car",
##             I.ToyCar.queue_remove()
##         ])
## [/codeblock]
func queue_remove(animate := false) -> Callable:
	return func (): await remove(animate)


## Removes the item from the inventory (its instance will be kept in memory). Pass [param animate]
## as [code]true[/code] if you want the inventory GUI to animate when the item is removed.
## [br][br]Example of how to use it when using an item on a [PopochiuProp]:
## [codeblock]
## func on_item_used(item: PopochiuInventoryItem) -> void:
##     if item == I.ToyCar:
##         await C.player.say("Here is your toy car")
##         await I.ToyCar.remove()
## [/codeblock]
func remove(animate := false) -> void:
	in_inventory = false
	
	I.items.erase(script_name)
	I.set_active_item(null)
	# TODO: Maybe this signal should be triggered once the await has finished
	I.item_removed.emit(self, animate)
	
	await I.item_remove_done
	
	G.unblock()


## Replaces this inventory item by [param new_item]. Useful when combining items.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
## [br][br]Example of how to use it when combining two inventory items:
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


## Replaces this inventory item by [param new_item]. Useful when combining items.
## [br][br]Example of how to use it when combining two inventory items:
## [codeblock]
## # This is the script of the InventoryItemHook.gd (I.Hook)
## func on_item_used(item: PopochiuInventoryItem) -> void:
##     if item == I.Rope:
##         await I.Rope.remove()
##         await replace(I.RopeWithHook)
## [/codeblock]
func replace(new_item: PopochiuInventoryItem) -> void:
	in_inventory = false
	
	I.items.erase(script_name)
	I.set_active_item(null)
	I.items.append(new_item.script_name)
	new_item.in_inventory = true
	
	I.item_replaced.emit(self, new_item)
	
	await I.item_replace_done
	
	# NOTE: Inventory items should not be in charge of handling the GUI unblock. This should be
	# 		done by the GUI itself.
	G.unblock()


# NOTE: Maybe this is not necessary since we can have the same with [method queue_remove].
## Removes the item from the inventory (its instance will be kept in memory). Pass [param animate]
## as [code]true[/code] if you want the inventory GUI to animate when the item is removed.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_discard(animate := false) -> Callable:
	return func (): await discard(animate)


# NOTE: Maybe this is not necessary since we can have the same with [method remove].
## Removes the item from the inventory (its instance will be kept in memory). Pass [param animate]
## as [code]true[/code] if you want the inventory GUI to animate when the item is removed.
func discard(animate := false) -> void:
	_on_discard()
	
	I.items.erase(script_name)
	I.item_discarded.emit(self)
	
	await remove(animate)


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


## Triggers the proper GUI command for the clicked mouse button identified with [param button_idx],
## which can be [enum MouseButton].MOUSE_BUTTON_LEFT, [enum MouseButton].MOUSE_BUTTON_RIGHT or
## [enum MouseButton].MOUSE_BUTTON_MIDDLE.
func handle_command(button_idx: int) -> void:
	var command: String = E.get_current_command_name().to_snake_case()
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
	
	E.add_history({
		action = suffix if command.is_empty() else command,
		target = description
	})
	
	await call(prefix % suffix)


## Deselects this item if it is the current [member PopochiuIInventory.active] item.
func deselect() -> void:
	if I.active and I.active == self:
		I.active = null


#endregion

#region SetGet #####################################################################################
func set_in_inventory(value: bool) -> void:
	in_inventory = value
	
	if in_inventory: _on_added_to_inventory()


func get_description() -> String:
	if Engine.is_editor_hint():
		if description.is_empty():
			description = name
		return description
	return E.get_text(description)


#endregion

#region Private ####################################################################################
func _toggle_description(is_hover: bool) -> void:
	if is_hover:
		G.mouse_entered_inventory_item.emit(self)
	else:
		last_click_button = -1
		
		G.mouse_exited_inventory_item.emit(self)


func _on_gui_input(event: InputEvent) -> void: 
	if not PopochiuUtils.is_click_or_touch_pressed(event): return
	
	var event_index := PopochiuUtils.get_click_or_touch_index(event)
	
	# Fix #224 Clean E.clicked when an inventory item is clicked to ensure that the event is not
	# mishandled by the GUI
	if E.clicked:
		E.clicked = null
	
	I.clicked = self
	last_click_button = event_index
	
	match event_index:
		MOUSE_BUTTON_LEFT:
			if I.active:
				await on_item_used(I.active)
			else:
				if DisplayServer.is_touchscreen_available():
					G.mouse_entered_inventory_item.emit(self)
				
				await handle_command(event_index)
		MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
			if not I.active:
				await handle_command(event_index)
	
	I.clicked = null


#endregion
