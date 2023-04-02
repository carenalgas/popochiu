@tool
extends Resource
class_name PopochiuAudioCue

@export var audio: AudioStream
@export var loop := false : set = set_loop
@export var is_2d := false
@export var pitch := 0.0 : get = get_pitch
@export var volume := 0.0
@export var rnd_pitch := Vector2.ZERO
@export var rnd_volume := Vector2.ZERO
@export var max_distance := 2000
@export var attenuation := 1.0 # (float, EASE)
@export var bus := 'Master'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Plays immediately this audio cue with a fade that will last `duration` seconds.
# You can specify the starting volume with `from` and the target volume with `to`.
func fade(
	duration := 1.0,
	wait_to_end := false,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO
) -> void:
	if wait_to_end:
		await E.am.play_fade_cue(
			resource_name, 
			duration,
			from,
			to,
			position_2d,
			true
		)
	else:
		E.am.play_fade_cue(resource_name, duration, from, to, position_2d)


# Queue the call to play this audie cue with a fade that will last `duration`
# seconds. You can specify the starting volume with `from` and the target volume
# with `to`.
# (!) This is intended to run in queued instructions: E.queue([]).
func queue_fade(
	duration := 1.0,
	wait_to_end := false,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO
) -> Callable:
	return func ():
		if wait_to_end:
			await fade(duration, wait_to_end, from, to, position_2d)
		else:
			fade(duration, wait_to_end, from, to, position_2d)
			await E.get_tree().process_frame


# Stops the audio cue. Can use a fade that will last `fade_duration`
# seconds.
func stop(fade_duration := 0.0) -> void:
	E.am.stop(resource_name, fade_duration)


# Queue the call to stop the audio cue.
# Can use a fade that will last `fade_duration` seconds.
# (!) This is intended to run in queued instructions: E.queue([]).
func queue_stop(fade_duration := 0.0) -> Callable:
	return func ():
		stop(fade_duration)
		await E.get_tree().process_frame


# Changes the pitch_scale of the AudioStreamPlayer(2D) that is playing the audio
# file of this cue
func change_stream_pitch(pitch := 0.0) -> void:
	E.am.change_cue_pitch(resource_name, pitch)


# Changes the volume_db of the AudioStreamPlayer(2D) that is playing the audio
# file of this cue
func change_stream_volume(volume := 0.0) -> void:
	E.am.change_cue_volume(resource_name, volume)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_loop(value: bool) -> void:
	loop = value
	
	if not audio: return
	
	match audio.get_class():
		'AudioStreamOggVorbis', 'AudioStreamMP3':
			audio.loop = value
		'AudioStreamWAV':
			(audio as AudioStreamWAV).loop_mode =\
			AudioStreamWAV.LOOP_FORWARD if value\
			else AudioStreamWAV.LOOP_DISABLED
	
	notify_property_list_changed()


# Returns the `pitch_scale` to apply to the audio stream player that will play
# the audio of this audio cue.
func get_pitch() -> float:
	var p := A.semitone_to_pitch(pitch)
	
	if rnd_pitch != Vector2.ZERO:
		p = _get_rnd_pitch()
	
	return p


# Returns the playback position of the AudioCue identified by `cue_name`.
# If not found, returns -1.0.
func get_cue_playback_position() -> float:
	return E.am.get_cue_playback_position(resource_name)


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


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _get_rnd_pitch() -> float:
	randomize()
	return A.semitone_to_pitch(pitch + randf_range(rnd_pitch.x, rnd_pitch.y))


func _get_rnd_volume() -> float:
	randomize()
	return volume + randf_range(rnd_volume.x, rnd_volume.y)
