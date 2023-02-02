tool
extends "res://addons/Popochiu/Engine/AudioManager/AudioCue.gd"


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func play(fade_duration := 0.0, music_position := 0.0) -> void:
	yield()
	
	AudioManager.play_music(resource_name, fade_duration, music_position)
	yield(E.get_tree(), 'idle_frame')


func play_no_run(fade_duration := 0.0, music_position := 0.0) -> void:
	AudioManager.play_music_no_block(resource_name, fade_duration, music_position)
