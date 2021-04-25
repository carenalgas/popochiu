tool
extends Prop


func on_interact() -> void:
	yield(C.walk_to_clicked(), 'completed')
	# TODO: Hacer que la línea del berrinche la diga otro personaje
	yield(C.player_say('Esa mierda huele a berrinche como un hijueputa'), 'completed')
	G.done()


func on_look() -> void:
	yield(C.player_say('Qué pozo más rico...'), 'completed')
	G.done()


func on_item_used(item: Item) -> void:
	if item.script_name == 'Bucket':
		yield(C.walk_to_clicked(), 'completed')
		C.player.face_up()
		yield(C.player_say('Adiós baldecito...'), 'completed')
		yield(I.remove_item(item.script_name), 'completed')
		yield(get_tree().create_timer(0.8), 'timeout')
		yield(C.player_say('Te echaré de menos'), 'completed')
		G.done()
