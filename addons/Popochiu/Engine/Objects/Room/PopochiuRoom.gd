tool
class_name PopochiuRoom, 'res://addons/Popochiu/icons/room.png'
extends YSort
# The scenes used by Popochiu. Can have: Props, Hotspots, Regions, Points and
# Walkable areas. Characters can move through this and interact with its Props
# and Hotspots. Regions can be used to trigger methods when a character enters
# or leaves.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

export var script_name := ''
export var has_player := true
export var hide_gi := false
export var limit_left := INF
export var limit_right := INF
export var limit_top := INF
export var limit_bottom := INF

var is_current := false setget set_is_current
var characters_cfg := [] # Array of Dictionary

var _path := []
var _moving_character: PopochiuCharacter = null
var _nav_path: PopochiuWalkableArea = null


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _enter_tree() -> void:
	if Engine.editor_hint:
		sort_enabled = false
		$Props.sort_enabled = false
		$Characters.sort_enabled = false
		
		return
	else:
		sort_enabled = true
		$Props.sort_enabled = true
		$Characters.sort_enabled = true
	
	for c in $Characters.get_children():
		if c is PopochiuCharacter:
			var pc: PopochiuCharacter = c
			characters_cfg.append({
				script_name = pc.script_name,
				position = pc.position
			})
			
			$Characters.remove_child(pc)
			pc.queue_free()


func _ready():
	if Engine.editor_hint: return
	
	if not get_tree().get_nodes_in_group('walkable_areas').empty():
		_nav_path = get_tree().get_nodes_in_group('walkable_areas')[0]
	
	set_process_unhandled_input(false)
	E.room_readied(self)


func _process(delta):
	if Engine.editor_hint or not is_instance_valid(C.player) or not has_player:
		return
	
	if _path.empty(): return
	
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
		C.player.walk(get_local_mouse_position(), false)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# What happens when Popochiu loads the room. At this point the room is in the
# tree but it is not visible.
func on_room_entered() -> void:
	pass


# What happens when the room changing transition finishes. At this point the room
# is visible.
func on_room_transition_finished() -> void:
	pass


# What happens before Popochiu unloads the room. At this point the room is in the
# tree but it is not visible, it is not processing and has no childs in the
# $Characters node.
func on_room_exited() -> void:
	pass


# TODO: Make this to work and then add it to RoomTemplate.gd
func on_entered_from_editor() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# This function is called by Popochiu before moving the PC to another room. By
# default, characters are removed only to keep their instances in the array
# of characters in ICharacter.gd.
func exit_room() -> void:
	set_process(false)
	
	for c in $Characters.get_children():
		$Characters.remove_child(c)
	
	on_room_exited()


func add_character(chr: PopochiuCharacter) -> void:
	$Characters.add_child(chr)
	#warning-ignore:return_value_discarded
	chr.connect('started_walk_to', self, '_update_navigation_path')
	chr.connect('stoped_walk', self, '_clear_navigation_path')


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


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func get_point(point_name: String) -> Vector2:
	var point: Position2D = get_node_or_null('Points/' + point_name)
	if point:
		return point.global_position
	printerr('PopochiuRoom[%s].get_point: No se encontró el punto %s' % [script_name, point_name])
	return Vector2.ZERO


func get_prop(prop_name: String) -> PopochiuProp:
	for p in get_tree().get_nodes_in_group('props'):
		if p.script_name == prop_name or p.name == prop_name:
			return p as PopochiuProp
	printerr('PopochiuRoom[%s].get_prop: Prop %s not found' % [script_name, prop_name])
	return null


func get_hotspot(hotspot_name: String) -> PopochiuHotspot:
	for h in get_tree().get_nodes_in_group('hotspots'):
		if h.script_name == hotspot_name or h.name == hotspot_name:
			return h
	printerr('PopochiuRoom[%s].get_hotspot: Hotspot %s not found' %\
	[script_name, hotspot_name])
	return null


func get_region(region_name: String) -> PopochiuRegion:
	for r in get_tree().get_nodes_in_group('regions'):
		if r.script_name == region_name or r.name == region_name:
			return r
	printerr('PopochiuRoom[%s].get_region: Region %s not found' %\
	[script_name, region_name])
	return null


func get_walkable_area(walkable_area_name: String) -> PopochiuWalkableArea:
	for wa in get_tree().get_nodes_in_group('walkable_areas'):
		if wa.name == walkable_area_name:
			return wa
	printerr('PopochiuRoom[%s].get_walkable_area: Walkable area %s not found' %\
	[script_name, walkable_area_name])
	return null


func get_props() -> Array:
	return get_tree().get_nodes_in_group('props')


func get_hotspots() -> Array:
	return get_tree().get_nodes_in_group('hotspots')


func get_regions() -> Array:
	return get_tree().get_nodes_in_group('regions')


func get_points() -> Array:
	return $Points.get_children()


func get_walkable_areas() -> Array:
	return get_tree().get_nodes_in_group('walkable_areas')


func get_active_walkable_area() -> PopochiuWalkableArea:
	return _nav_path


func get_active_walkable_area_name() -> String:
	return _nav_path.name


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
		printerr('PopochiuRoom[%s].set_active_walkable_area: Walkable area %s not found' %\
		[script_name, walkable_area_name])


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _move_along_path(distance):
	var last_point = _moving_character.position
	
	while _path.size():
		var distance_between_points = last_point.distance_to(_path[0])
		if distance <= distance_between_points:
			_moving_character.position = last_point.linear_interpolate(
				_path[0], distance / distance_between_points
			)
			return

		distance -= distance_between_points
		last_point = _path[0]
		_path.remove(0)

	_moving_character.position = last_point
	_clear_navigation_path()


func _update_navigation_path(
	character: PopochiuCharacter, start_position: Vector2, end_position: Vector2
):
	if not _nav_path:
		prints('[Popochiu] No walkable areas in this room')
		return
	
	# TODO: Use a Dictionary so more than one character can move around at the
	# same time. Or maybe each character should handle its own movement? (;￢＿￢)
	if character.ignore_walkable_areas:
		# if the character can ignore WAs, just move over a straight line
		_path = PoolVector2Array([start_position, end_position])
	else:
		# if the character is forced into WAs, delegate pathfinding to the active WA
		_path = _nav_path.get_simple_path(start_position, end_position, true)
	
	if _path.empty():
		return
	
	_path.remove(0)
	_moving_character = character
	
	set_process(true)


func _clear_navigation_path() -> void:
	# FIX: 'function signature missmatch in Web export' error thrown when clearing
	# an empty Array.
	if not _path.empty():
		_path.clear()
	
	_moving_character.idle(false)
	C.emit_signal('character_move_ended', _moving_character)
	_moving_character = null
