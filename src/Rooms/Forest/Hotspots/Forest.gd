tool
extends Hotspot

func on_interact() -> void:
	yield(G.display('Este es un Hotspot', true), 'completed')
	G.done()


func on_look() -> void:
	.on_look()


func on_item_used(item: Item) -> void:
	if item.script_name == 'Bucket':
		yield(C.player_say('No quiero tirar mi balde al bosque'), 'completed')
		G.done()
