# The scenes used by Popochiu.
# 
# Can have: Props, Hotspots, Regions, Markers and
# Walkable areas. Characters can move through this and interact with its Props
# and Hotspots. Regions can be used to trigger methods when a character enters
# or leaves.
@tool
@icon('res://addons/popochiu/icons/room.png')
class_name PopochiuRoom
extends Node2D

@export var script_name := ''
@export var has_player := true
@export var hide_gi := false
@export_category("Camera limits")
@export var limit_left := INF
@export var limit_right := INF
@export var limit_top := INF
@export var limit_bottom := INF

var is_current := false : set = set_is_current

var _path: PackedVector2Array = PackedVector2Array()
var _moving_character: PopochiuCharacter = null
var _nav_path: PopochiuWalkableArea = null


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _enter_tree() -> void:
	if Engine.is_editor_hint():
		y_sort_enabled = false
		$Props.y_sort_enabled = false
		$Characters.y_sort_enabled = false
		
		return
	else:
		y_sort_enabled = true
		$Props.y_sort_enabled = true
		$Characters.y_sort_enabled = true


func _ready():
	if Engine.is_editor_hint(): return
	
	if not get_tree().get_nodes_in_group('walkable_areas').is_empty():
		_nav_path = get_tree().get_nodes_in_group('walkable_areas')[0]
		NavigationServer2D.map_set_active(_nav_path.map_rid, true)
	
	set_process_unhandled_input(false)
	set_physics_process(false)
	
	E.room_readied(self)


func _physics_process(delta):
	if _path.is_empty(): return
	
	var walk_distance = _moving_character.walk_speed * delta
	_move_along_path(walk_distance)


func _unhandled_input(event):
	if not has_player: return
	
	if I.active:
		if event.is_action_released('popochiu-look')\
		or event.is_action_pressed('popochiu-interact'):
			I.set_active_item()
		return
	
	if not event.is_action_pressed('popochiu-interact'):
		return
	
	if is_instance_valid(C.player) and C.player.can_move:
		C.player.walk(get_local_mouse_position())


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# What happens when Popochiu loads the room. At this point the room is in the
# tree but it is not visible.
func _on_room_entered() -> void:
	pass


# What happens when the room changing transition finishes. At this point the room
# is visible.
func _on_room_transition_finished() -> void:
	pass


# What happens before Popochiu unloads the room. At this point the room is in the
# tree but it is not visible, it is not processing and has no childs in the
# $Characters node.
func _on_room_exited() -> void:
	pass


# TODO: Make this to work and then add it to RoomTemplate.gd
func _on_entered_from_editor() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# This function is called by Popochiu before moving the PC to another room. By
# default, characters are removed only to keep their instances in the array
# of characters in ICharacter.gd.
func exit_room() -> void:
	set_physics_process(false)
	
	for c in $Characters.get_children():
		$Characters.remove_child(c)
	
	_on_room_exited()


func add_character(chr: PopochiuCharacter) -> void:
	$Characters.add_child(chr)
	#warning-ignore:return_value_discarded
	chr.started_walk_to.connect(_update_navigation_path)
	chr.stoped_walk.connect(_clear_navigation_path)
	
	chr.idle()


func remove_character(chr: PopochiuCharacter) -> void:
	$Characters.remove_child(chr)


func hide_props() -> void:
	for p in $Props.get_children():
		p.hide()


func has_character(character_name: String) -> bool:
	var result := false
	
	for c in $Characters.get_children():
		if (c as PopochiuCharacter).script_name == character_name:
			result = true
			break
	
	return result


func setup_camera() -> void:
	if limit_left != INF:
		E.main_camera.limit_left = limit_left
	if limit_right != INF:
		E.main_camera.limit_right = limit_right
	if limit_top != INF:
		E.main_camera.limit_top = limit_top
	if limit_bottom != INF:
		E.main_camera.limit_bottom = limit_bottom


func clean_characters() -> void:
	for c in $Characters.get_children():
		if c is PopochiuCharacter:
			c.queue_free()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func get_marker(marker_name: String) -> Vector2:
	var marker: Marker2D = get_node_or_null('Markers/' + marker_name)
	if marker:
		return marker.global_position
	printerr('[Popochiu] Marker %s not found' % marker_name)
	return Vector2.ZERO


