tool
extends Hotspot


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	var opt: DialogOption = yield(
		E.show_inline_dialog(['Hola', 'Venga', '¡Vemos!']),
		'completed'
	)
	yield(C.player_say(opt.text, false), 'completed')

	if opt.id == 'Opt1':
		yield(E.run([
			'Barney: Hola... maricón',
			'...',
			'Coco: No existo, entonces no puedo decir una mierda',
			'Dave: No tiene que tratarme tan feo... malparido'
		]), 'completed')
	elif opt.id == 'Opt2':
		yield(E.run([
			C.get_character('Barney').say('Venga usted que se puede mover'),
			'Barney: Yo estaré aquí clavado mientras me hacen controlable',
			G.display('En un futuro se podrá hacer controlable cualquier personaje')
		]), 'completed')
	else:
		yield(E.run(['Barney: ¡Vemos carechimba!']), 'completed')


func on_look() -> void:
	pass


func on_item_used(item: InventoryItem) -> void:
	pass
