extends CanvasLayer
class_name TransitionLayer

signal transition_finished

export var fade_color := Color.black

enum {
	FADE_IN_OUT,
	FADE_IN,
	FADE_OUT,
	PASS_DOWN_IN_OUT,
	PASS_DOWN_IN,
	PASS_DOWN_OUT,
}

onready var n := {
	fade = find_node('Fade')
}

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	for c in $Transitions.get_children():
		(c as Sprite).modulate = fade_color
	
	$AnimationPlayer.connect('animation_finished', self, '_transition_finished')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func play_transition(type := FADE_IN, duration := 1.0) -> void:
	$AnimationPlayer.playback_speed = 1.0 / duration
	
	match type:
		FADE_IN_OUT:
			$AnimationPlayer.play('fade_in')
			yield($AnimationPlayer, 'animation_finished')
			$AnimationPlayer.play('fade_out')
		FADE_IN:
			$AnimationPlayer.play('fade_in')
		FADE_OUT:
			$AnimationPlayer.play('fade_out')
		PASS_DOWN_IN_OUT:
			$AnimationPlayer.play('pass_down_in')
			yield($AnimationPlayer, 'animation_finished')
			$AnimationPlayer.play('pass_down_out')
		PASS_DOWN_IN:
			$AnimationPlayer.play('pass_down_in')
		PASS_DOWN_OUT:
			$AnimationPlayer.play('pass_down_out')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _transition_finished(anim_name := '') -> void:
	emit_signal('transition_finished')
