@tool
extends PopochiuProp
# You can use E.run([]) to trigger a sequence of events.
# Use await E.run([]) if you want to pause the excecution of
# the function until the sequence of events finishes.

signal cocoed


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# When the node is clicked
func on_interact() -> void:
	E.run([
		C.walk_to_clicked(),
		C.face_clicked(),
		'Player: My old toycar',
		'...',
		'Player: [wave]The memories...[/wave]',
		I.add_item('ToyCar')
	])


# When the node is right clicked
func on_look() -> void:
	super()


# When the node is clicked and there is an inventory item selected
func on_item_used(item: PopochiuInventoryItem) -> void:
	super(item)


# When an inventory item linked to this Prop (link_to_item) is removed from
# the inventory (i.e. when it is used in something that makes use of the object).
func on_linked_item_removed() -> void:
	pass


# When an inventory item linked to this Prop (link_to_item) is discarded from
# the inventory (i.e. when the player throws the object out of the inventory).
func on_linked_item_discarded() -> void:
	pass
