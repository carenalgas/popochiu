tool
extends PopochiuProp


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_interact() -> void:
	yield(E.run([
		C.walk_to_clicked(),
		I.add_item_as_active('Key')
	]), 'completed')


func on_look() -> void:
	.on_look()


func on_item_used(item: PopochiuInventoryItem) -> void:
	.on_item_used(item)
