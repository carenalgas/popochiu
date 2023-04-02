@tool
extends PopochiuAudioCue
class_name AudioCueMusic


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Plays immediately this cue's music track.
# It can fade for `fade_duration` seconds.
# You can change the track starting position in seconds with `music_position`.
func play(fade_duration := 0.0, music_position := 0.0) -> void:
	E.am.play_music_cue(resource_name, fade_duration, music_position)


# Queue the call to play this cue's music track.
# It can fade for `fade_duration` seconds.
# You can change the track starting position in seconds with `music_position`.
# (!) This is intended to run in queued instructions: E.queue([]).
func queue_play(fade_duration := 0.0, music_position := 0.0) -> Callable:
	return func ():
		await play(fade_duration, music_position)
		await E.get_tree().process_frame
