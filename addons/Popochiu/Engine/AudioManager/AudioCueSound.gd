tool
extends "res://addons/Popochiu/Engine/AudioManager/AudioCue.gd"


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Plays this cue' sound. If `wait_to_end` is `true` the function will pause until
# the audio clip finishes. You can play the clip from a specific `position_2d`
# in the scene if `is_2d` is `true`.
# (!) This is intended to run in queued instructions: E.run([]).
func play(wait_to_end := false, position_2d := Vector2.ZERO) -> void:
	yield()
	
	if wait_to_end:
		yield(
			A.play_no_block(resource_name, wait_to_end, position_2d),
			'completed'
		)
	else:
		A.play_no_block(resource_name, wait_to_end, position_2d)
		yield(E.get_tree(), 'idle_frame')


# Plays immediately this cue' sound. If `wait_to_end` is `true` the function will
# pause until the audio clip finishes. You can play the clip from a specific
# `position_2d` in the scene if `is_2d` is `true`.
func play_now(wait_to_end := false, position_2d := Vector2.ZERO) -> void:
	if wait_to_end:
		yield(
			A.play_no_block(resource_name, wait_to_end, position_2d),
			'completed'
		)
	else:
		A.play_no_block(resource_name, wait_to_end, position_2d)
