@tool
@icon("res://addons/popochiu/icons/room.png")
class_name PopochiuRoom
extends Node2D
## Each scene of the game. Is composed by Props, Hotspots, Regions, Markers, Walkable areas, and
## Characters.
## 
## Characters can move through it in the spaces defined by walkable areas, interact with its props
## and hotspots, react to its regions, and move to its markers.

## The identifier of the object used in scripts.
@export var script_name := ""
## Whether this room should add the Player-controlled Character (PC) to its [b]$Characters[/b] node
## when the room is loaded.
@export var has_player := true
## If [code]true[/code] the whole GUI will be hidden when the room is loaded. Useful for cutscenes,
## splash screens and when showing game menus or popups.
@export var hide_gi := false
@export_category("Camera limits")
## If this different from [constant INF], the value will define the left limit of the camera
## relative to the native game resolution. I.e. if your native game resolution is 320x180, and the
## background (size) of the room is 448x180, the left limit of the camera should be -64 (this is the
## difference between 320 and 448).
## [br][br][i]Set this on rooms that are bigger than the native game resolution so the camera will
## follow the character.[/i]
@export var limit_left := INF
## If this different from [constant INF], the value will define the right limit of the camera
## relative to the native game resolution. I.e. if your native game resolution is 320x180, and the
## background (size) of the room is 448x180, the right limit of the camera should be 384 (320 + 64
## (this is the difference between 320 and 448)).
## [br][br][i]Set this on rooms that are bigger than the native game resolution so the camera will
## follow the character.[/i]
@export var limit_right := INF
## If this different from [constant INF], the value will define the top limit of the camera
## relative to the native game resolution.
## [br][br][i]Set this on rooms that are bigger than the native game resolution so the camera will
## follow the character.[/i]
@export var limit_top := INF
## If this different from [constant INF], the value will define the bottom limit of the camera
## relative to the native game resolution.
## [br][br][i]Set this on rooms that are bigger than the native game resolution so the camera will
## follow the character.[/i]
@export var limit_bottom := INF
# This category is used by the Aseprite Importer in order to allow the creation of a section in the
# Inspector for it.
@export_category("Aseprite")

## Whether this is the room in which players are. When [code]true[/code], the room starts processing
## unhandled inputs.
var is_current := false : set = set_is_current

var _nav_path: PopochiuWalkableArea = null
# It contains the information of the characters moving around the room. Each entry has the form:
# PopochiuCharacter.ID: int = {
#     character: PopochiuCharacter,
#     path: PackedVector2Array
# }
var _moving_characters := {}
# Stores the childrens defined in the Editor"s Scene tree for each character inside $Characters to
# add them to the corresponding PopochiuCharacter instance when the room is loaded in runtime.
var _characters_childs := {}


#region Godot ######################################################################################
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
	
	if not get_tree().get_nodes_in_group("walkable_areas").is_empty():
		_nav_path = get_tree().get_nodes_in_group("walkable_areas")[0]
		NavigationServer2D.map_set_active(_nav_path.map_rid, true)
	
	set_process_unhandled_input(false)
	set_physics_process(false)
	
	# Connect to singletons signals
	G.blocked.connect(_on_graphic_interface_blocked)
	G.unblocked.connect(_on_graphic_interface_unblocked)
	
	E.room_readied(self)


func _get_property_list() -> Array[Dictionary]:
	return [
		{
			name = "popochiu_placeholder",
			type = TYPE_NIL,
		}
	]


func _physics_process(delta):
	if _moving_characters.is_empty(): return

	for character_id in _moving_characters:
		var moving_character_data: Dictionary = _moving_characters[character_id]
		var walk_distance = (
			moving_character_data.character as PopochiuCharacter
		).walk_speed * delta

		_move_along_path(walk_distance, moving_character_data)


func _unhandled_input(event: InputEvent):
	if not has_player: return
	
	if I.active:
		if event.is_action_released("popochiu-look")\
		or event.is_action_pressed("popochiu-interact"):
			# Wait so PopochiuClickable can handle the interaction
			await get_tree().create_timer(0.1).timeout
			
			I.set_active_item()
		return
	
	if PopochiuUtils.get_click_or_touch_index(event) != MOUSE_BUTTON_LEFT:
		return
	
	if not event is InputEventScreenTouch and E.hovered:
		return
	
	if is_instance_valid(C.player) and C.player.can_move:
		# Set this property to null in order to cancel any running interaction with a
		# PopochiuClickable (check PopochiuCharacter.walk_to_clicked(...))
		E.clicked = null
		
		C.player.walk(get_local_mouse_position())


