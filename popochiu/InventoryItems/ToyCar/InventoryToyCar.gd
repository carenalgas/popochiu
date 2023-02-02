extends PopochiuInventoryItem

const State := preload('InventoryToyCarState.gd')

var state: State = preload('InventoryToyCar.tres')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
# TODO: Overwrite Godot's methods as needed


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# When the item is clicked in the inventory
func on_interact() -> void:
	# Replace the call to .on_interact() to implement your code. This only makes
	# the default behavior to happen.
	.on_interact()


# When the item is right clicked in the inventory
func on_look() -> void:
	I.discard_item(script_name, false)


# When the item is clicked and there is another inventory item selected
func on_item_used(item: PopochiuInventoryItem) -> void:
	# Replace the call to .on_item_used(item) to implement your code. This only
	# makes the default behavior to happen.
	.on_item_used(item)


# Actions to excecute after the item is added to the Inventory
func on_added_to_inventory() -> void:
	# Replace the call to .on_added_to_inventory() to implement your code. This only
	# makes the default behavior to happen.
	.on_added_to_inventory()
