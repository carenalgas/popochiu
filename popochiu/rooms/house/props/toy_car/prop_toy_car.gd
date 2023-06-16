@tool
extends PopochiuProp
# You can use E.queue([]) to trigger a sequence of events.
# Use await E.queue([]) if you want to pause the excecution of
# the function until the sequence of events finishes.


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# When the node is clicked
func _on_click() -> void:
	# Replace the call to super() to implement your code. This only makes
	# the default behavior to happen.
	# For example you can make the character walk to the Prop and then say
	# something:
#	E.queue([
#		C.walk_to_clicked(),
#		C.face_clicked(),
#		'Player: Not picking that up'
#	])
	super.on_click()


# When the node is right clicked
func _on_right_click() -> void:
	# Replace the call to super() to implement your code. This only makes
	# the default behavior to happen.
	# For example you can make the character walk to the Prop and then say
	# something:
#	E.queue([
#		C.face_clicked(),
#		'Player: A deck of cards'
#	])
	super.on_right_click()


# When the node is clicked and there is an inventory item selected
func on_item_used(item: PopochiuInventoryItem) -> void:
	# Replace the call to super(item) to implement your code. This only
	# makes the default behavior to happen.
	# For example you can make the PC react checked using some items in this Prop
#	if item.script_name == 'Key':
#		E.queue(["Player: I can't do that"])
	super(item)


# When an inventory item linked to this Prop (link_to_item) is removed from
# the inventory (i.e. when it is used in something that makes use of the object).
func on_linked_item_removed() -> void:
	pass


# When an inventory item linked to this Prop (link_to_item) is discarded from
# the inventory (i.e. when the player throws the object out of the inventory).
func on_linked_item_discarded() -> void:
	pass
