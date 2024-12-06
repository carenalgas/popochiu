@tool
class_name PopochiuAudioCue
extends Resource
## Used to play audio files with extra properties.
##
## You can set the pitch (with random values), volume, and audio bus, as well as specify whether
## it loops, and whether it is 2D positioned.


## The audio file to play.
@export var audio: AudioStream
## Whether the audio file will loop when played.
@export var loop := false : set = set_loop
## Whether this audio cue uses a 2D position.
@export var is_2d := false
## Whether the audio can be played simultaneously with other instances of itself. Especially useful
## for audio cues set in a loop (where [member loop] is [code]true[/code]).
@export var can_play_simultaneous := true
## The pitch value (in semitones) to use when playing the audio file.
@export var pitch := 0.0
## The volume to use when playing the audio file.
@export var volume := 0.0
## The range of values to use for randomly changing the pitch of the audio file when played.
@export var rnd_pitch := Vector2.ZERO
## The range of values to use to randomly changing the volume of the audio file when played.
@export var rnd_volume := Vector2.ZERO
## Maximum distance from which the audio file is still hearable. This only works if [member is_2d]
## is [code]true[/code].
@export var max_distance := 2000
## The audio bus in which the audio file will be played.
@export var bus := "Master"


#region Public #####################################################################################
## Plays this audio cue with a fade that lasts [param duration] seconds. If [param wait_to_end] is
## set to [code]true[/code], the function will wait for the audio to finish. You can specify the
## starting volume with [param from] and the target volume with [param to], as well as the
## [param position_2d] of the [AudioStreamPlayer] or [AudioStreamPlayer2D] that will play the audio
## file.
func fade(
	duration := 1.0, wait_to_end := false, from := -80.0, to := INF, position_2d := Vector2.ZERO
) -> void:
	if wait_to_end:
		await PopochiuUtils.e.am.play_fade_cue(resource_name, duration, from, to, position_2d, true)
	else:
		PopochiuUtils.e.am.play_fade_cue(resource_name, duration, from, to, position_2d)


## Plays this audio cue with a fade that lasts [param duration] seconds. If [param wait_to_end] is
## set to [code]true[/code], the function will wait for the audio to finish. You can specify the
## starting volume with [param from] and the target volume with [param to], as well as the
## [param position_2d] of the [AudioStreamPlayer] or [AudioStreamPlayer2D] that will play the audio
## file.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_fade(
	duration := 1.0, wait_to_end := false, from := -80.0, to := INF, position_2d := Vector2.ZERO
) -> Callable:
	return func ():
		if wait_to_end:
			await fade(duration, wait_to_end, from, to, position_2d)
		else:
			fade(duration, wait_to_end, from, to, position_2d)
			await PopochiuUtils.e.get_tree().process_frame


## Stops the audio cue, with an optional fade effect lasting [param fade_duration] seconds.
func stop(fade_duration := 0.0) -> void:
	PopochiuUtils.e.am.stop(resource_name, fade_duration)


## Stops the audio cue, with an optional fade effect lasting [param fade_duration] seconds.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_stop(fade_duration := 0.0) -> Callable:
	return func ():
		stop(fade_duration)
		await PopochiuUtils.e.get_tree().process_frame


## Changes the [member AudioStreamPlayer.pitch_scale] of the [AudioStreamPlayer] playing the audio
## file associated with this audio cue to [param pitch]. If the audio was played with a 2D position,
## then [member AudioStreamPlayer2D.pitch_scale] will be affected.
func change_stream_pitch(pitch := 0.0) -> void:
	PopochiuUtils.e.am.change_cue_pitch(resource_name, pitch)


## Changes the [member AudioStreamPlayer.volume_db] of the [AudioStreamPlayer] playing the audio
## file associated with this audio cue to [param volume]. If the audio was played with a 2D
## position, then [member AudioStreamPlayer2D.volume_db] will be affected.
func change_stream_volume(volume := 0.0) -> void:
	PopochiuUtils.e.am.change_cue_volume(resource_name, volume)


## Returns the value of [member AudioStreamPlayer.pitch_scale] to be applied to the
## [AudioStreamPlayer] playing the audio file associated with this audio cue. If the audio was
## played with a 2D position, then [member AudioStreamPlayer2D.volume_db] will be affected.
func get_pitch_scale() -> float:
	var p := PopochiuUtils.a.semitone_to_pitch(pitch)
	
	if rnd_pitch != Vector2.ZERO:
		p = _get_rnd_pitch()
	
	return p


## Returns the playback position of this audio cue.
func get_cue_playback_position() -> float:
	return PopochiuUtils.e.am.get_cue_playback_position(resource_name)


## Maps [param values] to the properties of this audio cue. This is used by TabAudio when changing
## the script of the audio cue to one of the types: [AudioCueSound] or [AudioCueMusic].
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
	bus = values.bus


## Returns the properties of this audio cue as a [Dictionary]. This is used by TabAudio when
## changing the script of the audio cue to one of the types: [AudioCueSound] or [AudioCueMusic].
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
		bus = bus
	}


## Returns [code]true[/code] if playing.
func is_playing() -> bool:
	return PopochiuUtils.a.is_playing_cue(resource_name)


#endregion

#region SetGet #####################################################################################
func set_loop(value: bool) -> void:
	loop = value
	
	if not audio: return
	
	match audio.get_class():
		'AudioStreamOggVorbis', 'AudioStreamMP3':
			audio.loop = value
		'AudioStreamWAV':
			(audio as AudioStreamWAV).loop_mode = (
				AudioStreamWAV.LOOP_FORWARD if value else AudioStreamWAV.LOOP_DISABLED
			)
	
	notify_property_list_changed()


#endregion

#region Private ####################################################################################
func _get_rnd_pitch() -> float:
	randomize()
	return PopochiuUtils.a.semitone_to_pitch(pitch + randf_range(rnd_pitch.x, rnd_pitch.y))


func _get_rnd_volume() -> float:
	randomize()
	return volume + randf_range(rnd_volume.x, rnd_volume.y)


#endregion
