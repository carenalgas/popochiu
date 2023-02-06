tool
extends Resource

export var audio: AudioStream
export var loop := false setget _set_loop
export var is_2d := false
export var pitch := 0.0
export var volume := 0.0
export var rnd_pitch := Vector2.ZERO
export var rnd_volume := Vector2.ZERO
export var max_distance := 2000
export(float, EASE) var attenuation = 1.0
export(String, 'Master', 'Music') var bus = 'Master'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Returns the `pitch_scale` to apply to the audio stream player that will play
# the audio of this audio cue.
func get_pitch() -> float:
	if rnd_pitch != Vector2.ZERO:
		return _get_rnd_pitch()
	return A.semitone_to_pitch(pitch)


# Plays this audie cue with a fade that will last `duration` seconds.
# You can specify the starting volume with `from` and the target volume with `to`.
# (!) This is intended to run in queued instructions: E.run([]).
func fade(
	duration := 1.0,
	wait_to_end := false,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO
) -> void:
	yield()
	
	if wait_to_end:
		yield(
			A.play_fade_no_block(
				resource_name, duration, wait_to_end, from, to, position_2d
			),
			'completed'
		)
	else:
		A.play_fade_no_block(
			resource_name, duration, wait_to_end, from, to, position_2d
		)
		yield(E.get_tree(), 'idle_frame')


# Plays immediately this audio cue with a fade that will last `duration` seconds.
# You can specify the starting volume with `from` and the target volume with `to`.
func fade_now(
	duration := 1.0,
	wait_to_end := false,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO
) -> void:
	if wait_to_end:
		yield(
			A.play_fade_no_block(
				resource_name, duration, wait_to_end, from, to, position_2d
			),
			'completed'
		)
	else:
		A.play_fade_no_block(
			resource_name, duration, wait_to_end, from, to, position_2d
		)


# Stops the audio cue. Can use a fade that will last `fade_duration` seconds.
# (!) This is intended to run in queued instructions: E.run([]).
func stop(fade_duration := 0.0) -> void:
	yield()
	
	yield(A.stop_no_block(resource_name, fade_duration), 'completed')


# Stops the audio cue immediately. Can use a fade that will last `fade_duration`
# seconds.
func stop_now(fade_duration := 0.0) -> void:
	A.stop_no_block(resource_name, fade_duration)


# Changes the pitch_scale of the AudioStreamPlayer(2D) that is playing the audio
# file of this cue
func change_stream_pitch(pitch := 0.0) -> void:
	A.change_cue_pitch(resource_name, pitch)


# Changes the volume_db of the AudioStreamPlayer(2D) that is playing the audio
# file of this cue
func change_stream_volume(volume := 0.0) -> void:
	A.change_cue_volume(resource_name, volume)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
# Returns the properties of this audio cue as a Dictionary.
# Used by TabAudio when changing the script of the audio cue to one of the types:
# AudioCueSound or AudioCueMusic (in projects prior to v1.9.0)
func get_values() -> Dictionary:
	return {
		resource_name = resource_name,
		audio = audio,
		loop = loop,
		is_2d = is_2d,
		pitch = pitch,
		volume = volume,
		rnd_pitch = rnd_pitch,
		rnd_volume = rnd_volume,
		max_distance = max_distance,
		attenuation = attenuation,
		bus = bus
	}


# Maps the values in `values` to the properties of this audio cue.
# Used by TabAudio when changing the script of the audio cue to one of the types:
# AudioCueSound or AudioCueMusic (in projects prior to v1.9.0)
func set_values(values: Dictionary) -> void:
	resource_name = values.resource_name
	audio = values.audio
	loop = values.loop
	is_2d = values.is_2d
	pitch = values.pitch
	volume = values.volume
	rnd_pitch = values.rnd_pitch
	rnd_volume = values.rnd_volume
	max_distance = values.max_distance
	attenuation = values.attenuation
	bus = values.bus



# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _get_rnd_pitch() -> float:
	randomize()
	return A.semitone_to_pitch(
		pitch + rand_range(rnd_pitch.x, rnd_pitch.y)
	)


func _get_rnd_volume() -> float:
	randomize()
	return volume + rand_range(rnd_volume.x, rnd_volume.y)


func _set_loop(value: bool) -> void:
	loop = value
	match audio.get_class():
		'AudioStreamOGGVorbis', 'AudioStreamMP3':
			audio.loop = value
		'AudioStreamSample':
			(audio as AudioStreamSample).loop_mode =\
			AudioStreamSample.LOOP_FORWARD if value\
			else AudioStreamSample.LOOP_DISABLED
	property_list_changed_notify()
