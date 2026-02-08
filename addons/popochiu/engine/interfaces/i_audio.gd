# @popochiu-docs-category game-scripts-interfaces
class_name PopochiuIAudio
extends Node
## Provides access to the game's [PopochiuAudioCue]s through the singleton [b]A[/b] (for example:
## [code]A.sfx_woosh.play()[/code]).
##
## Use this interface to play sound effects and music.
##
## Capabilities include:
##
## - Playing sound effects and music.[br]
## - Convert semitone values to pitch multipliers for audio playback.
##
## [b]Use examples:[/b]
## [codeblock]
## func _on_click() -> void:
##     await A.sfx_tv_on.play()
##     await E.queue([
##         A.mx_toon_town.queue_play(),
##         A.vo_scream.queue_play(true), # Wait for the audio to finish
##         A.sfx_boing.queue_play(),
##     ])
##     A.mx_house.play()
## [/codeblock]

## Conversion factor from [member PopochiuAudioCue.pitch] semitone values to the
## multiplier required by [code]pitch_scale[/code] on [AudioStreamPlayer] and
## [AudioStreamPlayer2D].
var twelfth_root_of_two := pow(2, (1.0 / 12))


#region Godot ######################################################################################
func _init() -> void:
	Engine.register_singleton(&"A", self)


#endregion

#region Public #####################################################################################
## Converts a semitone offset ([param pitch]) to the corresponding multiplier needed by
## [member AudioStreamPlayer.pitch_scale] or [member AudioStreamPlayer2D.pitch_scale].
func semitone_to_pitch(pitch: float) -> float:
	return pow(twelfth_root_of_two, pitch)


## Returns [code]true[/code] if the [PopochiuAudioCue] identified by [param cue_name]
## is currently playing.
func is_playing_cue(cue_name: String) -> bool:
	return PopochiuUtils.e.am.is_playing_cue(cue_name)


#endregion
