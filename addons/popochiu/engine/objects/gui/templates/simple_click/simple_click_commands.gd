class_name SimpleClickCommands
extends PopochiuCommands
## Defines the commands and fallback methods for the 2-click Context-sensitive GUI.
##
## In this GUI, players interact with objects in the game based on the clicked mouse button.
## Usually, the left click is used to INTERACT with objects, while the RIGHT click is used to
## EXAMINE objects. This behavior is based on the one used in Beneath A Steel Sky and Broken Sword.


#region Public #####################################################################################
## Called by [Popochiu] when a command doesn't have an associated method.
func fallback() -> void:
	if is_instance_valid(E.clicked):
		if E.clicked.last_click_button == MOUSE_BUTTON_LEFT:
			await click_clickable()
		elif E.clicked.last_click_button == MOUSE_BUTTON_RIGHT:
			await right_click_clickable()
		else:
			await RenderingServer.frame_post_draw
	
	if is_instance_valid(I.clicked):
		if I.clicked.last_click_button == MOUSE_BUTTON_LEFT:
			await click_inventory_item()
		elif E.clicked.last_click_button == MOUSE_BUTTON_RIGHT:
			await right_click_inventory_item()
		else:
			await RenderingServer.frame_post_draw


## Called when players click (LMB) a [PopochiuClickable].
func click_clickable() -> void:
	if I.active:
		await G.show_system_text(
			"Can't USE %s with %s" % [I.active.description, E.clicked.description]
		)
	else:
		await G.show_system_text("Can't INTERACT with it")


## Called when players right click (RMB) a [PopochiuClickable].
func right_click_clickable() -> void:
	await G.show_system_text("Can't EXAMINE it")


## Called when players click (LMB) a [PopochiuInvenoryItem].
func click_inventory_item() -> void:
	if I.active and I.active != I.clicked:
		await G.show_system_text(
			"Can't USE %s with %s" % [I.active.description, I.clicked.description]
		)
	else:
		I.clicked.set_active()


## Called when players right click (RMB) a [PopochiuInvenoryItem].
func right_click_inventory_item() -> void:
	await G.show_system_text('Nothing to see in this item')


#endregion
