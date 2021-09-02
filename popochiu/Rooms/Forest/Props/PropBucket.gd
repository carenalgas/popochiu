tool
extends Prop

var _interacted := false


func on_interact() -> void:
	yield(C.walk_to_clicked(false), 'completed')
	C.player.face_down(false)
	yield(C.player_say('Uy, un balde re-áspero', false), 'completed')
	yield(E.wait(0.2, false), 'completed')
	Globals.did(Globals.GameState.GOT_BUCKET)
	get_parent().remove_child(self)
	yield(I.add_item('Bucket'), 'completed')
	yield(C.player_say('¡Uy! Y adentro hay un sombrero.', false), 'completed')
	yield(I.add_item_as_active('Hat'), 'completed')
	yield(C.player_say('¡Ora sí! Ya verán de lo que soy capaz.', false), 'completed')
	yield(C.character_say('Barney', '¡Cállese maricón!', false), 'completed')
	G.done()
	queue_free()


func on_look() -> void:
	yield(E.run([
		'Dave: Es un balde ahí de lo más normal y puerco.'
	]), 'completed')
	G.done()