func get_prop(prop_name: String) -> PopochiuProp:
	for p in get_tree().get_nodes_in_group('props'):
		if p.script_name == prop_name or p.name == prop_name:
			return p as PopochiuProp
	printerr('[Popochiu] Prop %s not found' % prop_name)
	return null


func get_hotspot(hotspot_name: String) -> PopochiuHotspot:
	for h in get_tree().get_nodes_in_group('hotspots'):
		if h.script_name == hotspot_name or h.name == hotspot_name:
			return h
	printerr('[Popochiu] Hotspot %s not found' % hotspot_name)
	return null


func get_region(region_name: String) -> PopochiuRegion:
	for r in get_tree().get_nodes_in_group('regions'):
		if r.script_name == region_name or r.name == region_name:
			return r
	printerr('[Popochiu] Region %s not found' % region_name)
	return null


func get_walkable_area(walkable_area_name: String) -> PopochiuWalkableArea:
	for wa in get_tree().get_nodes_in_group('walkable_areas'):
		if wa.name == walkable_area_name:
			return wa
	printerr('[Popochiu] Walkable area %s not found' % walkable_area_name)
	return null


func get_props() -> Array:
	return get_tree().get_nodes_in_group('props')


func get_hotspots() -> Array:
	return get_tree().get_nodes_in_group('hotspots')


func get_regions() -> Array:
	return get_tree().get_nodes_in_group('regions')


func get_markers() -> Array:
	return $Markers.get_children()


func get_walkable_areas() -> Array:
	return get_tree().get_nodes_in_group('walkable_areas')


func get_active_walkable_area() -> PopochiuWalkableArea:
	return _nav_path


func get_active_walkable_area_name() -> String:
	return _nav_path.script_name


func get_characters() -> Array:
	var characters := []
	
	for c in $Characters.get_children():
		if c is PopochiuCharacter:
			characters.append(c)
	
	return characters


func get_characters_count() -> int:
	return $Characters.get_child_count()


func set_is_current(value: bool) -> void:
	is_current = value
	set_process_unhandled_input(is_current)


func set_active_walkable_area(walkable_area_name: String) -> void:
	var active_walkable_area = $WalkableAreas.get_node(walkable_area_name)
	if active_walkable_area != null:
		_nav_path = active_walkable_area
	else:
		printerr(
			"[Popochiu] Can't set %s as active walkable area" % walkable_area_name
		)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _move_along_path(distance):
	var last_point = _moving_character.position
	
	while _path.size():
		var distance_between_points = last_point.distance_to(_path[0])
		if distance <= distance_between_points:
			_moving_character.position = last_point.lerp(
				_path[0], distance / distance_between_points
			)
			return

		distance -= distance_between_points
		last_point = _path[0]
		_path.remove_at(0)

	_moving_character.position = last_point
	_clear_navigation_path()


func _update_navigation_path(
	character: PopochiuCharacter, start_position: Vector2, end_position: Vector2
):
	if not _nav_path:
		printerr('[Popochiu] No walkable areas in this room')
		return
	
	_moving_character = character
	
	# TODO: Use a Dictionary so more than one character can move around at the
	# same time. Or maybe each character should handle its own movement? (;￢＿￢)
	if character.ignore_walkable_areas:
		# if the character can ignore WAs, just move over a straight line
		_path = PackedVector2Array([start_position, end_position])
	else:
		# if the character is forced into WAs, delegate pathfinding to the active WA
		_path = NavigationServer2D.map_get_path(
			_nav_path.map_rid, start_position, end_position, true
		)
		
		# TODO: Use NavigationAgent2D target_location and get_next_location() to
		#		maybe improve characters movement with obstacles avoidance?
#		NavigationServer2D.agent_set_map(character.agent.get_rid(), _nav_path.map_rid)
#		character.agent.target_location = end_position
#		_path = character.agent.get_nav_path()
#		set_physics_process(true)
#		return
	
	if _path.is_empty():
		return
	
	_path.remove_at(0)
	
	set_physics_process(true)


func _clear_navigation_path() -> void:
	# FIX: 'function signature missmatch in Web export' error thrown when clearing
	# an empty Array.
	if not _path.is_empty():
		_path.clear()
	
	_moving_character.idle()
	C.character_move_ended.emit(_moving_character)
	_moving_character = null
