tool
class_name AudioCue
extends Resource

export var audio: AudioStream
export var loop := false setget _set_loop
export var is_2d := false
export var pitch := 0.0
export var volume := 1.0
export var rnd_pitch := Vector2.ZERO
export var rnd_volume := Vector2.ZERO
export var max_distance := 2000
export(float, EASE) var attenuation = 1.0
export(String, 'Master', 'Music') var bus = 0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func get_pitch() -> float:
	if rnd_pitch != Vector2.ZERO:
		return _get_rnd_pitch()
	return A.semitone_to_pitch(pitch)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _get_rnd_pitch() -> float:
	randomize()
	return A.semitone_to_pitch(pitch + rand_range(rnd_pitch.x, rnd_pitch.y))


func _get_rnd_volume() -> float:
	randomize()
	return volume + rand_range(rnd_volume.x, rnd_volume.y)


func _set_loop(value: bool) -> void:
	loop = value
	audio.loop = value
	property_list_changed_notify()
