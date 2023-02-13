tool
extends PopochiuHotspot
# You can use E.run([]) to trigger a sequence of events.
# Use yield(E.run([]), 'completed') if you want to pause the excecution of
# the function until the sequence of events finishes.


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# When the node is clicked
func on_interact() -> void:
	E.run([
		C.walk_to_clicked(),
		C.face_clicked(),
		"Player: I don't want to touch it.",
		"Player: Last time I did so it fell on my feet.",
		C.Popsy.say("Exactly..."),
	])



# When the node is right clicked
func on_look() -> void:
	E.run([
		C.walk_to_clicked(),
		C.face_clicked(),
		C.Goddiu.run_animation('jump'),
		C.Popsy.pause_animation(),
		"Player: Ah!! This pictures always scares me...",
		C.Goddiu.face_left(),
		"Player: It reminds me how much I paid for it",
		C.Popsy.resume_animation(),
	])


# When the node is clicked and there is an inventory item selected
func on_item_used(item: PopochiuInventoryItem) -> void:
	# Replace the call to .on_item_used(item) to implement your code. This only
	# makes the default behavior to happen.
	# For example you can make the PC react on using some items in this Hotspot
#	if item.script_name == 'Key':
#		E.run(['Player: No can do'])
	.on_item_used(item)
