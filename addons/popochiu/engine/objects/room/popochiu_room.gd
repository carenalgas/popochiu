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
@export var hide_gui := false
@export_category("Room size")
## Defines the room's width. If this exceeds from the project's viewport width, this value is used
## to calculate the camera limits, ensuring it follows the player as they move within the room.
@export var width: int = 0
## Defines the room's height. If this exceeds from the project's viewport height, this value is used
## to calculate the camera limits, ensuring it follows the player as they move within the room.
@export var height: int = 0
## @deprecated
@export_category("Camera limits")
## @deprecated
## If this different from [constant INF], the value will define the left limit of the camera
## relative to the native game resolution. I.e. if your native game resolution is 320x180, and the
## background (size) of the room is 448x180, the left limit of the camera should be -64 (this is the
## difference between 320 and 448).
## [br][br][i]Set this on rooms that are bigger than the native game resolution so the camera will
## follow the character.[/i]
@export var limit_left := INF
## @deprecated
## If this different from [constant INF], the value will define the right limit of the camera
## relative to the native game resolution. I.e. if your native game resolution is 320x180, and the
## background (size) of the room is 448x180, the right limit of the camera should be 384 (320 + 64
## (this is the difference between 320 and 448)).
## [br][br][i]Set this on rooms that are bigger than the native game resolution so the camera will
## follow the character.[/i]
@export var limit_right := INF
## @deprecated
## If this different from [constant INF], the value will define the top limit of the camera
## relative to the native game resolution.
## [br][br][i]Set this on rooms that are bigger than the native game resolution so the camera will
## follow the character.[/i]
@export var limit_top := INF
## @deprecated
## If this different from [constant INF], the value will define the bottom limit of the camera
## relative to the native game resolution.
## [br][br][i]Set this on rooms that are bigger than the native game resolution so the camera will
## follow the character.[/i]
@export var limit_bottom := INF


## Whether this is the room in which players are. When [code]true[/code], the room starts processing
## unhandled inputs.
var is_current := false: set = set_is_current

var _nav_path: PopochiuWalkableArea = null
# Stores the children defined in the Editor's Scene tree for each character inside $Characters to
# add them to the corresponding PopochiuCharacter instance when the room is loaded in runtime.
var _characters_children := {}


#region Godot ######################################################################################
func _enter_tree() -> void:
	if Engine.is_editor_hint():
		y_sort_enabled = false
		$Props.y_sort_enabled = false
		$Characters.y_sort_enabled = false

		if width == 0:
			width = ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH)
		if height == 0:
			height = ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)

		return
	else:
		y_sort_enabled = true
		$Props.y_sort_enabled = true
		$Characters.y_sort_enabled = true


func _ready():
	if Engine.is_editor_hint(): return

	# Bake obstacles in every and each walkable area, after all of them are initialized.
	_setup_navigation_obstacles.call_deferred()

	# Ensure exactly one area is active at startup. The first enabled area is activated.
	# Devs that want to control which area is active, should invoke set_active_walkable_area()
	# in _on_room_entered().
	_ensure_active_walkable_area.call_deferred()

	set_process_unhandled_input(false)

	# Connect to singletons signals
	PopochiuUtils.g.blocked.connect(_on_gui_blocked)
	PopochiuUtils.g.unblocked.connect(_on_gui_unblocked)

	# Connect to runtime enable/disable walkable areas signals.
	for wa: PopochiuWalkableArea in get_walkable_areas():
		if (
			wa
			and wa.has_signal("enabled_changed")
			and not wa.enabled_changed.is_connected(_on_walkable_area_enabled_changed)
		):
			# Bind the area instance so we know which one changed.
			wa.enabled_changed.connect(_on_walkable_area_enabled_changed.bind(wa))

	# Connect to props movement_ended signals to trigger navigation rebaking when they move
	_connect_object_changes_signals.call_deferred()

	# Connect to player changed signal to rebake navigation when player character changes
	if not PopochiuUtils.c.player_changed.is_connected(_on_player_changed):
		PopochiuUtils.c.player_changed.connect(_on_player_changed)

	PopochiuUtils.r.room_readied(self)

