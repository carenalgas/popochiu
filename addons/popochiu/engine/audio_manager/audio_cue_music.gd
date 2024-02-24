@tool
extends PopochiuAudioCue
class_name AudioCueMusic
## Specific type of [PopochiuAudioCue] used to play music.


#region Public #####################################################################################
## Plays this audio cue immediately. It can fade for [param fade_duration] seconds. You can change
## the track starting position in seconds with [param music_position].
func play(fade_duration := 0.0, music_position := 0.0) -> void:
	E.am.play_music_cue(resource_name, fade_duration, music_position)


## Plays this audio cue immediately. It can fade for [param fade_duration] seconds. You can change
## the track starting position in seconds with [param music_position].
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_play(fade_duration := 0.0, music_position := 0.0) -> Callable:
	return func ():
		await play(fade_duration, music_position)
		await E.get_tree().process_frame


#endregion
