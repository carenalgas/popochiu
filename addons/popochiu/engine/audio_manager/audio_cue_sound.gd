@tool
class_name AudioCueSound
extends PopochiuAudioCue
## A specific type of [PopochiuAudioCue] designed for playing sounds.


#region Public #####################################################################################
## Plays this audio cue. If [param wait_to_end] is set to [code]true[/code], the function will pause
## until the audio clip finishes. You can play the file from a specific [param position_2d] in the
## scene if [member PopochiuAudioCue.is_2d] is [code]true[/code].
func play(wait_to_end := false, position_2d := Vector2.ZERO) -> void:
	if wait_to_end:
		await PopochiuUtils.e.am.play_sound_cue(resource_name, position_2d, true)
	else:
		PopochiuUtils.e.am.play_sound_cue(resource_name, position_2d)


## Plays this audio cue. If [param wait_to_end] is set to [code]true[/code], the function will pause
## until the audio clip finishes. You can play the file from a specific [param position_2d] in the
## scene if [member PopochiuAudioCue.is_2d] is [code]true[/code].[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_play(wait_to_end := false, position_2d := Vector2.ZERO) -> Callable:
	return func ():
		if wait_to_end:
			await play(true, position_2d)
		else:
			play(false, position_2d)
			await PopochiuUtils.e.get_tree().process_frame


#endregion
