tool
extends Hotspot

func on_interact() -> void:
	.on_interact()


func on_look() -> void:
	.on_look()


func on_item_used(item: Item) -> void:
	if item.script_name == 'Bucket':
		yield(C.player_say('No quiero tirar mi balde al bosque'), 'completed')
		G.done()
