@tool
@icon('res://addons/popochiu/icons/walkable_area.png')
class_name PopochiuWalkableArea
extends Node2D
## The areas where characters can move.
##
## The area is defined by a [NavigationRegion2D].

## The identifier of the object used in scripts.
@export var script_name := ''
## Can be used to show the name of the area to players.
@export var description := ''
## Whether the area is or not enabled.
@export var enabled := true: set = _set_enabled
## Stores the outlines to assign to the [b]NavigationRegion2D/NavigationPolygon[/b] child during
## runtime. This is used by [PopochiuRoom] to store the info in its [code].tscn[/code].
@export var interaction_polygon := []
## Stores the position to assign to the [b]NavigationRegion2D/NavigationPolygon[/b] child during
## runtime. This is used by [PopochiuRoom] to store the info in its [code].tscn[/code].
@export var interaction_polygon_position := Vector2.ZERO
# TODO: If walkable is false, characters should not be able to walk through this.
#@export var walkable := true
# TODO: Make the value of the tint property to modify the modulate color of the polygon (or the
# 		modulate of the node itself).
#@export var tint := Color.WHITE
# TODO: Make the scale of the character change depending checked where it is placed in
# 		this walkable area.
#@export var scale_top := 1.0
#@export var scale_bottom := 1.0

## Property used by [PopochiuRoom]s to activate the map of this area in the [NavigationServer2D].
var map_rid: RID
## Used to assign a map in the [NavigationServer2D] to the region RID of the [b]$Perimeter[/b]
## child.
var region_rid: RID

## Emitted when the enabled flag changes so the room can react (e.g. switch active map).
signal enabled_changed(value: bool)

# Reference to the perimeter NavigationRegion2D, saved for internal use
@onready var _perimeter = get_node_or_null("Perimeter")


#region Godot ######################################################################################
func _ready() -> void:
	add_to_group('walkable_areas')

	if not _perimeter:
		print("No perimeter found in the walkable area. Please add a NavigationRegion2D child named 'Perimeter'.")
		return

	region_rid = (_perimeter as NavigationRegion2D).get_region_rid()

	# Editor setup...
	if Engine.is_editor_hint():
		# Ignore assigning the polygon when editing it in the .tscn file of the object directly
		if not get_parent() is Node2D:
			return

		# Add interaction polygon to the proper group
		_perimeter.add_to_group(
			PopochiuEditorHelper.POPOCHIU_OBJECT_POLYGON_GROUP
		)

		# Get the reference to the navigation polygon
		if interaction_polygon.is_empty():
			_save_navigation_polygon()
		else:
			_load_navigation_polygon()
			_bake_navigation()

		# If we are in the editor, we're done
		return

	# Runtime: create navigation setup
	map_rid = NavigationServer2D.map_create()
	# Ensure polygon and map use the same cell_size to avoid errors.
	NavigationServer2D.map_set_cell_size(
		map_rid,
		_perimeter.navigation_polygon.cell_size if _perimeter.navigation_polygon else 1.0
	)

	# Assign the region to the server map for this region.
	NavigationServer2D.region_set_map(region_rid, map_rid)

	# We don't activate the area here. Delegating this to the room
	# will avoid errors for non-ready areas in the server.

	# Load and bake navigation.
	_load_navigation_polygon()
	_bake_navigation()
	
	# Now sync the enabled state of this walkable area
	# that might have been set during scene loading.
	_sync_enabled_state_to_navigation_server()


func _notification(event: int) -> void:
	if event == NOTIFICATION_EDITOR_PRE_SAVE:
		_save_navigation_polygon()
		# Saving the scene is necessary to make the changes permanent.
		# If you remove this the character won't be able to walk in the area.
		PopochiuEditorHelper.pack_scene(self)


func _exit_tree():
	if Engine.is_editor_hint(): return
	
	# Deactivate and free our dedicated map to avoid leaking and to not affect other rooms.
	if map_rid.is_valid():
		NavigationServer2D.map_set_active(map_rid, false)
		NavigationServer2D.free_rid(map_rid)


#endregion

#region Private #####################################################################################
# Maps the outlines in [param perimeter] to the [member interaction_polygon] property and also
# stores its position in [member interaction_polygon_position].
func _save_navigation_polygon() -> void:
	# Take the reference to the navigation polygon
	var navpoly: NavigationPolygon = _perimeter.navigation_polygon
	if not navpoly or not is_instance_valid(navpoly):
		return
	
	interaction_polygon.clear()
	# Save all the NavigationPolygon outlines in the local variable
	for idx in range(0, navpoly.get_outline_count()):
		interaction_polygon.append(navpoly.get_outline(idx))
	# Save the NavigationRegion2D position
	interaction_polygon_position = _perimeter.position


