extends SimpleClickCommands


# Called when `E.command_fallback()` is triggered.
# By default evaluates if the clicked object was a `PopochiuClickable` or a
# `PopochiuInventoryItem` and calls the corresponding method depending on the
# object type and the clicked mouse button.
func fallback() -> void:
	super()


# Called when players click (LMB) a `PopochiuClickable`.
func click_clickable() -> void:
	super()


# Called when players right click (RMB) a `PopochiuClickable`.
func right_click_clickable() -> void:
	super()


# Called when players click (LMB) a `PopochiuInventoryItem`.
func click_inventory_item() -> void:
	super()


# Called when players right click (RMB) a `PopochiuInventoryItem`.
func right_click_inventory_item() -> void:
	super()
