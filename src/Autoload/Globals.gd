extends Node

enum GameState {
	NONE,
	GOT_BUCKET,
	LOST_BUCKET,
	CAVE_VISITED,
	GOT_MEDAL,
	WON_GAME
}

var game_progress := [GameState.NONE]


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func has_done(id := -1) -> bool:
	return game_progress.has(id)


func did(id := -1) -> void:
	if not GameState.values().has(id): return
	if game_progress.has(id): return

	game_progress.append(id)
