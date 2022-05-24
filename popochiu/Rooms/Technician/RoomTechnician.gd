tool
extends PopochiuRoom


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_room_entered() -> void:
	A.play_music('mx_classic', 1.5, 0.0, false)


func on_room_transition_finished() -> void:
	pass
