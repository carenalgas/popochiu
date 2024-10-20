class_name PopochiuTransitionLayer
extends Control
## Used to play different transition animations when moving between rooms, skipping a cutscene,
## and so on.

signal transition_finished(transition_name: String)

enum {
	FADE_IN_OUT,
	FADE_IN,
	FADE_OUT,
	PASS_DOWN_IN_OUT,
	PASS_DOWN_IN,
	PASS_DOWN_OUT,
}

@onready var n := {
	fade = find_child("Fade")
}

#region Godot ######################################################################################
func _ready() -> void:
	# Connect to childrens' signals
	$AnimationPlayer.animation_finished.connect(_transition_finished)
	$Curtain.modulate = E.settings.fade_color

	# Make sure the transition layer is ready
	# if it has to be visible in the first room
	if E.settings.show_tl_in_first_room and Engine.get_process_frames() == 0:
		$Curtain.show()
		_show()
	else:
		$AnimationPlayer.play("RESET")
		await get_tree().process_frame
		_hide()

#endregion

#region Public #####################################################################################
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
			print("Fading in")
			$AnimationPlayer.play("fade")
		FADE_OUT:
			print("Fading out")
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

#endregion

#region Private ####################################################################################
func _transition_finished(anim_name := "") -> void:
	if anim_name == "RESET":
		return

	transition_finished.emit(anim_name)


func _show() -> void:
	show()
	G.hide_interface()


func _hide() -> void:
	hide()
	G.show_interface()


#endregion
