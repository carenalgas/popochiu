tool
extends Room
# Nodo base para la creación de habitaciones dentro del juego.


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func on_room_entered() -> void:
	# Algo así tendrían que quedar los guiones cuando se están programando
	# interacciones.
	if C.player.last_room == 'Cave':
		C.player.global_position = $Points/CavePoint.global_position
	else:
		C.player.global_position = $Points/EntryPoint.global_position
	
	# TODO: No sé si esté bien que esta lógica la tenga la habitación. Tal vez
	# cada Prop/Hotspot/Character debería validar su propio estado.
	if Globals.has_done(Globals.GameState.GOT_BUCKET) \
		or Globals.has_done(Globals.GameState.LOST_BUCKET):
		$Props/Bucket.queue_free()


func on_room_transition_finished() -> void:
# warning-ignore: unreachable_code
	return
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
