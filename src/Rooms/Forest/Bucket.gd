tool
extends 'res://src/Nodes/Prop/Prop.gd'

var _interacted := false


func on_interact() -> void:
	yield(C.walk_to_clicked(), 'completed')
	C.player.face_down()
	yield(C.player_say('Uy, un balde re-áspero'), 'completed')
	yield(get_tree().create_timer(0.2), 'timeout')
	get_parent().remove_child(self)
	yield(I.add_item('Bucket'), 'completed')
	yield(C.player_say('¡Ora sí! Ya verán de lo que soy capaz.'), 'completed')
	yield(C.character_say('Barney', '¡Cállese maricón!'), 'completed')
	G.done()
	queue_free()


func on_look() -> void:
	._on_look()
