tool
extends Resource

export var id := '' setget _set_id
export var text := ''
export var visible := true

var description := '' # Aquí irá el código de localización
var disabled := false
var used := false
var script_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░


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


func _set_id(value: String) -> void:
	id = value
	script_name = id
	resource_name = id
	
	property_list_changed_notify()
