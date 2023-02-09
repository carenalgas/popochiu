tool
class_name PopochiuWalkableArea, 'res://addons/Popochiu/icons/walkable_area.png'
extends Navigation2D
# Areas players can walk upon.
# No specific behavior at the moment, the area is defined by a polygon.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

export var script_name := ''
export var description := ''
export var enabled := true setget _set_enabled
# TODO: If walkable is false, characters should not be able to walk through this.
#export var walkable := true
export var tint := Color.white
# TODO: Make the scale of the character change depending on where it is placed in
# this walkable area.
#export var scale_top := 1.0
#export var scale_bottom := 1.0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	add_to_group('walkable_areas')
	
	if Engine.editor_hint: return
	
	$Perimeter.position += Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func _set_enabled(value: bool) -> void:
	enabled = value
	property_list_changed_notify()
