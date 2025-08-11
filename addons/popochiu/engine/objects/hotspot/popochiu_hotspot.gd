@tool
@icon('res://addons/popochiu/icons/hotspot.png')
class_name PopochiuHotspot
extends PopochiuClickable
## Areas players can interact with (i.e. something that is part of the room's background: the sky,
## an entrance to a cave, a forest in the distance).
##
## When selecting a Hotspot in the scene tree (Scene dock), Popochiu will enable three buttons in
## the Canvas Editor Menu: Baseline, Walk to, and Interaction. This can be used to select the child
## nodes that allow to modify the position of the [member PopochiuClickable.baseline],
## the position of the [member PopochiuClickable.walk_to_point], and the position and the polygon
## points of the [b]$InteractionPolygon[/b] child.

#region Godot ######################################################################################
func _ready() -> void:
	super()
	add_to_group('hotspots')
	
	# Connect movement signals to virtual methods
	if not Engine.is_editor_hint():
		movement_started.connect(_on_movement_started)
		movement_ended.connect(_on_movement_ended)


#endregion

#region Virtual ####################################################################################
## Called when the hotspot starts moving.
## [i]Virtual[/i].
func _on_movement_started() -> void:
	pass


## Called when the hotspot stops moving.
## [i]Virtual[/i].
func _on_movement_ended() -> void:
	pass
