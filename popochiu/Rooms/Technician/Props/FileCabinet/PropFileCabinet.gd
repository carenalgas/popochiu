tool
extends PopochiuProp

#var TransitionLayer :=\
#preload('res://addons/Popochiu/Engine/Objects/TransitionLayer/TransitionLayer.gd')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_interact() -> void:
	yield(E.run([
		C.walk_to_clicked(),
		A.play_fade('sfx_locker_open'),
		'Player: I should not being doing this.'
	]), 'completed')
	
#	var s: AudioStreamPlayer = yield(
#		A.play('sfx_locker_open', false, false),
#		'completed'
#	)
#	s.pitch_scale = A.semitone_to_pitch(-5.0)
	
	var o: Resource = yield(D.show_inline_dialog([
		'Shake',
		'Zoom',
	]), 'completed')
	
	match o.id:
		'Opt1':
			E.run([
				E.camera_shake(),
				'Player: What was that?',
				E.play_transition(TransitionLayer.PASS_DOWN_IN, 0.5),
				'...',
				E.play_transition(TransitionLayer.PASS_DOWN_OUT, 0.5),
				'Player: [shake]Oh myyyyyyyyyyyyyyyy[/shake]'
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
