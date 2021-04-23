extends 'res://src/Nodes/Character/Character.gd'

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	G.emit_signal('show_inline_dialog', ['Hola', 'Carita', 'de bola'])


func on_look() -> void:
	yield(G.display('Ese es otro personaje'), 'completed')
	G.done()


func on_item_used(item: Item) -> void:
	if item.script_name == 'Bucket':
		yield(C.character_say(script_name, '¿Yo pa\' qué quiero esa mierda?'), 'completed')
		yield(C.player_say('No sé... ¿para metérselo por el culo?'), 'completed')
		yield(C.character_say(script_name, '...'), 'completed')
		G.done()
