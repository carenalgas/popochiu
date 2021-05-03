tool
extends Prop


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	E.run([
		'Dave: ¡Uy! ¿Qué es eso?',
		G.display('El personaje jugable puede moverse entre habitaciones.')
	])


func on_look() -> void:
	pass


func on_item_used(item: Item) -> void:
	pass
