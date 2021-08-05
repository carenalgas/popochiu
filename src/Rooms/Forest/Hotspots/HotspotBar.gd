tool
extends Hotspot


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	E.goto_room('Garden')


func on_look() -> void:
	pass


func on_item_used(item: InventoryItem) -> void:
	pass
