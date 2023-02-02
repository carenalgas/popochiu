tool
class_name PopochiuWalkableArea, 'res://addons/Popochiu/icons/walkable_area.png'
extends Node2D
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

var map_rid: RID
var rid: RID


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	add_to_group('walkable_areas')
	
	if Engine.editor_hint: return
	
	map_rid = Navigation2DServer.get_maps()[0]
	rid = ($Perimeter as NavigationPolygonInstance).get_region_rid()
	
	Navigation2DServer.region_set_map(rid, map_rid)


func _exit_tree() -> void:
	if Engine.editor_hint: return
	
	Navigation2DServer.map_set_active(map_rid, false)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func _set_enabled(value: bool) -> void:
	enabled = value
	property_list_changed_notify()