#endregion

#region Virtual ####################################################################################
## Called when Popochiu loads the room. At this point the room is in the tree but it is not visible.
func _on_room_entered() -> void:
	pass


## Called when the room-changing transition finishes. At this point the room is visible.
func _on_room_transition_finished() -> void:
	pass


## Called before Popochiu unloads the room. At this point the room is in the tree but it is not
## visible, it is not processing inputs, and has no childrens in the [b]$Characters[/b] node.
func _on_room_exited() -> void:
	pass


#endregion

#region Public #####################################################################################
## Called by Popochiu before moving the Player-controlled Character (PC) to another room.
## By default, characters are only removed (not deleted) to keep their instances in memory.
func exit_room() -> void:
	set_physics_process(false)
	
	for c in $Characters.get_children():
		c.position_stored = null
		
		for character_child: Node in c.get_children():
			if character_child.owner != c:
				character_child.queue_free()
		
		$Characters.remove_child(c)
	
	_on_room_exited()


## Adds the instance (in memory) of [param chr] to the [b]$Characters[/b] node and connects to its
## [signal PopochiuCharacter.started_walk_to] and [signal PopochiuCharacter.stoped_walk] signals.
## It also adds to it any children of the character in the Editor"s Scene tree. The [b]idle[/b]
## animation is triggered.
func add_character(chr: PopochiuCharacter) -> void:
	$Characters.add_child(chr)
	
	# Fix #191 by checking if the character had childs defined in the Room's Scene (Editor)
	if _characters_childs.has(chr.script_name):
		# Add child nodes (defined in the Scene tree of the room) to the instance of the character
		for child: Node in _characters_childs[chr.script_name]:
			chr.add_child(child)
	
	#warning-ignore:return_value_discarded
	chr.started_walk_to.connect(_update_navigation_path)
	chr.stopped_walk.connect(_clear_navigation_path.bind(chr))
	
	update_characters_position(chr)
	
	if chr.follow_player:
		C.player.started_walk_to.connect(_follow_player.bind(chr))
	
	chr.idle()


## Removes [param chr] the [b]$Characters[/b] node without destroying it.
func remove_character(chr: PopochiuCharacter) -> void:
	$Characters.remove_child(chr)


## Hides all its [PopochiuProp]s.
func hide_props() -> void:
	for prop: PopochiuProp in get_props():
		prop.hide()


## Checks if the [PopochiuCharacter], whose property [member PopochiuCharacter.script_name] matches
## [param character_name], is inside the [b]$Characters[/b] node.
func has_character(character_name: String) -> bool:
	var result := false
	
	for c in $Characters.get_children():
		if (c as PopochiuCharacter).script_name == character_name:
			result = true
			break
	
	return result


## Called by Popochiu when loading the room to assign its camera limits to the player camera.
func setup_camera() -> void:
	if limit_left != INF:
		E.main_camera.limit_left = limit_left
	if limit_right != INF:
		E.main_camera.limit_right = limit_right
	if limit_top != INF:
		E.main_camera.limit_top = limit_top
	if limit_bottom != INF:
		E.main_camera.limit_bottom = limit_bottom


## Remove all children from the [b]$Characters[/b] node, storing the children of each node to later
## assign them to the corresponding [PopochiuCharacter] when the room is loaded.
func clean_characters() -> void:
	for c in $Characters.get_children():
		if not c is PopochiuCharacter: continue
		
		_characters_childs[c.script_name] = []
		
		for character_child: Node in c.get_children():
			if not character_child.owner == self: continue
			
			c.remove_child(character_child)
			_characters_childs[c.script_name].append(character_child)
		
		c.queue_free()


