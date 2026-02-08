# @popochiu-docs-ignore-class
@tool
extends PopochiuProp
# You can use `E.queue([])` in any of the methods in this script to trigger a sequence of events.
# Use `await E.queue([])` to pause execution until the sequence completes.


#region Virtual ####################################################################################
# Called when the prop is clicked
func _on_click() -> void:
	# Replace the call to E.command_fallback() with your own logic.
	PopochiuUtils.e.command_fallback()
	# Example: make the player walk to this prop, face it, then say a line:
#	await C.player.walk_to_clicked()
#	await C.player.face_clicked()
#	await C.player.say("Not picking that up!")


# Called when the prop is double-clicked
func _on_double_click() -> void:
	# Replace the call to E.command_fallback() with your code.
	PopochiuUtils.e.command_fallback()
	# For example, you could make the player instantly do something instead of walking there first


# Called when the prop is right-clicked
func _on_right_click() -> void:
	# Replace the call to E.command_fallback() with your own logic.
	PopochiuUtils.e.command_fallback()
	# Example: make the player face this prop and say a line:
#	await C.player.face_clicked()
#	await C.player.say("A deck of cards")


# When the prop is middle clicked
func _on_middle_click() -> void:
	# Replace the call to E.command_fallback() to implement your code.
	PopochiuUtils.e.command_fallback()


# Called when the prop is clicked while an inventory item is selected
func _on_item_used(_item: PopochiuInventoryItem) -> void:
	# Replace the call to E.command_fallback() with your own logic.
	PopochiuUtils.e.command_fallback()
	# Example: if the Key is used on this prop, make the player speak.
#	if _item == I.Key:
#		await C.player.say("This stuff has no lock!")


# Called when an inventory item linked to this Prop (`link_to_item`) is removed
# from the inventory.
func _on_linked_item_removed() -> void:
	pass


# Called when an inventory item linked to this Prop (`link_to_item`) is discarded
# from the inventory.
func _on_linked_item_discarded() -> void:
	pass


# Called when the prop starts moving
func _on_movement_started() -> void:
	pass


# Called when the prop stops moving
func _on_movement_ended() -> void:
	pass


#endregion

#region Public #####################################################################################
# Add functions here that are triggered by GUI commands.
#
# If you name the functions following the `on_<command_id>` pattern, they will be automatically
# called when the corresponding command is triggered in the GUI.
#
# For example, if your GUI provides a `look_at` command you could add:
#
#func on_look_at() -> void:
#	pass
#
# This function will be called whenever the `look_at` command is triggered in the GUI while this
# prop is the target.
# This keeps the code way more tidy and organized with GUIs with many different commands,
# as opposed to having a single `match` statement in the general-use methods.


#endregion
