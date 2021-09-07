tool
extends Hotspot


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	yield(E.run([
		C.walk_to_clicked(),
		C.player.face_down(),
		C.player_say('Nito respirar')
	]), 'completed')
	E.goto_room('Forest')


func on_look() -> void:
	pass


func on_item_used(item: InventoryItem) -> void:
	pass
