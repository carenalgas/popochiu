tool
extends Prop

var _interacted := false


func on_interact() -> void:
	yield(C.walk_to_clicked(false), 'completed')
	C.player.face_down(false)
	yield(C.player_say('Uy, un balde re-áspero', false), 'completed')
	yield(E.wait(0.2), 'completed')
	get_parent().remove_child(self)
	yield(I.add_item_as_active('Bucket'), 'completed')
	yield(C.player_say('¡Ora sí! Ya verán de lo que soy capaz.', false), 'completed')
	yield(C.character_say('Barney', '¡Cállese maricón!', false), 'completed')
	G.done()
	queue_free()


func on_look() -> void:
	.on_look()
