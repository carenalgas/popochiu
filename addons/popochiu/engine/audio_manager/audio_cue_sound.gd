# @popochiu-docs-category game-objects
@tool
class_name AudioCueSound
extends PopochiuAudioCue
## A [PopochiuAudioCue] subtype for playing sound effects.


#region Public #####################################################################################
## Plays this audio cue. If [param wait_to_end] is [code]true[/code], this function will wait until
## the audio clip finishes. If [member PopochiuAudioCue.is_2d] is [code]true[/code], you can specify
## the playback location in the scene using [param position_2d].
func play(wait_to_end := false, position_2d := Vector2.ZERO) -> void:
	if wait_to_end:
		await PopochiuUtils.e.am.play_sound_cue(resource_name, position_2d, true)
	else:
		PopochiuUtils.e.am.play_sound_cue(resource_name, position_2d)


## Plays this audio cue asynchronously. If [param wait_to_end] is [code]true[/code], this function will
## wait until the audio clip finishes. If [member PopochiuAudioCue.is_2d] is [code]true[/code], you can
## specify the playback location in the scene using [param position_2d].
##
## [i]This method is intended for use inside a [method Popochiu.queue] sequence of instructions.[/i]
func queue_play(wait_to_end := false, position_2d := Vector2.ZERO) -> Callable:
	return func ():
		if wait_to_end:
			await play(true, position_2d)
		else:
			play(false, position_2d)
			await PopochiuUtils.e.get_tree().process_frame


#endregion
