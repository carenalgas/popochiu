tool
extends PopochiuProp

var TransitionLayer :=\
preload('res://addons/Popochiu/Engine/Objects/TransitionLayer/TransitionLayer.gd')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_interact() -> void:
	yield(E.run([
		C.walk_to_clicked(),
	]), 'completed')
	
	var o: Resource = yield(D.show_inline_dialog([
		'Yes',
		'Nope',
	]), 'completed')
	
	match o.id:
		'Opt1':
			E.run([
				E.camera_shake(),
				'Player: What was that?',
				E.play_transition(TransitionLayer.PASS_DOWN_IN, 0.5),
				'...',
				E.play_transition(TransitionLayer.PASS_DOWN_OUT, 0.5),
				'Player: Oh my...'
			])
		'Opt2':
			E.run([
				E.camera_offset(Vector2(0.0, -16.0)),
				E.camera_zoom(Vector2.ONE * 0.5, 0.5),
				'Player: Oh, oh.',
				E.camera_offset(),
				E.camera_zoom(Vector2.ONE, 0.5),
			])


func on_look() -> void:
	.on_look()


func on_item_used(item: PopochiuInventoryItem) -> void:
	.on_item_used(item)
