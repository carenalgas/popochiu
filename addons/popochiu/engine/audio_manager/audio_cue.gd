@tool
class_name PopochiuAudioCue
extends Resource
## Used to play audio files with extra properties.
##
## You can set the pitch (with random values), volume, and audio bus. Whether it loops or not, or
## whether it is 2D positioned.

## The audio file to play with this audio cue.
@export var audio: AudioStream
## Whether the audio file will loop when played.
@export var loop := false : set = set_loop
## Whether this audio cue uses a 2D position.
@export var is_2d := false
## Whether the audio can be played simultaniously with other instances of itself. Specially useful
## for audio cues in loop ([member loop] is [code]true[/code]).
@export var can_play_simultaneous := true
## The pitch value to use when playing the audio file.
@export var pitch := 1.0
## The volume to use when playing the audio file.
@export var volume := 0.0
## The range of values to use to randomly change the pitch of the audio file when played.
@export var rnd_pitch := Vector2.ZERO
## The range of values to use to randomly change the volume of the audio file when played.
@export var rnd_volume := Vector2.ZERO
## Maximum distance from which the audio file is still hearable. This only works if [member is_2d]
## is [code]true[/code].
@export var max_distance := 2000
## The bus in which this audio cue will be played.
@export var bus := "Master"


#region Public #####################################################################################
## Plays immediately this audio cue with a fade that will last [param duration] seconds. If
## [param wait_to_end] is [code]true[/code] the function will wait for the audio to finish. You can
## specify the starting volume with [param from] and the target volume with [param to], also the
## [param position_2d] of the [AudioStreamPlayer] that will play the audio file.
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


## Plays immediately this audio cue with a fade that will last [param duration] seconds. If
## [param wait_to_end] is [code]true[/code] the function will wait for the audio to finish. You can
## specify the starting volume with [param from] and the target volume with [param to], also the
## [param position_2d] of the [AudioStreamPlayer] that will play the audio file.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
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


## Stops the audio cue. Can use a fade effect that will last [param fade_duration] seconds.
func stop(fade_duration := 0.0) -> void:
	E.am.stop(resource_name, fade_duration)


## Stops the audio cue. Can use a fade effect that will last [param fade_duration] seconds.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_stop(fade_duration := 0.0) -> Callable:
	return func ():
		stop(fade_duration)
		await E.get_tree().process_frame


## Changes the [member AudioStreamPlayer.pitch_scale] of the [AudioStreamPlayer] that plays the
## audio file of this audio cue. If the audio was played with a 2D position, then
## [member AudioStreamPlayer2D.pitch_scale] will be the one affected.
func change_stream_pitch(pitch := 0.0) -> void:
	E.am.change_cue_pitch(resource_name, pitch)


## Changes the [member AudioStreamPlayer.volume_db] of the [AudioStreamPlayer] that plays the
## audio file of this audio cue. If the audio was played with a 2D position, then
## [member AudioStreamPlayer2D.volume_db] will be the one affected.
func change_stream_volume(volume := 0.0) -> void:
	E.am.change_cue_volume(resource_name, volume)


## Returns the [member AudioStreamPlayer.pitch_scale] to apply to the [AudioStreamPlayer] that will
## play the audio file of this audio cue. If the audio was played with a 2D position, then
## [member AudioStreamPlayer2D.volume_db] will be the one affected.
func get_pitch_scale() -> float:
	var p := A.semitone_to_pitch(pitch)
	
	if rnd_pitch != Vector2.ZERO:
		p = _get_rnd_pitch()
	
	return p


## Returns the playback position of this audio cue.
func get_cue_playback_position() -> float:
	return E.am.get_cue_playback_position(resource_name)


## Maps [param values] to the properties of this audio cue. Used by TabAudio when changing the
## script of the audio cue to one of the types: [AudioCueSound] or [AudioCueMusic].
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


## Returns the properties of this audio cue as a [Dictionary]. Used by TabAudio when changing the
## script of the audio cue to one of the types: [AudioCueSound] or [AudioCueMusic].
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


#endregion

#region SetGet #####################################################################################
func set_loop(value: bool) -> void:
	loop = value
	
	if not audio: return
	
	match audio.get_class():
		'AudioStreamOggVorbis', 'AudioStreamMP3':
			audio.loop = value
		'AudioStreamWAV':
			if (audio as AudioStreamWAV).get_loop_end() == 0 && value:
				PopochiuUtils.print_warning(
					"[b]%s[/b]" % resource_name +\
					" does not have the correct metadata to loop, please check" +\
					" AudioStreamWAV documentation"
				)
			else:
				(audio as AudioStreamWAV).loop_mode =\
				AudioStreamWAV.LOOP_FORWARD if value\
				else AudioStreamWAV.LOOP_DISABLED
	
	notify_property_list_changed()


#endregion

#region Private ####################################################################################
func _get_rnd_pitch() -> float:
	randomize()
	return A.semitone_to_pitch(pitch + randf_range(rnd_pitch.x, rnd_pitch.y))


func _get_rnd_volume() -> float:
	randomize()
	return volume + randf_range(rnd_volume.x, rnd_volume.y)


#endregion
