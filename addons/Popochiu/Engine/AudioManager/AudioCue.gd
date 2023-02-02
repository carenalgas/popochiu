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
func get_pitch() -> float:
	if rnd_pitch != Vector2.ZERO:
		return _get_rnd_pitch()
	return AudioManager.semitone_to_pitch(pitch)


func play_fade(
	duration := 1.0,
	wait_to_end := false,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO
) -> void:
	yield()
	
	if wait_to_end:
		yield(
			AudioManager.play_fade_no_block(
				resource_name, duration, wait_to_end, from, to, position_2d
			),
			'completed'
		)
	else:
		AudioManager.play_fade_no_block(
			resource_name, duration, wait_to_end, from, to, position_2d
		)
		yield(E.get_tree(), 'idle_frame')


func play_fade_no_run(
	duration := 1.0,
	wait_to_end := false,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO
) -> void:
	if wait_to_end:
		yield(
			AudioManager.play_fade_no_block(
				resource_name, duration, wait_to_end, from, to, position_2d
			),
			'completed'
		)
	else:
		AudioManager.play_fade_no_block(
			resource_name, duration, wait_to_end, from, to, position_2d
		)


func stop(fade_duration := 0.0) -> void:
	yield()
	
	yield(AudioManager.stop(resource_name, fade_duration), 'completed')


func stop_no_run(fade_duration := 0.0) -> void:
	AudioManager.stop(resource_name, fade_duration)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _get_rnd_pitch() -> float:
	randomize()
	return AudioManager.semitone_to_pitch(
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
