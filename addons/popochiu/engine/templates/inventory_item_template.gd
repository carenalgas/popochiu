# @popochiu-docs-ignore-class
extends PopochiuInventoryItem

const Data := preload('inventory_item_state_template.gd')

var state: Data = null


#region Virtual ####################################################################################
# Called when the item is clicked in the inventory
func _on_click() -> void:
	# Replace the call to E.command_fallback() to implement your code.
	PopochiuUtils.e.command_fallback()


# Called when the item is right-clicked in the inventory
func _on_right_click() -> void:
	# Replace the call to E.command_fallback() to implement your code.
	PopochiuUtils.e.command_fallback()


# Called when the item is middle-clicked in the inventory
func _on_middle_click() -> void:
	# Replace the call to E.command_fallback() to implement your code.
	PopochiuUtils.e.command_fallback()


# Called when the item is clicked while another inventory item is selected
func _on_item_used(_item: PopochiuInventoryItem) -> void:
	# Replace the call to E.command_fallback() with your own logic.
	PopochiuUtils.e.command_fallback()
	# Example: if a Key is used on this item, make the player say something.
#	if _item == I.Key:
#		await C.player.say("This item has no lock!")


# Called when the item is added to the inventory
func _on_added_to_inventory() -> void:
	# Replace the call to `super()` to implement custom behavior.
	# Calling `super()` preserves default behavior as well.
	super()


# Called when the item is discarded from the inventory
func _on_discard() -> void:
	# Replace the call to `super()` to implement custom behavior.
	# Calling `super()` preserves default behavior as well.
	super()


#endregion
