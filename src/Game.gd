extends Node2D

#onready var character: Character = find_node('Dave')
onready var forest: Room = find_node('Forest')
onready var camera: Camera2D = find_node('MainCamera')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	# TODO: La mierda más estúpida y chambona del primer semestre
	forest.on_room_entered()
	$TransitionLayer.play_transition({ name = 'fade_out', time = 0.5})
	yield($TransitionLayer, 'transition_finished')
	forest.on_room_transition_finished()


func _process(delta: float) -> void:
	if C.player:
		camera.position = C.player.position
