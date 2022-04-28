tool
extends PopochiuRoom

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_room_entered() -> void:
	pass


func on_room_transition_finished() -> void:
	C.player_say('This works so fine...', false)
