tool
extends PopochiuProp
# You can use E.run([]) to trigger a sequence of events.
# Use yield(E.run([]), 'completed') if you want to pause the excecution of
# the function until the sequence of events finishes.

var opened := false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# When the node is clicked
func on_interact() -> void:
	opened = !opened
	
	self.current_frame = 1 if opened else 0
	
	R.Outside.state.is_rainning = true


# When the node is right clicked
func on_look() -> void:
#	Replace the call to .on_look() to implement your code. This only makes
#	the default behavior to happen.
#	For example you can make the character walk to the Prop and then say
#	something:
#	E.run([
#		C.face_clicked(),
#		'Player: A deck of cards'
#	])
	.on_look()


# When the node is clicked and there is an inventory item selected
func on_item_used(item: PopochiuInventoryItem) -> void:
	# Replace the call to .on_item_used(item) to implement your code. This only
	# makes the default behavior to happen.
	.on_item_used(item)


# When an inventory item linked to this Prop (link_to_item) is removed from
# the inventory (i.e. when it is used in something that makes use of the object).
func on_linked_item_removed() -> void:
	pass


# When an inventory item linked to this Prop (link_to_item) is discarded from
# the inventory (i.e. when the player throws the object out of the inventory).
func on_linked_item_discarded() -> void:
	pass


func on_room_set() -> void:
	self.current_frame = 1 if opened else 0
