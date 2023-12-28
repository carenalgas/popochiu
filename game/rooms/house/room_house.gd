@tool
extends PopochiuRoom

const Data := preload('room_house_state.gd')

var state: Data = load('res://game/rooms/house/room_house.tres')


#region Virtual ####################################################################################
# What happens when Popochiu loads the room. At this point the room is in the
# tree but it is not visible
func _on_room_entered() -> void:
	pass


# What happens when the room changing transition finishes. At this point the room
# is visible.
func _on_room_transition_finished() -> void:
	await C.Goddiu.say("Hi amigo mío")
	await C.Goddiu.say("mmmmm")
	await E.camera_shake()


# What happens before Popochiu unloads the room.
# At this point, the screen is black, processing is disabled and all characters
# have been removed from the $Characters node.
func _on_room_exited() -> void:
	pass


#endregion
