tool
extends PopochiuRoom

const Data := preload('res://popochiu/Rooms/Outside/RoomOutsideState.gd')

var state: Data = preload('RoomOutside.tres')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
# TODO: Overwrite Godot's methods


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# What happens when Popochiu loads the room. At this point the room is in the
# tree but it is not visible
func on_room_entered() -> void:
	A.mx_beach_time.play_now(5)
	pass


# What happens when the room changing transition finishes. At this point the room
# is visible.
func on_room_transition_finished() -> void:
#	if E.rooms_states['101'].props.Drawer.opened:
#		E.run([
#			"Player: I shouldn't have left that drawer open"
#		])
#
#	prints('101 Window have been clicked %d times'\
#	% E.rooms_states['101'].hotspots.Window.times_clicked)
	pass


# What happens before Popochiu unloads the room.
# At this point, the screen is black, processing is disabled and all characters
# have been removed from the $Characters node.
func on_room_exited() -> void:
	A.mx_beach_time.stop_now(2)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# You could put public functions here


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
# You could put private functions here
