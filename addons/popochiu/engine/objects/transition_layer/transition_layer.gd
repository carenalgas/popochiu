extends CanvasLayer
class_name TransitionLayer
# warning-ignore-all:return_value_discarded

signal transition_finished(transition_name)

enum {
	FADE_IN_OUT,
	FADE_IN,
	FADE_OUT,
	PASS_DOWN_IN_OUT,
	PASS_DOWN_IN,
	PASS_DOWN_OUT,
}

@onready var n := {
	fade = find_child('Fade')
}

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	$AnimationPlayer.animation_finished.connect(_transition_finished)
	
	if E.settings.scale_gui:
		$Transitions.scale = E.scale


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func play_transition(type := FADE_IN, duration := 1.0) -> void:
	for c in $Transitions.get_children():
		(c as Sprite2D).modulate = E.settings.fade_color
	
	$AnimationPlayer.speed_scale = 1.0 / duration
	
	match type:
		FADE_IN_OUT:
			$AnimationPlayer.play('fade_in')
			await $AnimationPlayer.animation_finished
			$AnimationPlayer.play('fade_out')
		FADE_IN:
			$AnimationPlayer.play('fade_in')
		FADE_OUT:
			$AnimationPlayer.play('fade_out')
		PASS_DOWN_IN_OUT:
			$AnimationPlayer.play('pass_down_in')
			await $AnimationPlayer.animation_finished
			$AnimationPlayer.play('pass_down_out')
		PASS_DOWN_IN:
			$AnimationPlayer.play('pass_down_in')
		PASS_DOWN_OUT:
			$AnimationPlayer.play('pass_down_out')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _transition_finished(anim_name := '') -> void:
	transition_finished.emit(anim_name)
