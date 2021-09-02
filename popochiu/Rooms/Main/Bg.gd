tool
extends Prop


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	E.goto_room('forest')


func on_look() -> void:
	pass


func on_item_used(item: InventoryItem) -> void:
	pass
