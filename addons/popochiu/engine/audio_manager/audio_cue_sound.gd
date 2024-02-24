@tool
extends PopochiuAudioCue
class_name AudioCueSound


#region Public #####################################################################################
## Plays this audio cue. If [param wait_to_end] is [code]true[/code], the function will pause until
## the audio clip finishes. You can play the file from a specific [param position_2d] in the scene
## if [member is_2d] is [code]true[/code].
func play(wait_to_end := false, position_2d := Vector2.ZERO) -> void:
	if wait_to_end:
		await E.am.play_sound_cue(resource_name, position_2d, true)
	else:
		E.am.play_sound_cue(resource_name, position_2d)


## Plays this audio cue. If [param wait_to_end] is [code]true[/code], the function will pause until
## the audio clip finishes. You can play the file from a specific [param position_2d] in the scene
## if [member is_2d] is [code]true[/code].
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_play(wait_to_end := false, position_2d := Vector2.ZERO) -> Callable:
	return func ():
		if wait_to_end:
			await play(true, position_2d)
		else:
			play(false, position_2d)
			await E.get_tree().process_frame


#endregion
