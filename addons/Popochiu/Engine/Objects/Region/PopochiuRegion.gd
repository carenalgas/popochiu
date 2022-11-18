tool
class_name PopochiuRegion, 'res://addons/Popochiu/icons/region.png'
extends Area2D
# Can trigger events when the player walks on them. Can tint the PC.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

export var script_name := ''
export var description := ''
export var enabled := true setget _set_enabled
# TODO: If walkable is false, characters should not be able to walk through this.
#export var walkable := true
export var tint := Color.white
# TODO: Make the scale of the character change depending on where it is placed in
# the area.
#export var scale_top := 1.0
#export var scale_bottom := 1.0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	add_to_group('regions')
	connect('area_entered', self, '_check_area', [true])
	connect('area_exited', self, '_check_area', [false])


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_character_entered(chr: PopochiuCharacter) -> void:
	pass


func on_character_exited(chr: PopochiuCharacter) -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _check_area(area: PopochiuCharacter, entered: bool) -> void:
	if area is PopochiuCharacter:
		if entered: on_character_entered(area)
		else: on_character_exited(area)


func _set_enabled(value: bool) -> void:
	enabled = value
	monitoring = value
	
	property_list_changed_notify()
