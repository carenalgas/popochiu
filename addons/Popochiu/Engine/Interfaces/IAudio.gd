extends Node
# Interface class to handle things related to the AudioManager
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

var twelfth_root_of_two := pow(2, (1.0 / 12))


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func play(
	cue_name := '', wait_to_end := false, position_2d := Vector2.ZERO
) -> Node:
	yield()
	
	return yield(
		E.am.play_sound_cue(cue_name, position_2d, wait_to_end), 'completed'
	)


func play_no_block(
	cue_name := '', wait_to_end := false, position_2d := Vector2.ZERO
) -> Node:
	if wait_to_end:
		return yield(
			E.am.play_sound_cue(cue_name, position_2d, true), 'completed'
		)
	else:
		return E.am.play_sound_cue(cue_name, position_2d)


func play_music(
	cue_name: String, fade_duration := 0.0, music_position := 0.0
) -> Node:
	# TODO: Add a position: Vector2 parameter in case one want to play music coming
	# out from a specific source (e.g. a radio in the room).
	yield()
	
	var stream_player: Node = E.am.play_music_cue(
		cue_name, fade_duration, music_position
	)
	
	yield(get_tree(), 'idle_frame')
	
	return stream_player


func play_music_no_block(
	cue_name: String, fade_duration := 0.0, music_position := 0.0
) -> Node:
	# TODO: Add a position: Vector2 parameter in case one want to play music coming
	# out from a specific source (e.g. a radio in the room).
	
	return E.am.play_music_cue(cue_name, fade_duration, music_position)


func play_fade(
	cue_name := '',
	duration := 1.0,
	wait_to_end := false,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO
) -> Node:
	yield()
	
	return yield(
		E.am.play_fade_cue(
			cue_name, duration, from, to, position_2d, wait_to_end
		),
		'completed'
	)


func play_fade_no_block(
	cue_name := '',
	duration := 1.0,
	wait_to_end := false,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO
) -> Node:
	if wait_to_end:
		return yield(E.am.play_fade_cue(
			cue_name, 
			duration,
			from,
			to,
			position_2d,
			true
		), 'completed')
	else:
		return E.am.play_fade_cue(cue_name, duration, from, to, position_2d)


func stop(cue_name: String, fade_duration := 0.0) -> void:
	yield()
	
	E.am.stop(cue_name, fade_duration)
	
	yield(get_tree(), 'idle_frame')


func stop_no_block(cue_name: String, fade_duration := 0.0) -> void:
	E.am.stop(cue_name, fade_duration)


func get_cue_playback_position(cue_name: String) -> float:
	return E.am.get_cue_playback_position(cue_name)


func change_cue_pitch(cue_name: String, pitch := 0.0) -> void:
	E.am.change_cue_pitch(cue_name, pitch)


func change_cue_volume(cue_name: String, volume := 0.0) -> void:
	E.am.change_cue_volume(cue_name)


func semitone_to_pitch(pitch: float) -> float:
	return pow(twelfth_root_of_two, pitch)
