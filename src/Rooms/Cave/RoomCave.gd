tool
extends PopochiuRoom

var zapato := 'no'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
# TODO: Sobrescribir los métodos de Godot que hagan falta


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_room_entered() -> void:
	C.player.global_position = Vector2(98, 78)


func on_room_transition_finished() -> void:
	if not Globals.has_done(Globals.GameState.CAVE_VISITED):
		zapato = 'sí'
		Globals.did(Globals.GameState.CAVE_VISITED)
		E.run([
			C.player_walk_to($Points/EntryPoint.global_position),
			C.player.face_left(),
			C.player_say('Pues no está tan paila aquí dentro')
		])


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
# TODO: Poner aquí los métodos privados
