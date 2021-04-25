extends Node

var id := ''
var script_name := ''
var text := ''
var description := '' # Aquí irá el código de localización
var visible := true
var disabled := false
var used := false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func turn_on() -> void:
	pass


func turn_off() -> void:
	pass


func turn_off_forever() -> void:
	pass


func hide_forever() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _on_interacted() -> void:
	pass


func _on_interaction_canceled() -> void:
	pass
