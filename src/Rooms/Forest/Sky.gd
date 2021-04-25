tool
extends Hotspot


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	var opt: Dictionary = yield(
		E.show_inline_dialog(['Hola', 'Venga', '¡Vemos!']),
		'completed'
	)
	yield(C.player_say(opt.text), 'completed')

	if opt.id == '1':
		yield(E.run([
			'Barney: Hola... maricón',
			'Coco: No existo',
			'Dave: No tiene que tratarme tan feo... malparido'
		]), 'completed')
	elif opt.id == '2':
		yield(E.run([
			C._get_character('Barney').say('Venga usted que se puede mover'),
			'Barney: Yo estaré aquí clavado mientras me hacen controlable',
			G.display('En un futuro se podrá hacer controlable cualquier personaje')
		]), 'completed')
	else:
		yield(E.run(['Barney: ¡Vemos carechimba!']), 'completed')


func on_look() -> void:
	pass


func on_item_used(item: Item) -> void:
	pass
