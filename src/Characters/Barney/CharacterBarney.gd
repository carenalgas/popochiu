tool
extends Character

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	yield(D.show_dialog('ChatWithBarney'), 'completed')


func on_look() -> void:
	yield(G.display('Ese es otro personaje'), 'completed')
	G.done()


func on_item_used(item: InventoryItem) -> void:
	if item.script_name == 'Bucket':
		E.run([
			C.character_say(script_name, '¿Yo pa\' qué quiero esa mierda?'),
			C.player_say('No sé... ¿para metérselo por el culo?'),
			C.character_say(script_name, '...'),
			G.done()
		])
