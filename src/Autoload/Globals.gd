extends Node

enum GameState {
	NONE,
	GOT_BUCKET,
	LOST_BUCKET,
	GOT_MEDAL,
	WON_GAME
}

var game_progress := [GameState.NONE]
