class_name SimpleClickCommands
extends PopochiuCommands


## Called when `E.command_fallback()` is triggered.
func fallback() -> void:
	if is_instance_valid(E.clicked):
		if E.clicked.last_click_button == MOUSE_BUTTON_LEFT:
			click_clickable()
		else:
			right_click_clickable()
	elif is_instance_valid(I.clicked):
		if I.clicked.last_click_button == MOUSE_BUTTON_LEFT:
			click_inventory_item()
		else:
			right_click_inventory_item()


## Called when players click (LMB) a `PopochiuClickable`.
func click_clickable() -> void:
	await G.show_system_text("Can't INTERACT with it")


## Called when players right click (RMB) a `PopochiuClickable`.
func right_click_clickable() -> void:
	await G.show_system_text("Can't EXAMINE it")


## Called when players click (LMB) a `PopochiuInvenoryItem`.
func click_inventory_item() -> void:
	pass


## Called when players right click (RMB) a `PopochiuInvenoryItem`.
func right_click_inventory_item() -> void:
	await G.show_system_text('Nothing to see in this item')
