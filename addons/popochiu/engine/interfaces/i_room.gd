class_name PopochiuIRoom
extends Node
## Provides access to the [PopochiuRoom]s in the game. Access with [b]R[/b] (e.g.
## [code]R.House.get_prop("Drawer")[/code]).
##
## Use it to access props, hotspots, regions and walkable areas in the current room; or to access to
## data from other rooms. Its script is [b]i_room.gd[/b].[br][br]
##
## Some things you can do with it:[br][br]
## [b]•[/b] Access objects inside the current room.[br]
## [b]•[/b] Access the state of any room.[br]
## [b]•[/b] Move to another room.[br][br]
##
## Examples:
## [codeblock]
## R.get_prop('Scissors').modulate.a = 1.0 # Get Scissors prop and make it visible
## R.Outside.state.is_rainning # Access the is_rainning property in the Outside room
## [/codeblock]

## Provides access to the current room.
var current: PopochiuRoom = null : set = set_current

var _room_instances := {}


#region Public #####################################################################################
## Retrieves the [PopochiuProp] with a [member PopochiuClickable.script_name] matching
## [param prop_name].
func get_prop(prop_name: String) -> PopochiuProp:
	return current.get_prop(prop_name)


## Retrieves the [PopochiuHotspot] with a [member PopochiuClickable.script_name] matching
## [param hotspot_name].
func get_hotspot(hotspot_name: String) -> PopochiuHotspot:
	return current.get_hotspot(hotspot_name)


## Retrieves the [PopochiuRegion] with a [member PopochiuRegion.script_name] matching
## [param region_name].
func get_region(region_name: String) -> PopochiuRegion:
	return current.get_region(region_name)


## Retrieves the [PopochiuWalkableArea] with a [member PopochiuWalkableArea.script_name] matching
## [param walkable_area_name].
func get_walkable_area(walkable_area_name: String) -> PopochiuWalkableArea:
	return current.get_walkable_area(walkable_area_name)


## Retrieves the [Marker2D] with a [member Node.name] matching [param marker_name].
func get_marker(marker_name: String) -> Marker2D:
	return current.get_marker(marker_name)


## Retrieves the [b]global position[/b] of the [Marker2D] with a [member Node.name] matching
## [param marker_name].
func get_marker_position(marker_name: String) -> Vector2:
	return current.get_marker_position(marker_name)


## Returns all the [PopochiuProp]s in the room.
func get_props() -> Array:
	return get_tree().get_nodes_in_group('props')


## Returns all the [PopochiuHotspot]s in the room.
func get_hotspots() -> Array:
	return get_tree().get_nodes_in_group('hotspots')


## Returns all the [PopochiuRegion]s in the room.
func get_regions() -> Array:
	return get_tree().get_nodes_in_group('regions')


## Returns all the [PopochiuWalkableArea]s in the room.
func get_walkable_areas() -> Array:
	return get_tree().get_nodes_in_group('walkable_areas')


## Returns all the [Marker2D]s in the room.
func get_markers() -> Array:
	return current.get_markers()


## Returns the instance of the [PopochiuRoom] identified with [param script_name]. If the room
## doesn't exists, then [code]null[/code] is returned.[br][br]
## This method is used by [b]res://game/autoloads/r.gd[/b] to load the instace of each room (present
## in that script as a variable for code autocompletion) in runtime.
func get_runtime_room(script_name: String) -> PopochiuRoom:
	if _room_instances.has(script_name):
		return _room_instances[script_name]
	
	var rp: String = PopochiuResources.get_data_value('rooms', script_name, null)
	if rp.is_empty():
		printerr('[Popochiu] No PopochiuRoom with name: %s' % script_name)
		return null
	
	_room_instances[script_name] = load(load(rp).scene).instantiate()
	
	return _room_instances[script_name]


## Clears all the [PopochiuRoom] instances to free memory and orphan childs.
func clear_instances() -> void:
	for r in _room_instances:
		(_room_instances[r] as PopochiuRoom).free()
	
	_room_instances.clear()


#endregion

#region SetGet #####################################################################################
func set_current(value: PopochiuRoom) -> void:
	current = value
	
	E.goto_room(current.script_name)


#endregion
