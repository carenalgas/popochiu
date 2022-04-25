extends InventoryItem


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
# TODO: Overwrite Godot's methods as needed


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# When the item is clicked in the inventory
func on_interact() -> void:
	# Emit the "selected" signal to make the cursor get the appearance of this
	# item (emit_signal('selected', self))
	pass


# When the item is right clicked in the inventory
func on_look() -> void:
	pass


# When the item is clicked and there is another inventory item selected
func on_item_used(_item: InventoryItem) -> void:
	# Remove the _ from the _item parameter once you are ready to write this
	# functionality
	pass


# Actions to excecute after the item is added to the Inventory
func added_to_inventory() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
# TODO: Private methods can go here
