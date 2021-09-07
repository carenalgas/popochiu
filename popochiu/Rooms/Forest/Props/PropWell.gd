tool
extends Prop


func on_interact() -> void:
	yield(C.walk_to_clicked(false), 'completed')
	C.player.face_up(false)
	yield(E.wait(1.0, false), 'completed')
	C.player.face_down(false)
	yield(C.player_say('Esa mierda huele a berrinche como un hijueputa', false), 'completed')
	G.done()


func on_look() -> void:
	yield(C.player_say('Qué pozo más rico...', false), 'completed')
	G.done()


func on_item_used(item: InventoryItem) -> void:
	if item.script_name == 'Bucket':
		Globals.game_progress.append(Globals.GameState.LOST_BUCKET)
		E.run([
			C.walk_to_clicked(),
			C.player.face_up(),
			C.player_say('Adiós baldecito...'),
			I.remove_item(item.script_name),
			'...',
			C.player_say('Te echaré de menos'),
			E.wait(3),
			C.player.face_left(),
			C.player_say('...te echaré de menos...'),
		])