func _unhandled_input(event: InputEvent):
	if (
		not PopochiuUtils.get_click_or_touch_index(event) in [
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT
		]
		or (not event is InputEventScreenTouch and PopochiuUtils.e.hovered)
	):
		return

	# Fix #224 Item should be removed only if the click was done anywhere in the room when the
	# cursor is not hovering another object.
	if PopochiuUtils.i.active:
		# Wait so PopochiuClickable can handle the interaction.
		await get_tree().create_timer(0.1).timeout

		PopochiuUtils.i.set_active_item()
		return

	if has_player and is_instance_valid(PopochiuUtils.c.player) and PopochiuUtils.c.player.can_move:
		# Set this property to null in order to cancel any running interaction with a
		# PopochiuClickable (check PopochiuCharacter.walk_to_clicked(...)).
		PopochiuUtils.e.clicked = null

		if PopochiuUtils.c.player.is_moving:
			PopochiuUtils.c.player.movement_ended.emit()

		PopochiuUtils.c.player.walk(get_local_mouse_position())


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
	for c in $Characters.get_children():
		c.reset_buffered_position()

		for character_child: Node in c.get_children():
			if character_child.owner != c:
				character_child.queue_free()

		# Disconnect character signals before removing
		_disconnect_obstacle_obj_signals(c)

		$Characters.remove_child(c)

	_on_room_exited()


## Adds the instance (in memory) of [param chr] to the [b]$Characters[/b] node.
## It also adds to it any children of the character in the Editor's Scene tree. The [b]idle[/b]
## animation is triggered.
func add_character(chr: PopochiuCharacter) -> void:
	$Characters.add_child(chr)

	# Fix #191 by checking if the character had children defined in the Room's Scene (Editor).
	if _characters_children.has(chr.script_name):
		# Add child nodes (defined in the Scene tree of the room) to the instance of the character.
		for child: Node in _characters_children[chr.script_name]:
			chr.add_child(child)

	update_characters_position(chr)

	# Connect character signals for navigation updates
	_connect_obstacle_obj_signals(chr)

	# Update navigation obstacles since a new character was added
	update_navigation_obstacles()

	chr.idle()


## Removes [param chr] from the [b]$Characters[/b] node without destroying it.
## [br][br]
## [b]Note:[/b] This removal persists across room transitions. A removed character will not be restored
## when returning to the room. If you want the character to reappear on subsequent visits, either
## use [method add_character] in the room's [method PopochiuRoom._on_room_entered] callback
## or hide the character instead ([code]character.disable()[/code]).
func remove_character(chr: PopochiuCharacter) -> void:
	# Only remove if the character is actually a child of this room's $Characters node
	if chr.get_parent() != $Characters:
		PopochiuUtils.print_warning(
			"Attempted to remove character '%s' from room '%s', but it's not a child of this room." %
			[chr.script_name, script_name]
		)
		return
	
	# Disconnect character signals before removing
	_disconnect_obstacle_obj_signals(chr)

	$Characters.remove_child(chr)

	# Update navigation obstacles since a character was removed
	update_navigation_obstacles()


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
	if width > 0 and width > PopochiuUtils.e.width:
		var h_diff: int = (PopochiuUtils.e.width - width) / 2
		PopochiuUtils.e.camera.limit_left = h_diff
		PopochiuUtils.e.camera.limit_right = PopochiuUtils.e.width - h_diff
	if height > 0 and height > PopochiuUtils.e.height:
		var v_diff: int = (PopochiuUtils.e.height - height) / 2
		PopochiuUtils.e.camera.limit_top = - v_diff
		PopochiuUtils.e.camera.limit_bottom = PopochiuUtils.e.height - v_diff


## Remove all children from the [b]$Characters[/b] node, storing the children of each node to later
## assign them to the corresponding [PopochiuCharacter] when the room is loaded.
func clean_characters() -> void:
	for c in $Characters.get_children():
		if not c is PopochiuCharacter: continue

		_characters_children[c.script_name] = []

		for character_child: Node in c.get_children():
			if not character_child.owner == self: continue

			c.remove_child(character_child)
			_characters_children[c.script_name].append(character_child)

		c.queue_free()


## Updates the position of [param character] in the room, and then updates its scale.
func update_characters_position(character: PopochiuCharacter):
	character.update_position()
	character.update_scale()


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
	var next: PopochiuWalkableArea = $WalkableAreas.get_node_or_null(walkable_area_name)
	if next == null:
		PopochiuUtils.print_error("No walkable area named %s is available for activation" % walkable_area_name)
		return
	if not next.enabled:
		PopochiuUtils.print_error("Walkable area %s is disabled and cannot be activated" % walkable_area_name)
		return

	# Important: wait for the next physics frame before trying to activate the map.
	# This gives the NavigationServer time to fully register the map.
	#await get_tree().physics_frame

	# Deactivate previous maps to ensure only one set is active at any time.
	if _nav_path and _nav_path.map_rid.is_valid():
		NavigationServer2D.map_set_active(_nav_path.map_rid, false)
	if _nav_path and _nav_path.map_rid_no_obstacles.is_valid():
		NavigationServer2D.map_set_active(_nav_path.map_rid_no_obstacles, false)

	# Set the new active area.
	_nav_path = next

	# Activate the newly selected area's maps
	NavigationServer2D.map_set_active(_nav_path.map_rid, true)
	NavigationServer2D.map_set_active(_nav_path.map_rid_no_obstacles, true)

	# Important: wait for the next physics frame before trying to activate the map.
	# This gives the NavigationServer time to fully register the map.
	await get_tree().physics_frame

	if _nav_path.map_rid.is_valid() and NavigationServer2D.map_is_active(_nav_path.map_rid):
		NavigationServer2D.map_force_update(_nav_path.map_rid)


