class_name PopochiuTransitionLayer
extends Node2D
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
	
	if E.scale != Vector2.ONE:
		$Transitions.scale = E.scale
	
	$InputBlockerLayer.hide()


#endregion

#region Public #####################################################################################
func play_transition(type := FADE_IN, duration := 1.0) -> void:
	$InputBlockerLayer.show()
	G.hide_interface()
	
	# ---- Play RESET in order to fix #168 ---------------------------------------------------------
	$AnimationPlayer.play("RESET")
	await get_tree().process_frame
	# --------------------------------------------------------- Play RESET in order to fix #168 ----
	
	for c in $Transitions.get_children():
		(c as Sprite2D).modulate = E.settings.fade_color
	
	$AnimationPlayer.speed_scale = 1.0 / duration
	
	match type:
		FADE_IN_OUT:
			$AnimationPlayer.play("fade_in")
			await $AnimationPlayer.animation_finished
			
			$AnimationPlayer.play("fade_out")
		FADE_IN:
			$AnimationPlayer.play("fade_in")
		FADE_OUT:
			$AnimationPlayer.play("fade_out")
		PASS_DOWN_IN_OUT:
			$AnimationPlayer.play("pass_down_in")
			await $AnimationPlayer.animation_finished
			
			$AnimationPlayer.play("pass_down_out")
		PASS_DOWN_IN:
			$AnimationPlayer.play("pass_down_in")
		PASS_DOWN_OUT:
			$AnimationPlayer.play("pass_down_out")


#endregion

#region Private ####################################################################################
func _transition_finished(anim_name := "") -> void:
	if anim_name == "RESET":
		return
	
	$InputBlockerLayer.hide()
	G.show_interface()
	
	transition_finished.emit(anim_name)


#endregion
