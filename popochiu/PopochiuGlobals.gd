extends Node

var took_car := false
var money := 100
var health := 50
var umbrella_position := Vector2.ONE
var cards := ['blue', 'red', 'yellow']


func on_save() -> Dictionary:
	return {
		umbrella_position = {
			x = 200.0,
			y = 300.0
		}
	}


func on_load(data: Dictionary) -> void:
	umbrella_position.x = data.umbrella_position.x
	umbrella_position.y = data.umbrella_position.y
