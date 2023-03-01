@tool
extends "res://addons/popochiu/engine/audio_manager/audio_cue.gd"


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Plays this cue's music track. It can fade for `fade_duration` seconds.
# You can change the track starting position in seconds with `music_position`.
# (!) This is intended to run in queued instructions: E.run([]).
func play(fade_duration := 0.0, music_position := 0.0) -> Callable:
	return func ():
		await play_now(fade_duration, music_position)
		await E.get_tree().process_frame


# Plays immediately this cue's music track. It can fade for `fade_duration` seconds.
# You can change the track starting position in seconds with `music_position`.
func play_now(fade_duration := 0.0, music_position := 0.0) -> void:
	A.play_music_now(resource_name, fade_duration, music_position)
