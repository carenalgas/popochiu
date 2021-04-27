tool
extends Hotspot

func on_interact() -> void:
	C.player.face_right(false)
	yield(C.player_say('Me dan miedo las cuevas'), 'completed')
	G.done()


func on_look() -> void:
	yield(C.player_say('Es la entrada a una cueva'), 'completed')
	G.done()
