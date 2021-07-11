tool
extends Region


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_character_entered(chr: Character) -> void:
	.on_character_entered(chr)
	yield(E.run([
		C.player.stop_walking(),
		C.player.face_down(),
		'Player: Aquí se siente como raro...',
		'..',
		'Barney: Sí... como triste...',
		'Player: Mejor me alejo de laesquinadelatristeza',
	]), 'completed')


func on_character_exited(chr: Character) -> void:
	.on_character_exited(chr)
