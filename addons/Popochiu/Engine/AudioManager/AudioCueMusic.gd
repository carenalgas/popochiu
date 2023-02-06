tool
extends "res://addons/Popochiu/Engine/AudioManager/AudioCue.gd"


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Plays this cue's music track. It can fade for `fade_duration` seconds.
# You can change the track starting position in seconds with `music_position`.
# (!) This is intended to run in queued instructions: E.run([]).
func play(fade_duration := 0.0, music_position := 0.0) -> void:
	yield()
	
	A.play_music(resource_name, fade_duration, music_position)
	yield(E.get_tree(), 'idle_frame')


# Plays immediately this cue's music track. It can fade for `fade_duration` seconds.
# You can change the track starting position in seconds with `music_position`.
func play_now(fade_duration := 0.0, music_position := 0.0) -> void:
	A.play_music_no_block(resource_name, fade_duration, music_position)