## Updates the scale of [param chr] depending on the properties of the scaling region where it is
## located.
func update_character_scale(chr: PopochiuCharacter):
	if chr.on_scaling_region:
		var polygon_range = (
			chr.on_scaling_region["polygon_bottom_y"] - chr.on_scaling_region["polygon_top_y"]
			)
		var scale_range = (
			chr.on_scaling_region["scale_bottom"] - chr.on_scaling_region["scale_top"]
			)

		var position_from_the_top_of_region = (
			chr.position.y-chr.on_scaling_region["polygon_top_y"]
			)

		var scale_for_position = (
			chr.on_scaling_region["scale_top"]+(
				scale_range/polygon_range*position_from_the_top_of_region
		)
		)
		chr.scale.x = [
			[scale_for_position, chr.on_scaling_region["scale_min"]].max(), 
			chr.on_scaling_region["scale_max"]
		].min()
		chr.scale.y = [
			[scale_for_position, chr.on_scaling_region["scale_min"]].max(), 
			chr.on_scaling_region["scale_max"]
		].min()
		chr.walk_speed = chr.default_walk_speed/chr.default_scale.x*scale_for_position
	else:
		chr.scale = chr.default_scale
		chr.walk_speed = chr.default_walk_speed


## Updates the position of [param character] in the room, and then updates its scale.
func update_characters_position(character: PopochiuCharacter):
	character.position = (
		character.position_stored 
		if character.position_stored 
		else character.position
		)
	update_character_scale(character)


## Returns the [Marker2D] which [member Node.name] matches [param marker_name].
func get_marker(marker_name: String) -> Marker2D:
	var marker: Marker2D = get_node_or_null("Markers/" + marker_name)
	if marker:
		return marker
	PopochiuUtils.print_error("Marker %s not found" % marker_name)
	return null


## Returns the [b]global position[/b] of the [Marker2D] which [member Node.name] matches
## [param marker_name].
func get_marker_position(marker_name: String) -> Vector2:
	var marker := get_marker(marker_name)
	return marker.global_position if marker != null else Vector2.ZERO


## Returns the [PopochiuProp] which [member PopochiuClickable.script_name] matches
## [param prop_name].
func get_prop(prop_name: String) -> PopochiuProp:
	for p in get_tree().get_nodes_in_group("props"):
		if p.script_name == prop_name or p.name == prop_name:
			return p as PopochiuProp
	PopochiuUtils.print_error("Prop %s not found" % prop_name)
	return null


## Returns the [PopochiuHotspot] which [member PopochiuClickable.script_name] matches
## [param hotspot_name].
func get_hotspot(hotspot_name: String) -> PopochiuHotspot:
	for h in get_tree().get_nodes_in_group("hotspots"):
		if h.script_name == hotspot_name or h.name == hotspot_name:
			return h
	PopochiuUtils.print_error("Hotspot %s not found" % hotspot_name)
	return null


## Returns the [PopochiuRegion] which [member PopochiuRegion.script_name] matches
## [param region_name].
func get_region(region_name: String) -> PopochiuRegion:
	for r in get_tree().get_nodes_in_group("regions"):
		if r.script_name == region_name or r.name == region_name:
			return r
	PopochiuUtils.print_error("Region %s not found" % region_name)
	return null


## Returns the [PopochiuWalkableArea] which [member PopochiuWalkableArea.script_name] matches
## [param walkable_area_name].
func get_walkable_area(walkable_area_name: String) -> PopochiuWalkableArea:
	for wa in get_tree().get_nodes_in_group("walkable_areas"):
		if wa.name == walkable_area_name:
			return wa
	PopochiuUtils.print_error("Walkable area %s not found" % walkable_area_name)
	return null


## Returns all the [PopochiuProp]s in the room.
func get_props() -> Array:
	return get_tree().get_nodes_in_group("props")


## Returns all the [PopochiuHotspot]s in the room.
func get_hotspots() -> Array:
	return get_tree().get_nodes_in_group("hotspots")


## Returns all the [PopochiuRegion]s in the room.
func get_regions() -> Array:
	return get_tree().get_nodes_in_group("regions")


## Returns all the [Marker2D]s in the room.
func get_markers() -> Array:
	return $Markers.get_children()


## Returns all the [PopochiuWalkableArea]s in the room.
func get_walkable_areas() -> Array:
	return get_tree().get_nodes_in_group("walkable_areas")


## Returns the current active [PopochiuWalkableArea].
func get_active_walkable_area() -> PopochiuWalkableArea:
	return _nav_path


## Returns the [member PopochiuWalkableArea.script_name] of current active [PopochiuWalkableArea].
func get_active_walkable_area_name() -> String:
	return _nav_path.script_name


