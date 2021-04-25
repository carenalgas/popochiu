extends Character

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	var opt: String = yield(
		G.show_inline_dialog(['Hola', 'Venga', '¡Vemos!']),
		'completed'
	)
#	yield(Utils.run([C.player_say(opt)]), 'completed')
	
	if opt == 'Hola':
		yield(Utils.run([
			'Barney: Hola... maricón',
			'Coco: No existo',
			'Dave: No tiene que tratarme tan feo... malparido'
		]), 'completed')
	elif opt == 'Venga':
		yield(Utils.run([
			say('Venga usted que se puede mover'),
			'Barney: Yo estaré aquí clavado mientras me hacen controlable',
#			say('Yo estaré aquí clavado mientras me hacen controlable'),
			G.display('En un futuro se podrá hacer controlable cualquier personaje')
		]), 'completed')
#		yield(say('Venga usted que se puede mover'), 'completed')
#		yield(say('Yo estaré aquí clavado mientras me hacen controlable'), 'completed')
#		yield(G.display('En un futuro se podrá hacer controlable cualquier personaje'), 'completed')
#		G.done()
	else:
		yield(say('¡Vemos carechimba!'), 'completed')
		G.done()


func on_look() -> void:
	yield(G.display('Ese es otro personaje'), 'completed')
	G.done()


func on_item_used(item: Item) -> void:
	if item.script_name == 'Bucket':
		yield(C.character_say(script_name, '¿Yo pa\' qué quiero esa mierda?'), 'completed')
		yield(C.player_say('No sé... ¿para metérselo por el culo?'), 'completed')
		yield(C.character_say(script_name, '...'), 'completed')
		G.done()
