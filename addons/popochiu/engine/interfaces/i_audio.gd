# (A) Data and functions to work with audio cues.
#
# Interface class to handle things related to the AudioManager
extends Node

var twelfth_root_of_two := pow(2, (1.0 / 12))


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Transforms `pitch` to a value that can be used to modify the `pitch_scale` of
# an AudioStreamPlayer(2D)
func semitone_to_pitch(pitch: float) -> float:
	return pow(twelfth_root_of_two, pitch)