## Returns the navigation path from start to end position using the active walkable area.
## Returns empty array if no walkable area is set.
func get_navigation_path(
	start_position: Vector2, end_position: Vector2,
	ignore_walkable_areas: bool = false,
	ignore_obstacles: bool = false
) -> PackedVector2Array:
	if ignore_walkable_areas:
		# Direct path for characters that ignore walkable areas.
		return PackedVector2Array([start_position, end_position])

	if not _nav_path:
		return PackedVector2Array()

	# Use the map without obstacles if requested
	var map_to_use = _nav_path.map_rid_no_obstacles if ignore_obstacles else _nav_path.map_rid

	# Delegate pathfinding to the appropriate map
	return NavigationServer2D.map_get_path(map_to_use, start_position, end_position, true)


## Manually triggers navigation obstacle rebaking for all walkable areas.
## Useful when props are moved or added/removed at runtime, or when you need to force
## a navigation mesh update. The rebaking happens in the next frame to avoid performance issues.
func update_navigation_obstacles() -> void:
	_setup_navigation_obstacles.call_deferred()


#endregion


#region SetGet #####################################################################################
func set_is_current(value: bool) -> void:
	is_current = value
	set_process_unhandled_input(is_current)

#endregion
 

#region Private ####################################################################################
func _on_gui_blocked() -> void:
	set_process_unhandled_input(false)


func _on_gui_unblocked() -> void:
	set_process_unhandled_input(true)


# Sets up navigation obstacles for all walkable areas based on props in the room.
# This method collects all valid navigation obstacles from props and distributes them
# to each walkable area, then triggers a rebake of the navigation meshes.
func _setup_navigation_obstacles() -> void:
	# #433 Guard check: this method is called deferred, so the room may have been removed from
	# the tree by the time it runs (e.g., when characters are removed during room transitions).
	if not is_inside_tree():
		return
	
	var walkable_areas = get_walkable_areas()
	if walkable_areas.is_empty():
		return

	# Collect all valid navigation obstacles from props and characters.
	var obstacles = _collect_all_obstacles()

	# Apply obstacles to each enabled walkable area.
	for walkable_area in walkable_areas:
		if walkable_area and walkable_area is PopochiuWalkableArea and walkable_area.enabled:
			await walkable_area.setup_obstacles(obstacles)

	# Important: do not activate/switch areas here. This function only bakes obstacles.
	await get_tree().physics_frame

# Ensures one walkable area is active when the room gets readied.
# Keeps the current active area if it is still enabled, otherwise it picks the first
# enabled one (scene-tree order).
# Delegates most of the logic to set_active_walkable_area().
func _ensure_active_walkable_area() -> void:
	# If we already have a valid, enabled active area (i.e. from a savegame), keep it.
	if _nav_path and _nav_path.enabled:
		return

	# Otherwise, search for all the enabled areas in the room.
	var enabled_walkable_areas = get_walkable_areas().filter(func(wa): return wa.enabled)
	if enabled_walkable_areas.is_empty():
		# No enabled areas: deactivate any previously active map and clear.
		if _nav_path and _nav_path.map_rid.is_valid():
			NavigationServer2D.map_set_active(_nav_path.map_rid, false)
		_nav_path = null
		# Fix #459: Don't try to activate walkable areas if none are enabled.
		return

	# Finally, take the first enabled walkable area and activate it.
	set_active_walkable_area(enabled_walkable_areas[0].name)


# Collects all valid navigation obstacles from props and characters in the room.
# Returns an array of NavigationObstacle2D nodes that have valid polygons.
# Excludes temporary editor-placed characters and the player character.
func _collect_all_obstacles() -> Array[NavigationObstacle2D]:
	var obstacles: Array[NavigationObstacle2D] = []

	# Collect obstacles from props
	for prop in get_props():
		if not prop or not prop is PopochiuProp:
			continue

		var obstacle: NavigationObstacle2D = prop.get_navigation_obstacle()
		if obstacle:
			# Adjust the global position to account for the baseline because
			# props are currently using y-sorting and not z-index.
			obstacle.position.y -= prop.baseline * scale.y
			obstacles.append(obstacle)

	# Collect obstacles from characters (excluding temporary editor instances and player character)
	for character in get_characters():
		if not character or not character is PopochiuCharacter:
			continue

		# Skip temporary editor-placed characters
		if character.has_meta("EDITOR_TMP_COPY_OF"):
			continue

		# Skip the player character to avoid them blocking their own movement
		# Use PopochiuCharactersHelper to identify the player character reliably
		if PopochiuCharactersHelper.is_player_character(character):
			continue

		var obstacle: NavigationObstacle2D = character.get_navigation_obstacle()
		if obstacle:
			obstacles.append(obstacle)

	return obstacles


