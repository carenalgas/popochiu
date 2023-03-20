# (R) Data and functions to work with rooms.
extends Node

var current: PopochiuRoom = null

var _room_instances := {}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func get_prop(prop_name: String) -> PopochiuProp:
	return current.get_prop(prop_name)


func get_hotspot(hotspot_name: String) -> PopochiuHotspot:
	return current.get_hotspot(hotspot_name)


func get_region(region_name: String) -> PopochiuRegion:
	return current.get_region(region_name)


func get_walkable_area(walkable_area_name: String) -> PopochiuWalkableArea:
	return current.get_walkable_area(walkable_area_name)


func get_point(point_name: String) -> Vector2:
	return current.get_point(point_name)


func get_props() -> Array:
	return get_tree().get_nodes_in_group('props')


func get_hotspots() -> Array:
	return get_tree().get_nodes_in_group('hotspots')


func get_regions() -> Array:
	return get_tree().get_nodes_in_group('regions')


func get_markers() -> Array:
	return current.get_markers()


func get_walkable_areas() -> Array:
	return get_tree().get_nodes_in_group('walkable_areas')


func get_runtime_room(script_name: String) -> PopochiuRoom:
	if _room_instances.has(script_name):
		return _room_instances[script_name]
	
	var rp: String = PopochiuResources.get_data_value('rooms', script_name, null)
	if rp.is_empty():
		printerr('[Popochiu] No PopochiuRoom with name: %s' % script_name)
		return null
	
	_room_instances[script_name] = load(load(rp).scene).instantiate()
	
	return _room_instances[script_name]


func clear_instances() -> void:
	for r in _room_instances:
		(_room_instances[r] as PopochiuRoom).free()
	
	_room_instances.clear()
