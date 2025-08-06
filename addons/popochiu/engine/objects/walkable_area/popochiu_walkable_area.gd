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
@export var enabled := true : set = _set_enabled
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
# Add these properties to store RIDs
var _obstacle_rids = []

#region Godot ######################################################################################
func _ready() -> void:
	add_to_group('walkable_areas')

	if Engine.is_editor_hint():
		# Ignore assigning the polygon when:
		if (
			get_node_or_null("Perimeter") == null # there is no NavigationArea2D node
			or not get_parent() is Node2D # editing it in the .tscn file of the object directly
		):
			return

		# Add interaction polygon to the proper group
		$Perimeter.add_to_group(
			PopochiuEditorHelper.POPOCHIU_OBJECT_POLYGON_GROUP
		)

		# Take the reference to the navigation polygon
		var navpoly: NavigationPolygon = $Perimeter.navigation_polygon
		if interaction_polygon.is_empty():
			# Save all the NavigationPolygon outlines in the local variable
			for idx in range(0, navpoly.get_outline_count()):
				interaction_polygon.append(navpoly.get_outline(idx))
			# Save the NavigationRegion2D position
			interaction_polygon_position = $Perimeter.position
		else:
			clear_and_bake(navpoly)

		# If we are in the editor, we're done
		return

	# When the game is running...
	# Update the node's polygon when:
	if (
		get_node_or_null("Perimeter") # there is an Perimeter node
	):
		# Take the reference to the navigation polygon
		var navpoly: NavigationPolygon = $Perimeter.navigation_polygon
		clear_and_bake(navpoly)

	# Map the necessary resources
	map_rid = NavigationServer2D.get_maps()[0]
	region_rid = ($Perimeter as NavigationRegion2D).get_region_rid()
	NavigationServer2D.region_set_map(region_rid, map_rid)


func _notification(event: int) -> void:
	if event == NOTIFICATION_EDITOR_PRE_SAVE:
		map_navigation_polygon($Perimeter)
		# Saving the scene is necessary to make the changes permanent.
		# If you remove this the character won't be able to walk in the area.
		PopochiuEditorHelper.pack_scene(self)


func _exit_tree():
	if Engine.is_editor_hint(): return
	
	NavigationServer2D.map_set_active(map_rid, false)


#endregion

#region Public #####################################################################################
## Maps the outlines in [param perimeter] to the [member interaction_polygon] property and also
## stores its position in [member interaction_polygon_position].
func map_navigation_polygon(perimeter: NavigationRegion2D) -> void:
	# Take the reference to the navigation polygon
	var navpoly: NavigationPolygon = perimeter.navigation_polygon
	
	if not navpoly or not is_instance_valid(navpoly):
		return
	
	interaction_polygon.clear()
	# Save all the NavigationPolygon outlines in the local variable
	for idx in range(0, navpoly.get_outline_count()):
		interaction_polygon.append(navpoly.get_outline(idx))
	# Save the NavigationRegion2D position
	interaction_polygon_position = perimeter.position


## Populates [param navpoly] with all the outlines and bakes it back.
func clear_and_bake(navpoly: NavigationPolygon) -> void:
	if not navpoly:
		return
	
	navpoly.clear_outlines()
	for outline in interaction_polygon:
		navpoly.add_outline(outline)
	NavigationServer2D.bake_from_source_geometry_data(
		navpoly, NavigationMeshSourceGeometryData2D.new()
	)

	# Restore the NavigationRegion2D position
	$Perimeter.position = interaction_polygon_position




