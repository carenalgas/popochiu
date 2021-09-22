extends CanvasLayer

signal transition_finished

export var fade_color := Color.black

enum Directions {
	LEFT,
	RIGHT,
	UP,
	DOWN
}

onready var n := {
	fade = find_node('Fade')
}

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	for c in $Transitions.get_children():
		(c as Sprite).modulate = fade_color
	
	$AnimationPlayer.connect('animation_finished', self, '_transition_finished')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func play_transition(name := 'fade_in', time := 1.0) -> void:
	$AnimationPlayer.playback_speed = 1.0 / time
	
	match name:
		'fade_in':
			$AnimationPlayer.play('fade_in')
		'fade_out':
			$AnimationPlayer.play('fade_out')
		'pass_down':
			$AnimationPlayer.play('pass_down_in')
			yield($AnimationPlayer, 'animation_finished')
			$AnimationPlayer.play('pass_down_out')
		'pass_down_in':
			$AnimationPlayer.play('pass_down_in')
		'pass_down_out':
			$AnimationPlayer.play('pass_down_out')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _transition_finished(anim_name := '') -> void:
	emit_signal('transition_finished')
