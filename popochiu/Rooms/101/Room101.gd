tool
extends PopochiuRoom

const Data := preload('res://popochiu/Rooms/101/Room101State.gd')

var state: Data = preload('Room101.tres')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
# TODO: Overwrite Godot's methods


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# What happens when Popochiu loads the room. At this point the room is in the
# tree but it is not visible
func on_room_entered() -> void:
#	print_stray_nodes()
	A.mx_two_popochius.play_now(5)


# What happens when the room changing transition finishes. At this point the room
# is visible.
func on_room_transition_finished() -> void:
	if state.visited_times == 1:
		yield(E.run([
			'.',
#			C.Goddiu.face_left(),
#			C.Popsy.face_right(),
#			'...',
#			C.Goddiu.face_right(),
#			C.Popsy.face_left(),
#			'Player: Here we go again',
#			'Popsy: What!?',
#			C.Popsy.walk_to_prop('ToyCar'),
#			'Popsy: THIS IS MY TOY CAR!!!',
#			I.Key.add_as_active(),
		]), 'completed')


# What happens before Popochiu unloads the room.
# At this point, the screen is black, processing is disabled and all characters
# have been removed from the $Characters node.
func on_room_exited() -> void:
	A.mx_two_popochius.stop_now()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# You could put public functions here


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
# You could put private functions here
