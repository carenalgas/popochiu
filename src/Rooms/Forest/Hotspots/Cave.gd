tool
extends Hotspot


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	yield(E.run([
		C.walk_to_clicked(),
		C.player_say('Tengo las güevitas pa entrar')
	]), 'completed')
	E.goto_room('Cave')


func on_look() -> void:
	yield(C.player_say('Es la entrada a una cueva'), 'completed')
	G.done()
