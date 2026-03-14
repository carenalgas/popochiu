# @popochiu-docs-ignore-class
@tool
extends PopochiuRoom

const Data := preload('room_state_template.gd')

var state: Data = null


#region Virtual ####################################################################################
# Called when Popochiu loads the room. At this point the room is in the scene tree but not yet
# visible.
# Add any code you want to setup the stage before the room is shown to the player (e.g. setting
# character position and facing direction, active walkable area, props visibility, etc.).
func _on_room_entered() -> void:
	pass


# Called after the room transition completes; the room is now visible.
# Implement this to start cutscenes, play sounds, etc.
func _on_room_transition_finished() -> void:
	# You can use await E.queue([]) to run a sequence of actions here.
	pass


# Called before Popochiu unloads the room.
# At this point the screen is black, processing is disabled, and characters
# have been removed from the $Characters node.
# Implement cleanup code, handle custom data or states before leaving the room, etc. if needed.
func _on_room_exited() -> void:
	pass


#endregion
