@tool
@icon('res://addons/popochiu/icons/region.png')
class_name PopochiuRegion
extends Area2D
## Used to handle events when a character walks inside or outside of it. Can also be used to scale
## characters while they walk through the region's polygon.
##
## By default, can be used to apply a tint to characters when they enter or leave the region.

## The identifier of the object used in scripts.
@export var script_name := ''
## Can be used to show the name of the area to players.
@export var description := ''
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


#region Godot ######################################################################################
func _ready() -> void:
	add_to_group('regions')
	
	area_entered.connect(_check_area.bind(true))
	area_exited.connect(_check_area.bind(false))
	area_shape_entered.connect(_check_scaling.bind(true))
	area_shape_exited.connect(_check_scaling.bind(false))


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
func _check_area(area: PopochiuCharacter, entered: bool) -> void:
	if area is PopochiuCharacter:
		if entered:
			_on_character_entered(area)
		else:
			_on_character_exited(area)


func _check_scaling(
	area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int, entered: bool
):
	if (
		area is PopochiuCharacter 
		and area.get_node_or_null("ScalingPolygon") 
		and area_shape_index == area.get_node("ScalingPolygon").get_index()
		):
		if entered:
			if scaling:
				_update_scaling_region(area)
				E.current_room.update_character_scale(area)
		else:
			_clear_scaling_region(area)


func _update_scaling_region(chr: PopochiuCharacter) -> void:
	var polygon_y_array = []
	for x in get_node("InteractionPolygon").get_polygon():
		polygon_y_array.append(x.y)

	chr.on_scaling_region= {
		'region_description': self.description,
		'scale_top': self.scale_top, 
		'scale_bottom': self.scale_bottom,
		'scale_max': [self.scale_top, self.scale_bottom].max(),
		'scale_min': [self.scale_top, self.scale_bottom].min(),
		'polygon_top_y': (
			polygon_y_array.min()+self.position.y+get_node("InteractionPolygon").position.y 
			if self.position 
			else ''
			),
		'polygon_bottom_y': (
			polygon_y_array.max()+self.position.y+get_node("InteractionPolygon").position.y 
			if self.position 
			else ''),

		}


func _clear_scaling_region(chr: PopochiuCharacter) -> void:
	if chr.on_scaling_region and chr.on_scaling_region['region_description'] == self.description:
		chr.on_scaling_region = {}


#endregion
