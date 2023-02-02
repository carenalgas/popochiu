tool
extends "res://addons/Popochiu/Engine/AudioManager/AudioCue.gd"


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
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


func play_no_run(wait_to_end := false, position_2d := Vector2.ZERO) -> void:
	if wait_to_end:
		yield(
			A.play_no_block(resource_name, wait_to_end, position_2d),
			'completed'
		)
	else:
		A.play_no_block(resource_name, wait_to_end, position_2d)
