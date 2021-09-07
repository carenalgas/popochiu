extends Node
# Clase de uso transversal para todos los objetos del proyecto. Aquí se puede
# guardar información que se usará en varias habitaciones, o cosas relacionadas
# con el estado del juego.

enum GameState {
	NONE,
	GOT_BUCKET,
	LOST_BUCKET,
	CAVE_VISITED,
	GOT_MEDAL,
	WON_GAME
}

var game_progress := [GameState.NONE]
