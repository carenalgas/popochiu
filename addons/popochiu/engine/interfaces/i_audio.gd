# (A) Data and functions to work with audio cues.
#
# Interface class to handle things related to the AudioManager
extends Node

var twelfth_root_of_two := pow(2, (1.0 / 12))


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Plays the AudioCue identified with `cue_name`.
# If `wait_to_end` is `true` the excecution will pause until the audio clip finishes.
# You can play the clip from a specific `position_2d` in the scene if the AudioCue
# `is_2d` property is `true`.
# (!) This is intended to run in queued instructions: E.run([]).
func play(
	cue_name := '', wait_to_end := false, position_2d := Vector2.ZERO
) -> Callable:
	return func (): await play_now(cue_name, wait_to_end, position_2d)


# Plays immediately the AudioCue identified with `cue_name`.
# If `wait_to_end` is `true` the excecution will pause until the audio clip finishes.
# You can play the clip from a specific `position_2d` in the scene if the AudioCue
# `is_2d` property is `true`.
func play_now(
	cue_name := '', wait_to_end := false, position_2d := Vector2.ZERO
) -> Node:
	if wait_to_end:
		return await E.am.play_sound_cue(cue_name, position_2d, true)
	else:
		return await E.am.play_sound_cue(cue_name, position_2d)


# Plays the music track named `cue_name`.
# It can fade for `fade_duration` seconds.
# You can change the track starting position in seconds with `music_position`.
# (!) This is intended to run in queued instructions: E.run([]).
func play_music(
	cue_name: String, fade_duration := 0.0, music_position := 0.0
) -> Callable:
	# TODO: Add a position: Vector2 parameter in case one want to play music coming
	# out from a specific source (e.g. a radio in the room).
	return func (): await play_music_now(cue_name, fade_duration, music_position)


# Plays immediately the music track named `cue_name`.
# It can fade for `fade_duration` seconds.
# You can change the track starting position in seconds with `music_position`.
# (!) This is intended to run in queued instructions: E.run([]).
func play_music_now(
	cue_name: String, fade_duration := 0.0, music_position := 0.0
) -> Node:
	# TODO: Add a position: Vector2 parameter in case one want to play music coming
	# out from a specific source (e.g. a radio in the room).
	
	return E.am.play_music_cue(cue_name, fade_duration, music_position)


# Plays the AudioCue identified with `cue_name` with a fade that will last
# `duration` seconds.
# You can specify the starting volume with `from` and the target volume with `to`.
# (!) This is intended to run in queued instructions: E.run([]).
func play_fade(
	cue_name := '',
	duration := 1.0,
	wait_to_end := false,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO
) -> Callable:
	return func (): await play_fade_now(
		cue_name, duration, wait_to_end, from, to, position_2d
	)


# Plays immediately the AudioCue identified with `cue_name` with a fade that will
# last `duration` seconds.
# You can specify the starting volume with `from` and the target volume with `to`.
func play_fade_now(
	cue_name := '',
	duration := 1.0,
	wait_to_end := false,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO
) -> Node:
	if wait_to_end:
		return await E.am.play_fade_cue(
			cue_name, 
			duration,
			from,
			to,
			position_2d,
			true
		)
	else:
		return await E.am.play_fade_cue(cue_name, duration, from, to, position_2d)


# Stops the AudioCue identified with `cue_name`. Can use a fade that will last
# `fade_duration` seconds.
# (!) This is intended to run in queued instructions: E.run([]).
func stop(cue_name: String, fade_duration := 0.0) -> Callable:
	return func ():
		stop_now(cue_name, fade_duration)
		await get_tree().process_frame


# Stops immediately the AudioCue identified with `cue_name`. Can use a fade that
# will last `fade_duration` seconds.
func stop_now(cue_name: String, fade_duration := 0.0) -> void:
	E.am.stop(cue_name, fade_duration)


# Returns the playback position of the AudioCue identified by `cue_name`.
# If not found, returns -1.0.
func get_cue_playback_position(cue_name: String) -> float:
	return E.am.get_cue_playback_position(cue_name)


# Sets to `pitch` the `pitch_scale` in the AudioStreamPlayer(2D) of the AudioCue
# identified with `cue_name`.
func change_cue_pitch(cue_name: String, pitch := 0.0) -> void:
	E.am.change_cue_pitch(cue_name, pitch)


# Sets to `volume` the `volume_db` in the AudioStreamPlayer(2D) of the AudioCue
# identified with `cue_name`.
func change_cue_volume(cue_name: String, volume := 0.0) -> void:
	E.am.change_cue_volume(cue_name, volume)


# Transforms `pitch` to a value that can be used to modify the `pitch_scale` of
# an AudioStreamPlayer(2D)
func semitone_to_pitch(pitch: float) -> float:
	return pow(twelfth_root_of_two, pitch)
