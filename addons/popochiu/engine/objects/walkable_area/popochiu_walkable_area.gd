@tool
@icon('res://addons/popochiu/icons/walkable_area.png')
class_name PopochiuWalkableArea
extends Node2D
# Areas players can walk upon.
# No specific behavior at the moment, the area is defined by a polygon.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

@export var script_name := ''
@export var description := ''
@export var enabled := true : set = _set_enabled
# TODO: If walkable is false, characters should not be able to walk through this.
#export var walkable := true
@export var tint := Color.WHITE
# TODO: Make the scale of the character change depending checked where it is placed in
# this walkable area.
#export var scale_top := 1.0
#export var scale_bottom := 1.0

var map_rid: RID
var rid: RID


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	add_to_group('walkable_areas')
	
	if Engine.is_editor_hint(): return
	
	map_rid = NavigationServer2D.get_maps()[0]
	rid = ($Perimeter as NavigationRegion2D).get_region_rid()
	NavigationServer2D.region_set_map(rid, map_rid)


func _exit_tree():
	if Engine.is_editor_hint(): return
	
	NavigationServer2D.map_set_active(map_rid, false)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func _set_enabled(value: bool) -> void:
	enabled = value
	notify_property_list_changed()
