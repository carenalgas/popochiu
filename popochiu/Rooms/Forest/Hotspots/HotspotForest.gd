tool
extends Hotspot


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	E.run([
		C.walk_to_clicked(),
		C.player.face_up(),
		E.wait(),
		C.player_say('No puedo entrarlo')
	])


func on_look() -> void:
	.on_look()


func on_item_used(item: InventoryItem) -> void:
	if item.script_name == 'Bucket':
		yield(C.player_say('No quiero tirar mi balde al bosque'), 'completed')
		G.done()
