tool
extends PopochiuDialog


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func start() -> void:
	yield(E.run([
		C.walk_to_clicked(),
		C.player.say('Hola'),
		'Barney: ¿Qué quiere mano?'
	]), 'completed')

	.start()


func option_selected(opt: DialogOption) -> void:
	match opt.id:
		'1':
			yield(E.run([
				C.player.say('Esto está como bueno'),
				C.get_character('Barney').say('No me lo parece')
			]), 'completed')
		'Necesidad':
			yield(C.player_say('Estoy que me cago', false), 'completed')
			yield(C.character_say('Barney', 'Puede hacer aquí adentro', false), 'completed')
		'Despedida':
			yield(C.player_say('Chau chau', false), 'completed')
			D.emit_signal('dialog_finished')
			return
	_show_options()
