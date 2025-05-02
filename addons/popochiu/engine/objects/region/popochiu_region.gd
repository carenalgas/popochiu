@tool
@icon('res://addons/popochiu/icons/region.png')
class_name PopochiuRegion
extends Area2D
## Used to handle events when a character walks inside or outside of it. Can also be used to scale
## characters while they walk through the region's polygon.
##
## By default, can be used to apply a tint to characters when they enter or leave the region.

## The identifier of the object used in scripts.
@export var script_name := ""
## Can be used to show the name of the area to players.
@export var description := ""
## Whether the region is or not enabled.
@export var enabled := true : set = _set_enabled
## The [Color] to apply to the character that enters this region.
@export var tint := Color.WHITE
## Whether the region will scale the character while it moves through it.
@export var scaling :bool = false
## The scale to apply to the character inside the region when it moves to the top ([code]y[/code])
## of it.
@export var scale_top :float = 1.0
## The scale to apply to the character inside the region when it moves to the bottom
## ([code]y[/code]) of it.
@export var scale_bottom :float = 1.0
## Stores the vertices to assign to the [b]InteractionPolygon[/b] child during runtime. This is used
## by [PopochiuRoom] to store the info in its [code].tscn[/code].
@export var interaction_polygon := PackedVector2Array()
## Stores the position to assign to the [b]InteractionPolygon[/b] child during runtime. This is used
## by [PopochiuRoom] to store the info in its [code].tscn[/code].
@export var interaction_polygon_position := Vector2.ZERO

var _last_char_pos := Vector2.ZERO
var _active_characters := {}

@onready var interaction_polygon_node: CollisionPolygon2D = $InteractionPolygon


#region Godot ######################################################################################
func _ready() -> void:
	add_to_group("regions")

	area_entered.connect(_check_area.bind(true))
	area_exited.connect(_check_area.bind(false))
	area_shape_entered.connect(_check_scaling.bind(true))
	area_shape_exited.connect(_check_scaling.bind(false))

	if Engine.is_editor_hint():
		hide_helpers()

		# Ignore assigning the polygon when:
		if (
			interaction_polygon_node == null # there is no InteractionPolygon node
			or not get_parent() is Node2D # editing it in the .tscn file of the object directly
		):
			return

		# Add interaction polygon to the proper group
		interaction_polygon_node.add_to_group(
			PopochiuEditorHelper.POPOCHIU_OBJECT_POLYGON_GROUP
		)

		if interaction_polygon.is_empty():
			interaction_polygon = interaction_polygon_node.polygon
			interaction_polygon_position = interaction_polygon_node.position
		else:
			interaction_polygon_node.polygon = interaction_polygon
			interaction_polygon_node.position = interaction_polygon_position

		# If we are in the editor, we're done
		return

	# When the game is running...
	# Update the node's polygon when:
	if (
		get_node_or_null("InteractionPolygon") # there is an InteractionPolygon node
	):
		interaction_polygon_node.polygon = interaction_polygon
		interaction_polygon_node.position = interaction_polygon_position


func _notification(event: int) -> void:
	if event == NOTIFICATION_EDITOR_PRE_SAVE:
		interaction_polygon = interaction_polygon_node.polygon
		interaction_polygon_position = interaction_polygon_node.position


#endregion

#region Virtual ####################################################################################
## Called when a [param chr] enters this region.
## [i]Virtual[/i].
func _on_character_entered(chr: PopochiuCharacter) -> void:
	pass


## Called when a [param chr] leaves this region.
## [i]Virtual[/i].
func _on_character_exited(chr: PopochiuCharacter) -> void:
	pass


#endregion

#region SetGet #####################################################################################
func _set_enabled(value: bool) -> void:
	enabled = value
	monitoring = value
	
	notify_property_list_changed()


#endregion

#region Private ####################################################################################
func _check_area(area: Area2D, entered: bool) -> void:
	if not area is PopochiuCharacter: return
	
	if entered:
		_on_character_entered(area)
	else:
		_on_character_exited(area)


func _check_scaling(
	area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int, entered: bool
):
	if not is_instance_valid(area) or not (
		area is PopochiuCharacter
		and area.get("scaling_polygon")
		and area_shape_index == area.get("scaling_polygon").get_index()
	):
		return
	
	var character: PopochiuCharacter = area
	# Track character entry/exit across all shapes
	if entered:
		_active_characters[character.script_name] = area
	elif not character in get_overlapping_areas():
		_active_characters.erase(character.script_name)
		_remove_character_scaling_region(character)
		return
	
	if scaling and _active_characters.has(character.script_name):
		_update_character_scaling_region(character)
		character.update_scale()


func _update_character_scaling_region(chr: PopochiuCharacter) -> void:
	var polygon_y_array := []
	for x: Vector2 in interaction_polygon_node.get_polygon():
		polygon_y_array.append(x.y)
	
	# Get global positions for more accurate calculations 
	var global_top: float = (
		polygon_y_array.min() + global_position.y + interaction_polygon_node.position.y
	)
	var global_bottom: float = (
		polygon_y_array.max() + global_position.y + interaction_polygon_node.position.y
	)
	_last_char_pos = chr.global_position

	var region_height := global_bottom - global_top
	var position_ratio := (chr.global_position.y - global_top) / region_height
	position_ratio = clamp(position_ratio, 0.0, 1.0)
	var target_scale := lerp(scale_top, scale_bottom, position_ratio)
	
	chr.scaling_region = {
		region_description = self.description,
		scale_top = self.scale_top,
		scale_bottom = self.scale_bottom,
		scale_max = [self.scale_top, self.scale_bottom].max(),
		scale_min = [self.scale_top, self.scale_bottom].min(),
		polygon_top_y = global_top,
		polygon_bottom_y = global_bottom,
		target_scale = target_scale
	}


func _remove_character_scaling_region(chr: PopochiuCharacter) -> void:
	if chr.scaling_region and chr.scaling_region.region_description == self.description:
		chr.scaling_region = {}
		_last_char_pos = Vector2.ZERO
		_active_characters.erase(chr.script_name)


#endregion


#region Public #####################################################################################
## Used by the plugin to hide the visual helpers that show the [member baseline] and
## [member walk_to_point] in the 2D Canvas Editor when this node is unselected in the Scene panel.
func hide_helpers() -> void:
	# TODO: visibility logic for gizmos
	if get_node_or_null("InteractionPolygon"):
		interaction_polygon_node.hide()


#endregion