# React when a walkable area's enabled flag changes at runtime.
func _on_walkable_area_enabled_changed(enabled: bool, area: PopochiuWalkableArea) -> void:
	# If the active area was disabled, switch to another enabled one (if any).
	if area == _nav_path and not enabled:
		if _nav_path.map_rid.is_valid():
			NavigationServer2D.map_set_active(_nav_path.map_rid, false)
		var fallback := get_walkable_areas().filter(func(wa): return wa.enabled)
		if not fallback.is_empty():
			set_active_walkable_area(fallback[0].name)
		else:
			_nav_path = null
	# If nothing is active and an area just became enabled, activate it.
	elif _nav_path == null and enabled:
		set_active_walkable_area(area.name)


# Connects to all props' and characters' movement_ended and visibility_changed signals to trigger navigation rebaking.
func _connect_object_changes_signals() -> void:
	# Connect to props signals
	for prop: PopochiuProp in get_props():
		_connect_obstacle_obj_signals(prop)

	# Connect to characters signals
	for character: PopochiuCharacter in get_characters():
		if character.has_meta('EDITOR_TMP_COPY_OF'):
			continue
		_connect_obstacle_obj_signals(character)


# Called when an obstacle changes state because of movement or visibility change.
# Triggers navigation obstacle rebaking since the prop's collision shape has moved.
func _on_obstacle_obj_state_changed(obj: PopochiuClickable) -> void:
	# Only rebake navigation if the prop has navigation obstacles
	if obj.get_node_or_null("ObstaclePolygon"):
		_setup_navigation_obstacles.call_deferred()


# Called when the player character changes.
# Triggers navigation obstacle rebaking since player character obstacles need to be updated.
func _on_player_changed(old_player: PopochiuCharacter, new_player: PopochiuCharacter) -> void:
	# Rebake navigation obstacles when player changes to handle character obstacles properly
	_setup_navigation_obstacles.call_deferred()


# Helper function to connect a single prop's signals for navigation updates.
func _connect_obstacle_obj_signals(obj: PopochiuClickable) -> void:
	if not obj:
		return

	if not obj is PopochiuProp and not obj is PopochiuCharacter:
		return

	# Connect to movement_started signal
	if (
		obj.has_signal("movement_started")
		and not obj.movement_started.is_connected(_on_obstacle_obj_state_changed)
	):
		obj.movement_started.connect(_on_obstacle_obj_state_changed.bind(obj))

	# Connect to movement_ended signal
	if (
		obj.has_signal("movement_ended")
		and not obj.movement_ended.is_connected(_on_obstacle_obj_state_changed)
	):
		obj.movement_ended.connect(_on_obstacle_obj_state_changed.bind(obj))

	# Connect to visibility_changed signal (built-in Node2D signal)
	if not obj.visibility_changed.is_connected(_on_obstacle_obj_state_changed):
		obj.visibility_changed.connect(_on_obstacle_obj_state_changed.bind(obj))

	# Connect to obstacle_state_changed signal
	if (
		obj.has_signal("obstacle_state_changed")
		and not obj.obstacle_state_changed.is_connected(_on_obstacle_obj_state_changed)
	):
		obj.obstacle_state_changed.connect(_on_obstacle_obj_state_changed.bind(obj))


# Helper function to disconnect a single character's signals.
func _disconnect_obstacle_obj_signals(obj: PopochiuClickable) -> void:
	if not obj:
		return

	if not obj is PopochiuProp and not obj is PopochiuCharacter:
		return

	# Disconnect movement_started signal
	if (
		obj.has_signal("movement_started")
		and obj.movement_started.is_connected(_on_obstacle_obj_state_changed)
	):
		obj.movement_started.disconnect(_on_obstacle_obj_state_changed)

	# Disconnect movement_ended signal
	if (
		obj.has_signal("movement_ended")
		and obj.movement_ended.is_connected(_on_obstacle_obj_state_changed)
	):
		obj.movement_ended.disconnect(_on_obstacle_obj_state_changed)

	# Disconnect visibility_changed signal
	if obj.visibility_changed.is_connected(_on_obstacle_obj_state_changed):
		obj.visibility_changed.disconnect(_on_obstacle_obj_state_changed)

	# Disconnect obstacle_state_changed signal
	if (
		obj.has_signal("obstacle_state_changed")
		and obj.obstacle_state_changed.is_connected(_on_obstacle_obj_state_changed)
	):
		obj.obstacle_state_changed.disconnect(_on_obstacle_obj_state_changed)


#endregion
