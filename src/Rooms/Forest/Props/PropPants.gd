tool
extends Prop


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	E.run(['Player: Uy, unos pantalones!'])


func on_look() -> void:
	pass


func on_item_used(item: InventoryItem) -> void:
	pass
