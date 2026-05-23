# @popochiu-docs-category room-objects
@tool
@icon('res://addons/popochiu/icons/region.png')
class_name PopochiuRegion
extends Area2D
## Defines areas in a room that trigger events when characters enter or exit.
##
## Regions can apply visual effects such as tinting characters or scaling them based on vertical
## position (useful for simulating depth in walkable areas).

## The identifier of the object used in scripts.
@export var script_name := ""
## Can be used to show the name of the area to players.
@export var description := ""
## Whether the region is or not enabled.
@export var enabled := true: set = _set_enabled
## The [Color] to apply to the character that enters this region.
@export var tint := Color.WHITE
## Whether the region will scale the character while it moves through it.
@export var scaling: bool = false
## The scale to apply to the character inside the region when it moves to the top ([code]y[/code])
## of it.
@export var scale_top: float = 1.0
## The scale to apply to the character inside the region when it moves to the bottom
## ([code]y[/code]) of it.
@export var scale_bottom: float = 1.0
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
## Called when [param chr] enters this region.[br]
## Implement this to add custom behavior or update the game state.
func _on_character_entered(chr: PopochiuCharacter) -> void:
	# #435: Respect the character's flag to opt out of region tinting.
	if not chr.ignore_region_tinting:
		chr.modulate = tint


## Called when [param chr] exits this region.[br]
## Implement this to add custom behavior or update the game state.
func _on_character_exited(chr: PopochiuCharacter) -> void:
	# #435: Only restore the color if the character accepts tinting from regions.
	if not chr.ignore_region_tinting:
		chr.modulate = Color.WHITE


#endregion

#region Public #####################################################################################
## Returns [code]true[/code] if [param chr]'s [b]ScalingPolygon[/b] is currently inside this region.
func has_character(chr: PopochiuCharacter) -> bool:
	return _active_characters.has(chr.script_name)


## Returns [code]true[/code] if [param marker]'s global position is inside this region's polygon.
func has_marker(marker: Marker2D) -> bool:
	return Geometry2D.is_point_in_polygon(marker.global_position, _get_global_polygon())


## Returns all [PopochiuCharacter]s whose [b]ScalingPolygon[/b] is currently inside this region.
func get_characters() -> Array[PopochiuCharacter]:
	var characters: Array[PopochiuCharacter] = []
	for chr: PopochiuCharacter in _active_characters.values():
		characters.append(chr)
	return characters


## Returns all [Marker2D]s whose global position falls inside this region's polygon.
func get_markers() -> Array[Marker2D]:
	var markers: Array[Marker2D] = []
	var global_polygon := _get_global_polygon()
	for marker: Marker2D in (owner as PopochiuRoom).get_markers():
		if Geometry2D.is_point_in_polygon(marker.global_position, global_polygon):
			markers.append(marker)
	return markers


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
) -> void:
	# Fixes #505: Only trigger scaling behavior if the shape that entered/exited belongs
	# to the character's ScalingPolygon.
	# Identify the physical shape that fired by resolving it to its owner node, then compare
	# against the character's ScalingPolygon. Previously we were comparing against the child index
	# (position in scene tree) with an area_shape_index: it worked by coincidence because
	# the ScalingPolygon was the first child of a "standard" character.
	if not is_instance_valid(area) or not (
		area is PopochiuCharacter
		and area.get("scaling_polygon")
		and area.shape_owner_get_owner(
			area.shape_find_owner(area_shape_index)
		) == area.get("scaling_polygon")
	):
		return
	
	var character: PopochiuCharacter = area
	# Fixes #505
	# Only the ScalingPolygon shape drives entry and exit decisions. Because we check the exact
	# shape node above, the InteractionPolygon still overlapping the region on exit is irrelevant
	# and does not prevent the scaling reset.
	if entered:
		_active_characters[character.script_name] = area
	else:
		_active_characters.erase(character.script_name)
		_remove_character_scaling_region(character)
		return
	
	# #435: Skip applying scaling region data if the character opts out of region scaling.
	if scaling and _active_characters.has(character.script_name) and not character.ignore_region_scaling:
		_update_character_scaling_region(character)
		character.update_scale()


func _update_character_scaling_region(chr: PopochiuCharacter) -> void:
	var polygon_y_array: Array[float] = []
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


# Returns the region's polygon vertices transformed to global space.
func _get_global_polygon() -> PackedVector2Array:
	var global_polygon := PackedVector2Array()
	for point: Vector2 in interaction_polygon_node.polygon:
		global_polygon.append(interaction_polygon_node.to_global(point))
	return global_polygon


#endregion
