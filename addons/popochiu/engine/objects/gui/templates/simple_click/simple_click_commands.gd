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
	if is_instance_valid(PopochiuUtils.e.clicked):
		if PopochiuUtils.e.clicked.last_click_button == MOUSE_BUTTON_LEFT:
			await click_clickable()
		elif PopochiuUtils.e.clicked.last_click_button == MOUSE_BUTTON_RIGHT:
			await right_click_clickable()
		else:
			await RenderingServer.frame_post_draw
	
	if is_instance_valid(PopochiuUtils.i.clicked):
		if PopochiuUtils.i.clicked.last_click_button == MOUSE_BUTTON_LEFT:
			await click_inventory_item()
		elif PopochiuUtils.i.clicked.last_click_button == MOUSE_BUTTON_RIGHT:
			await right_click_inventory_item()
		else:
			await RenderingServer.frame_post_draw


## Called when players click (LMB) a [PopochiuClickable].
func click_clickable() -> void:
	if PopochiuUtils.i.active:
		await PopochiuUtils.g.show_system_text("Can't USE %s with %s" % [
			PopochiuUtils.i.active.description, PopochiuUtils.e.clicked.description
		])
	else:
		await PopochiuUtils.g.show_system_text("Can't INTERACT with it")


## Called when players right click (RMB) a [PopochiuClickable].
func right_click_clickable() -> void:
	await PopochiuUtils.g.show_system_text("Can't EXAMINE it")


## Called when players click (LMB) a [PopochiuInvenoryItem].
func click_inventory_item() -> void:
	if PopochiuUtils.i.active and PopochiuUtils.i.active != PopochiuUtils.i.clicked:
		await PopochiuUtils.g.show_system_text("Can't USE %s with %s" % [
			PopochiuUtils.i.active.description, PopochiuUtils.i.clicked.description
		])
	else:
		PopochiuUtils.i.clicked.set_active()


## Called when players right click (RMB) a [PopochiuInvenoryItem].
func right_click_inventory_item() -> void:
	await PopochiuUtils.g.show_system_text('Nothing to see in this item')


#endregion
