tool
class_name Region, 'res://addons/Popochiu/icons/region.png'
extends Area2D

export var script_name := ''
export var description := ''
export var enabled := true setget _set_enabled
# TODO: Si walkable se vuelve falso, los personajes no deberían poder caminar
#		por ahí.
#export var walkable := true
export var tint := Color.white
# TODO: Implementar esto de la escala para que al entrar al área se agrande el
#		personaje mientras esté en la parte de arriba o en la parte de abajo.
#export var scale_top := 1.0
#export var scale_bottom := 1.0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	connect('area_entered', self, '_check_area', [true])
	connect('area_exited', self, '_check_area', [false])


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_character_entered(chr: PopochiuCharacter) -> void:
	chr.modulate = tint


func on_character_exited(chr: PopochiuCharacter) -> void:
	chr.modulate = Color.white


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _check_area(area: PopochiuCharacter, entered: bool) -> void:
	if area is PopochiuCharacter:
		if entered: on_character_entered(area)
		else: on_character_exited(area)


func _set_enabled(value: bool) -> void:
	enabled = value
	monitoring = value
	property_list_changed_notify()
