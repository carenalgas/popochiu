@tool
@icon('res://addons/popochiu/icons/region.png')
class_name PopochiuRegion
extends Area2D
# Can trigger events when the player walks checked them. Can tint the PC.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

@export var script_name := ''
@export var description := ''
@export var enabled := true : set = _set_enabled
# TODO: If walkable is false, characters should not be able to walk through this.
#export var walkable := true
@export var tint := Color.WHITE
# TODO: Make the scale of the character change depending checked where it is placed in
# the area.
#export var scale_top := 1.0
#export var scale_bottom := 1.0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	add_to_group('regions')
	
	area_entered.connect(_check_area.bind(true))
	area_exited.connect(_check_area.bind(false))


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _on_character_entered(chr: PopochiuCharacter) -> void:
	pass


func _on_character_exited(chr: PopochiuCharacter) -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _check_area(area: PopochiuCharacter, entered: bool) -> void:
	if area is PopochiuCharacter:
		if entered: _on_character_entered(area)
		else: _on_character_exited(area)


func _set_enabled(value: bool) -> void:
	enabled = value
	monitoring = value
	
	notify_property_list_changed()
