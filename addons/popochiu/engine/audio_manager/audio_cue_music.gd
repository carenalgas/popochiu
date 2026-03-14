# @popochiu-docs-category game-objects
@tool
class_name AudioCueMusic
extends PopochiuAudioCue
## A [PopochiuAudioCue] subtype for playing music tracks.


#region Public #####################################################################################
## Plays this audio cue. Optionally fades over [param fade_duration] seconds and starts the track
## at [param music_position] seconds.
func play(fade_duration := 0.0, music_position := 0.0) -> void:
	PopochiuUtils.e.am.play_music_cue(resource_name, fade_duration, music_position)


## Plays this audio cue asynchronously. Optionally fades over [param fade_duration] seconds and starts
## the track at [param music_position] seconds.
##
## [i]This method is intended for use inside a [method Popochiu.queue] sequence of instructions.[/i]
func queue_play(fade_duration := 0.0, music_position := 0.0) -> Callable:
	return func ():
		await play(fade_duration, music_position)
		await PopochiuUtils.e.get_tree().process_frame


#endregion
