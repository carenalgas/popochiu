extends Room
# Nodo base para la creación de habitaciones dentro del juego.

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func on_room_entered() -> void:
	# Algo así tendrían que quedar los guiones cuando se están programando
	# interacciones.
	C.player.global_position = $Points/EntryPoint.global_position


func on_room_transition_finished() -> void:
	E.run([
		G.display('Haz clic para interactuar y clic derecho para examinar'),
		G.display('DLG_A'),
		C.player_say('Bueno. Hay que empezar con algo'),
		C.character_say('Barney', 'Cállese maricón!'),
		E.wait(),
		C.player.face_up(),
		E.wait(),
		C.player.face_left(),
		E.wait(),
		C.player.face_right(),
		E.wait(),
		C.player.face_down(),
		C.player_say('Lo importante es empezar')
	])


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
# TODO: Poner aquí los métodos privados
