tool
extends "res://src/Nodes/Hotspot/Hotspot.gd"

func on_interact() -> void:
	G.emit_signal('show_inline_dialog', ['A esto le falta mucho', '...vamos a terminarlo'])


func on_look() -> void:
	._on_look()


func on_item_used(item: Item) -> void:
	if item.script_name == 'Bucket':
		yield(C.player_say('No quiero tirar mi balde al bosque'), 'completed')
		G.done()