## Clears all prop-generated navigation obstacles and restores the original walkable area state.
func clear_prop_obstacles() -> void:
	var perimeter = get_node_or_null("Perimeter")
	if not perimeter or not perimeter is NavigationRegion2D:
		return
		
	print("Clearing navigation obstacles for area: %s" % name)
	
	# Create a fresh navigation polygon
	var navpoly = NavigationPolygon.new()
	
	# Add the original outlines
	for outline in interaction_polygon:
		navpoly.add_outline(outline)
	
	# Bake without any obstacles
	NavigationServer2D.bake_from_source_geometry_data(
		navpoly, NavigationMeshSourceGeometryData2D.new()
	)
	
	# Assign the polygon to the region
	perimeter.navigation_polygon = navpoly
	
	# Make sure the region is up to date
	NavigationServer2D.region_set_map(perimeter.get_region_rid(), map_rid)
	NavigationServer2D.region_set_navigation_polygon(perimeter.get_region_rid(), navpoly)
	
	# Restore position
	perimeter.position = interaction_polygon_position
	
	# Free any obstacle RIDs we've created
	for obstacle_rid in _obstacle_rids:
		if obstacle_rid.is_valid():
			NavigationServer2D.free_rid(obstacle_rid)
	
	_obstacle_rids.clear()
	
	# Force navigation update
	NavigationServer2D.map_force_update(map_rid)
	
	print("Navigation mesh restored to original state for area: %s" % name)


## Sets up navigation obstacles using projected obstructions.
## This is the preferred method for carving out areas in a NavigationPolygon.
func setup_prop_obstacles(obstacles: Array[NavigationObstacle2D]) -> void:
	var perimeter = get_node_or_null("Perimeter")
	if not perimeter or not perimeter is NavigationRegion2D:
		return
		
	# Clear existing obstacles first
	clear_prop_obstacles()
	
	print("Setting up %d obstacles for walkable area %s" % [obstacles.size(), name])
	
	# Create a NEW navigation polygon - important for ownership reasons
	var navpoly = NavigationPolygon.new()
	
	# Add the original outlines to the new navigation polygon
	for outline in interaction_polygon:
		navpoly.add_outline(outline)
		
	# Create source geometry data for baking
	var source_geometry = NavigationMeshSourceGeometryData2D.new()
	
	# Add each obstacle as a projected obstruction BEFORE parsing
	var any_obstacles_added = false
	for obstacle in obstacles:
		if not obstacle or obstacle.vertices.size() < 3:
			continue
			
		var obstacle_parent = obstacle.get_parent()
		if not obstacle_parent:
			continue
		
		# Convert obstacle vertices to global space, then to perimeter's local space
		var local_vertices = PackedVector2Array()
		for vertex in obstacle.vertices:
			# First convert to global space
			var global_pos = obstacle_parent.to_global(vertex)
			# Then convert to perimeter's local space
			local_vertices.append(perimeter.to_local(global_pos))
		
		# Add as projected obstruction (true means carving)
		source_geometry.add_projected_obstruction(local_vertices, true)
		any_obstacles_added = true
		print("Added projected obstruction with %d vertices at positions: %s" % [local_vertices.size(), local_vertices])
	
	# Only continue if we actually added obstacles
	if not any_obstacles_added:
		print("No valid obstacles to add")
		return
		
	# Parse source geometry (which now includes obstacle projections)
	NavigationServer2D.bake_from_source_geometry_data(navpoly, source_geometry)
	
	# Assign the new polygon to the region
	perimeter.navigation_polygon = navpoly
	
	# Get the region_rid
	region_rid = perimeter.get_region_rid()
	
	# Make sure the region is up to date and linked to the map
	NavigationServer2D.region_set_map(region_rid, map_rid)
	NavigationServer2D.region_set_navigation_polygon(region_rid, navpoly)
	
	# Force navigation update
	NavigationServer2D.map_force_update(map_rid)
	
	# Wait a frame to ensure navigation is properly updated
	await get_tree().process_frame
	
	print("Navigation mesh rebaked with obstacles for area: %s" % name)
	
	return


#endregion

#region SetGet #####################################################################################
func _set_enabled(value: bool) -> void:
	enabled = value
	notify_property_list_changed()


#endregion

#region Private ####################################################################################
#endregion