# Populates the Walkable Area's navigation polygon
# with all the outlines of the saved polygon and bakes it back.
func _load_navigation_polygon() -> void:
	# Take the reference to the navigation polygon
	if not _perimeter.navigation_polygon:
		return

	# Create a fresh navigation polygon
	var navpoly = NavigationPolygon.new()
	navpoly.agent_radius = 0.0
	
	# Add the original outlines
	for outline in interaction_polygon:
		navpoly.add_outline(outline)
	
	# Assign the polygon to the perimeter first - this establishes the relationship
	_perimeter.navigation_polygon = navpoly

	# Restore the NavigationRegion2D position
	_perimeter.position = interaction_polygon_position


func _bake_navigation(source_geometry: NavigationMeshSourceGeometryData2D = null) -> void:
	# This is a convenience method to bake the navigation polygon
	if not _perimeter or not _perimeter is NavigationRegion2D:
		return
	
	# If no source geometry is specified, use an empty one.
	if not source_geometry:
		source_geometry = NavigationMeshSourceGeometryData2D.new()
	
	# Now use the perimeter's navigation polygon for baking
	NavigationServer2D.bake_from_source_geometry_data(_perimeter.navigation_polygon, source_geometry)

	# Guard against editor mode or invalid map RID
	# This ensures we don't try to update the navigation server in the editor or if the map
	# is not valid (e.g. when the scene is not running).
	if Engine.is_editor_hint() or not map_rid.is_valid():
		return

	# Make sure the region is up to date and linked to the map
	NavigationServer2D.region_set_navigation_polygon(region_rid, _perimeter.navigation_polygon)
	# Force navigation update using the existing map relationship
	if NavigationServer2D.map_is_active(map_rid):
		NavigationServer2D.map_force_update(map_rid)


#region Public ####################################################################################
## Collects all the [NavigationObstacle2D]s in the scene and returns them.

## Sets up navigation obstacles using projected obstructions.
## This is the preferred method for carving out areas in a NavigationPolygon.
func setup_prop_obstacles(obstacles: Array[NavigationObstacle2D]) -> void:
	if not _perimeter or not _perimeter is NavigationRegion2D:
		return

	_load_navigation_polygon()

	# Create source geometry data for baking
	var source_geometry = NavigationMeshSourceGeometryData2D.new()

	# Now add each obstacle as a projected obstruction
	for obstacle in obstacles:
		if not obstacle or obstacle.vertices.size() < 3:
			continue
			
		var obstacle_parent = obstacle.get_parent()
		if not obstacle_parent or not obstacle_parent.visible:
			continue
		
		# Convert obstacle vertices to global space, then to perimeter's local space
		var local_vertices = PackedVector2Array()
		for vertex in obstacle.vertices:
			# First convert to global space
			var global_pos = obstacle_parent.to_global(vertex)
			# Adjust the global position to account for the baseline because
			# the engine is currently using y-sorting and not z-index.
			global_pos.y -= obstacle_parent.baseline * scale.y
			# Then convert to perimeter's local space
			local_vertices.append(_perimeter.to_local(global_pos))

		# Add as projected obstruction (true means carving)
		source_geometry.add_projected_obstruction(local_vertices, true)
	
	_bake_navigation(source_geometry)

	# Wait a frame to ensure navigation is properly updated
	await get_tree().process_frame


#endregion

#region SetGet #####################################################################################
func _set_enabled(value: bool) -> void:
	# Always store the value first
	enabled = value
	
	# Editor: allow changing and saving the property, but never touch the NavigationServer.
	if Engine.is_editor_hint():
		emit_signal("enabled_changed", enabled)
		notify_property_list_changed()
		return

	# Runtime: if not ready yet, defer the NavigationServer update to _ready().
	# This handles the case where the exported property is set during scene loading.
	if not is_inside_tree() or not _perimeter or not region_rid.is_valid() or not map_rid.is_valid():
		# Don't emit signal yet - _ready() will handle the actual NavigationServer sync
		notify_property_list_changed()
		return

	# Runtime and ready: apply to NavigationServer immediately
	_sync_enabled_state_to_navigation_server()
	emit_signal("enabled_changed", enabled)
	notify_property_list_changed()


# Synchronizes the enabled property with the NavigationServer
# Why: separates the property logic from NavigationServer updates for cleaner flow
func _sync_enabled_state_to_navigation_server() -> void:
	if not _perimeter or not region_rid.is_valid() or not map_rid.is_valid():
		return
		
	_perimeter.enabled = enabled
	NavigationServer2D.region_set_enabled(region_rid, enabled)
	if NavigationServer2D.map_is_active(map_rid):
		NavigationServer2D.map_force_update(map_rid)
#endregion
