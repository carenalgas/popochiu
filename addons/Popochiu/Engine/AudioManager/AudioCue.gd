@tool
extends Resource

@export var audio: AudioStream
@export var loop := false : set = _set_loop
@export var is_2d := false
@export var pitch := 0.0
@export var volume := 1.0
@export var rnd_pitch := Vector2.ZERO
@export var rnd_volume := Vector2.ZERO
@export var max_distance := 2000
@export var attenuation := 1.0 # (float, EASE)
@export var bus := 'Master' # (String, 'Master', 'Music')

var twelfth_root_of_two := pow(2, (1.0 / 12))


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func get_pitch() -> float:
	if rnd_pitch != Vector2.ZERO:
		return _get_rnd_pitch()
	return semitone_to_pitch(pitch)


func semitone_to_pitch(pitch: float) -> float:
	return pow(twelfth_root_of_two, pitch)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _get_rnd_pitch() -> float:
	randomize()
	return semitone_to_pitch(pitch + randf_range(rnd_pitch.x, rnd_pitch.y))


func _get_rnd_volume() -> float:
	randomize()
	return volume + randf_range(rnd_volume.x, rnd_volume.y)


func _set_loop(value: bool) -> void:
	loop = value
	
	match audio.get_class():
		'AudioStreamOggVorbis', 'AudioStreamMP3':
			audio.loop = value
		'AudioStreamWAV':
			(audio as AudioStreamWAV).loop_mode =\
			AudioStreamWAV.LOOP_FORWARD if value\
			else AudioStreamWAV.LOOP_DISABLED
	
	notify_property_list_changed()
