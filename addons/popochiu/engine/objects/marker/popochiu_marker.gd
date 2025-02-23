@tool
class_name PopochiuMarker
extends Node2D
## Exposes a Vector2 representing a position on the stage of a Room.
##
## It solves the same purpose as the [code]Marker2D[/code] node, but it is
## shown by means of a Gizmo2D in the editor, for consistency with other
## Popochiu objects.

## The identifier of the object used in scripts.
@export var script_name := ""
## The [Vector2] position that the marker represents.
@export var marker_point := Vector2.ZERO
