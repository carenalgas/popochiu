class_name PopochiuTransitionLayer
extends Control
## Used to play different transition animations when moving between rooms, skipping a cutscene,
## and so on.

signal transition_finished(transition_name: String)

## Available transition types.
enum {
	## Fades in and out.
	FADE_IN_OUT,
	## Fades in.
	FADE_IN,
	## Fades out.
	FADE_OUT,
	## Passes down and up.
	PASS_DOWN_IN_OUT,
	## Passes down.
	PASS_DOWN_IN,
	## Passes up.
	PASS_DOWN_OUT,
}


#region Godot ######################################################################################
func _ready() -> void:
	# Connect to childrens' signals
	$AnimationPlayer.animation_finished.connect(_transition_finished)
	$Curtain.modulate = PopochiuUtils.e.settings.fade_color

	# Make sure the transition layer is ready
	# if it has to be visible in the first room
	if PopochiuUtils.e.settings.show_tl_in_first_room and Engine.get_process_frames() == 0:
		$Curtain.show()
		_show()
	else:
		$AnimationPlayer.play("RESET")
		await get_tree().process_frame
		
		_hide()


#endregion

#region Public #####################################################################################
## Plays a transition with the animation identified by [param type] and that lasts [param duration]
## (in seconds). The transition can be one of the following:
## [enum PopochiuTransitionLayer.FADE_IN_OUT], [enum PopochiuTransitionLayer.FADE_IN],
## [enum PopochiuTransitionLayer.FADE_OUT], [enum PopochiuTransitionLayer.PASS_DOWN_IN_OUT],
## [enum PopochiuTransitionLayer.PASS_DOWN_IN], [enum PopochiuTransitionLayer.PASS_DOWN_OUT].
func play_transition(type := FADE_IN, duration := 1.0) -> void:
	_show()
	
	# ---- Play RESET in order to fix #168 ---------------------------------------------------------
	$AnimationPlayer.play("RESET")
	await get_tree().process_frame
	# --------------------------------------------------------- Play RESET in order to fix #168 ----
	
	$AnimationPlayer.speed_scale = 1.0 / duration
	
	match type:
		FADE_IN_OUT:
			$AnimationPlayer.play("fade")
			await $AnimationPlayer.animation_finished
			$AnimationPlayer.play_backwards("fade")
			await $AnimationPlayer.animation_finished
			_hide()
		FADE_IN:
			$AnimationPlayer.play("fade")
		FADE_OUT:
			$AnimationPlayer.play_backwards("fade")
			await $AnimationPlayer.animation_finished
			_hide()
		PASS_DOWN_IN_OUT:
			$AnimationPlayer.play("pass")
			await $AnimationPlayer.animation_finished
			$AnimationPlayer.play_backwards("pass")
			await $AnimationPlayer.animation_finished
			_hide()
		PASS_DOWN_IN:
			$AnimationPlayer.play("pass")
		PASS_DOWN_OUT:
			$AnimationPlayer.play_backwards("pass")
			await $AnimationPlayer.animation_finished
			_hide()


## Shows the curtain without playing any transition.
func show_curtain() -> void:
	$Curtain.modulate = PopochiuUtils.e.settings.fade_color
	$Curtain.show()
	_show()


## Hides the transition layer.
func hide_curtain() -> void:
	_hide()


#endregion

#region Private ####################################################################################
func _transition_finished(anim_name := "") -> void:
	if anim_name == "RESET":
		return

	transition_finished.emit(anim_name)


func _show() -> void:
	show()
	PopochiuUtils.g.hide_interface()


func _hide() -> void:
	hide()
	PopochiuUtils.g.show_interface()


#endregion
