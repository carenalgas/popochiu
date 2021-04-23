tool
extends 'res://src/Nodes/Hotspot/Hotspot.gd'

func on_interact() -> void:
	C.player.face_right()
	yield(get_tree().create_timer(1.0), 'timeout')
	yield(C.player_say('Me dan miedo las cuevas'), 'completed')
	G.done()


func on_look() -> void:
	._on_look()
