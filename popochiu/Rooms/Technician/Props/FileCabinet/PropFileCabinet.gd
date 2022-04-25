tool
extends PopochiuProp


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_interact() -> void:
	yield(E.run([
		C.walk_to_clicked()
	]), 'completed')


func on_look() -> void:
	yield(E.run([]), 'completed')


func on_item_used(_item: InventoryItem) -> void:
	pass
