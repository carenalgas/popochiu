extends 'res://src/Inventory/Item.gd'

# Cuando se le hace clic en el inventario
func on_interact() -> void:
	prints('aaaaaaaaaaaaaa')


# Lo que pasará cuando se haga clic derecho en el icono del inventario
func on_look() -> void:
	G.emit_signal('show_info_requested', 'Este es mi balde')


# Lo que pasará cuando se use otro Item del inventario sobre este
func on_use_item() -> void:
	pass
