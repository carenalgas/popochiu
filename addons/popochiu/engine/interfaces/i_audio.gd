class_name PopochiuIAudio
extends Node
## Provides access to the [PopochiuAudioCue]s in the game. Access with [b]A[/b] (e.g.
## [code]A.sfx_woosh.play()[/code]).
##
## Interface class that can be used to access all the audio cues in the game in order to play
## sound effects and music.[br][br]
## Use examples:[br]
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

## Used to convert the value of the pitch set on [member PopochiuAudioCue.pitch] to the
## corresponding value needed for the [code]pitch_scale[/code] property of the audio stream players.
var twelfth_root_of_two := pow(2, (1.0 / 12))


#region Godot ######################################################################################
func _init() -> void:
	Engine.register_singleton(&"A", self)


#endregion

#region Public #####################################################################################
## Transforms [param pitch] to a value that can be used to modify the
## [member AudioStreamPlayer.pitch_scale] or [member AudioStreamPlayer2D.pitch_scale].
func semitone_to_pitch(pitch: float) -> float:
	return pow(twelfth_root_of_two, pitch)


## Returns [code]true[/code] if the [PopochiuAudioCue] identified by [param cue_name] is playing.
func is_playing_cue(cue_name: String) -> bool:
	return PopochiuUtils.e.am.is_playing_cue(cue_name)


#endregion
