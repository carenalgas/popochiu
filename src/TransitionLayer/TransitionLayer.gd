extends CanvasLayer

signal transition_finished

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
	$AnimationPlayer.connect('animation_finished', self, '_transition_finished')
	
#	for t in $Transitions.get_children():
#		t.hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func play_transition(name := 'fade_in', direction := 'down', time := 1.0) -> void:
	$AnimationPlayer.playback_speed = 1.0 / time
	
	match name:
		'fade_in':
			$AnimationPlayer.play('fade_in')
		'fade_out':
			$AnimationPlayer.play('fade_out')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _transition_finished(anim_name := '') -> void:
	emit_signal('transition_finished')
