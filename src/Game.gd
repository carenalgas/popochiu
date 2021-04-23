extends Node2D

#onready var character: Character = find_node('Dave')
onready var room: Room = find_node('Room')
onready var camera: Camera2D = find_node('MainCamera')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	room.on_room_entered()

func _process(delta: float) -> void:
	if C.player:
		camera.position = C.player.position