## Returns all the [PopochiuCharacter]s in the room.
func get_characters() -> Array:
	var characters := []
	
	for c in $Characters.get_children():
		if c is PopochiuCharacter:
			characters.append(c)
	
	return characters


## Returns the number of characters in the room.
func get_characters_count() -> int:
	return $Characters.get_child_count()


## Sets as active the [PopochiuWalkableArea] which [member Node.name] matches
## [param walkable_area_name].
func set_active_walkable_area(walkable_area_name: String) -> void:
	var active_walkable_area = $WalkableAreas.get_node(walkable_area_name)
	if active_walkable_area != null:
		_nav_path = active_walkable_area
	else:
		PopochiuUtils.print_error("Can't set %s as active walkable area" % walkable_area_name)


#endregion

#region SetGet #####################################################################################
func set_is_current(value: bool) -> void:
	is_current = value
	set_process_unhandled_input(is_current)


#endregion

#region Private ####################################################################################
func _on_graphic_interface_blocked() -> void:
	set_process_unhandled_input(false)


func _on_graphic_interface_unblocked() -> void:
	set_process_unhandled_input(true)


func _move_along_path(distance: float, moving_character_data: Dictionary):
	var last_point: Vector2 =( 
		moving_character_data.character.position_stored 
		if moving_character_data.character.position_stored 
		else moving_character_data.character.position
		)

	while moving_character_data.path.size():
		var distance_between_points = last_point.distance_to(
			moving_character_data.path[0]
		)
		
		if distance <= distance_between_points:
			moving_character_data.character.take_turn(moving_character_data.path[0])
			var next_position = last_point.lerp(
					moving_character_data.path[0], distance / distance_between_points
				)
			if moving_character_data.character.anti_glide_animation:
				moving_character_data.character.position_stored = next_position
			else:
				moving_character_data.character.position = next_position
				update_character_scale(moving_character_data.character)
			return

		distance -= distance_between_points
		last_point = moving_character_data.path[0]
		moving_character_data.path.remove_at(0)

	moving_character_data.character.position = last_point
	update_character_scale(moving_character_data.character)
	_clear_navigation_path(moving_character_data.character)


func _update_navigation_path(
	character: PopochiuCharacter, start_position: Vector2, end_position: Vector2
):
	if not _nav_path:
		PopochiuUtils.print_error("No walkable areas in this room")
		return
	
	_moving_characters[character.get_instance_id()] = {}
	var moving_character_data: Dictionary = _moving_characters[character.get_instance_id()]
	moving_character_data.character = character
	
	# TODO: Use a Dictionary so more than one character can move around at the
	# same time. Or maybe each character should handle its own movement? (;￢＿￢)
	if character.ignore_walkable_areas:
		# if the character can ignore WAs, just move over a straight line
		moving_character_data.path = PackedVector2Array([start_position, end_position])
	else:
		# if the character is forced into WAs, delegate pathfinding to the active WA
		moving_character_data.path = NavigationServer2D.map_get_path(
			_nav_path.map_rid, start_position, end_position, true
		)
		
		# TODO: Use NavigationAgent2D target_location and get_next_location() to
		#		maybe improve characters movement with obstacles avoidance?
#		NavigationServer2D.agent_set_map(character.agent.get_rid(), _nav_path.map_rid)
#		character.agent.target_location = end_position
#		_path = character.agent.get_nav_path()
#		set_physics_process(true)
#		return
	
	if moving_character_data.path.is_empty():
		return
	
	moving_character_data.path.remove_at(0)
	
	set_physics_process(true)


func _clear_navigation_path(character: PopochiuCharacter) -> void:
	# INFO: fixes "function signature missmatch in Web export" error thrown when
	# clearing an empty Array.
	if not _moving_characters.has(character.get_instance_id()):
		return
	
	_moving_characters.erase(character.get_instance_id())
	character.idle()
	character.move_ended.emit()


func _follow_player(
	character: PopochiuCharacter,
	start_position: Vector2,
	end_position: Vector2,
	follower: PopochiuCharacter
):
	var follower_end_position
	if end_position.x > follower.position.x:
		follower_end_position = end_position - follower.follow_player_offset
	else:
		follower_end_position = end_position + follower.follow_player_offset
	follower.walk_to(follower_end_position)


#endregion
