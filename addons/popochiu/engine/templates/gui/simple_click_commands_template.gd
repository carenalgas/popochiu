# @popochiu-docs-ignore-class
extends SimpleClickCommands


# Called when `E.command_fallback()` is triggered.
# By default this checks whether the clicked object is a `PopochiuClickable` or
# a `PopochiuInventoryItem` and invokes the corresponding method based on the
# object type and mouse button.
func fallback() -> void:
	super()


# Called when the player left-clicks a `PopochiuClickable`.
func click_clickable() -> void:
	super()


# Called when the player right-clicks a `PopochiuClickable`.
func right_click_clickable() -> void:
	super()


# Called when the player left-clicks a `PopochiuInventoryItem`.
func click_inventory_item() -> void:
	super()


# Called when the player right-clicks a `PopochiuInventoryItem`.
func right_click_inventory_item() -> void:
	super()
