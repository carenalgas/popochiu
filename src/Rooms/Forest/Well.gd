tool
extends 'res://src/Nodes/Prop/Prop.gd'


func on_interact() -> void:
	yield(C.walk_to_clicked(), 'completed')
	# TODO: Hacer que la línea del berrinche la diga otro personaje
	yield(C.player_say('Esa mierda huele a berrinche como un hijueputa'), 'completed')
	G.done()


func on_look() -> void:
	._on_look('Qué pozo más rico...')


func on_item_used(item: Item) -> void:
	if item.script_name == 'Bucket':
		yield(C.walk_to_clicked(), 'completed')
		C.player.face_up()
		yield(C.player_say('Adiós baldecito...'), 'completed')
		# TODO: quitar el Bucket del inventario
		yield(get_tree().create_timer(2.0), 'timeout')
		yield(C.player_say('Te echaré de menos'), 'completed')
		G.done()
