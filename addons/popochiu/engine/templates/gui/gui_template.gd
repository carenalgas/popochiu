# @popochiu-docs-ignore-class
extends PopochiuGraphicInterface


#region Virtual ####################################################################################
# Called when the GUI is blocked and should not handle input events.
func _on_blocked(props := { blocking = true }) -> void:
	super(props)


# Called when the GUI is unblocked and can handle input events again.
func _on_unblocked() -> void:
	super()


# Called to hide the GUI.
func _on_hidden() -> void:
	super()


# Called to show the GUI.
func _on_shown() -> void:
	super()


# Called when `G.show_system_text()` is triggered.
# `super()` shows `msg` in the SystemText component. Override or extend if needed.
func _on_system_text_shown(msg: String) -> void:
	super(msg)


# Called when the player closes the SystemText component (for example by
# clicking the screen anywhere).
func _on_system_text_hidden() -> void:
	super()


# Called when the mouse enters (hovers) a `clickable`.
func _on_mouse_entered_clickable(clickable: PopochiuClickable) -> void:
	super(clickable)


# Called when the mouse exits a `clickable`.
func _on_mouse_exited_clickable(clickable: PopochiuClickable) -> void:
	super(clickable)


# Called when the mouse enters (hovers) an `inventory_item`.
func _on_mouse_entered_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	super(inventory_item)


# Called when the mouse exits an `inventory_item`.
func _on_mouse_exited_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	super(inventory_item)


# Called when a dialog line is spoken by a `PopochiuCharacter` (i.e. when
# `PopochiuCharacter.say()` is called).
func _on_dialog_line_started() -> void:
	super()


# Called when a dialog line finishes (for example after the player clicks the
# screen to dismiss it).
func _on_dialog_line_finished() -> void:
	super()


# Called when a `dialog` starts (after calling `PopochiuDialog.start()`).
func _on_dialog_started(dialog: PopochiuDialog) -> void:
	super(dialog)


# Called when a `dialog` finishes (after calling `PopochiuDialog.stop()`).
func _on_dialog_finished(dialog: PopochiuDialog) -> void:
	super(dialog)


# Called when an inventory `item` is selected (for example, by clicking it).
func _on_inventory_item_selected(item: PopochiuInventoryItem) -> void:
	super(item)


# Called by `PopochiuCursor` to get the name of the cursor texture to show.
func _get_cursor_name() -> String:
	return super()


#endregion
