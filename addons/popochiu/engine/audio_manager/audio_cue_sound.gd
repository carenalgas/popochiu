@tool
extends PopochiuAudioCue
class_name AudioCueSound


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Plays immediately this cue's sound.
# If `wait_to_end` is `true` the function will pause until the audio clip finishes.
# You can play the clip from a specific `position_2d` in the scene if `is_2d` is
# `true`.
func play(wait_to_end := false, position_2d := Vector2.ZERO) -> void:
	if wait_to_end:
		await E.am.play_sound_cue(resource_name, position_2d, true)
	else:
		E.am.play_sound_cue(resource_name, position_2d)


# Queue the call to play this cue's sound.
# If `wait_to_end` is `true` the function will pause until the audio clip finishes
# You can play the clip from a specific `position_2d` in the scene if `is_2d` is
# `true`.
# (!) This is intended to be used in queued instructions: E.queue([]).
func queue_play(wait_to_end := false, position_2d := Vector2.ZERO) -> Callable:
	return func ():
		if wait_to_end:
			await play(true, position_2d)
		else:
			play(false, position_2d)
			await E.get_tree().process_frame
