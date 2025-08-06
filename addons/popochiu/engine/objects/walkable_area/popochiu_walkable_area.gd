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

#region Godot ######################################################################################
func _ready() -> void:
	add_to_group('walkable_areas')

	if not $Perimeter:
		return

	# We are in the editor so let's address what's needed to edit the perimenter polygon
	if Engine.is_editor_hint():
		# Ignore assigning the polygon when editing it in the .tscn file of the object directly
		if get_parent() is Node2D:
			return

		# Add interaction polygon to the proper group
		$Perimeter.add_to_group(
			PopochiuEditorHelper.POPOCHIU_OBJECT_POLYGON_GROUP
		)

		# Get the reference to the navigation polygon
		var navpoly: NavigationPolygon = $Perimeter.navigation_polygon
		if interaction_polygon.is_empty():
			# Save all the NavigationPolygon outlines in the local variable
			for idx in range(0, navpoly.get_outline_count()):
				interaction_polygon.append(navpoly.get_outline(idx))
			# Save the NavigationRegion2D position
			interaction_polygon_position = $Perimeter.position
		else:
			_load_navigation_polygon(navpoly)
			_bake_navigation()

		# If we are in the editor, we're done
		return

	# When the game is running...
	# Bake the perimeter polygon in the navigation server
	# Take the reference to the navigation polygon
	var navpoly: NavigationPolygon = $Perimeter.navigation_polygon
	_load_navigation_polygon(navpoly)
	_bake_navigation()

	# Map the necessary resources
	map_rid = NavigationServer2D.get_maps()[0]
	region_rid = ($Perimeter as NavigationRegion2D).get_region_rid()
	NavigationServer2D.region_set_map(region_rid, map_rid)


func _notification(event: int) -> void:
	if event == NOTIFICATION_EDITOR_PRE_SAVE:
		_save_navigation_polygon($Perimeter)
		# Saving the scene is necessary to make the changes permanent.
		# If you remove this the character won't be able to walk in the area.
		PopochiuEditorHelper.pack_scene(self)


func _exit_tree():
	if Engine.is_editor_hint(): return
	
	NavigationServer2D.map_set_active(map_rid, false)


#endregion

#region Public #####################################################################################
# Maps the outlines in [param perimeter] to the [member interaction_polygon] property and also
# stores its position in [member interaction_polygon_position].
func _save_navigation_polygon(perimeter: NavigationRegion2D) -> void:
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


# Populates [param navpoly] with all the outlines and bakes it back.
func _load_navigation_polygon(navpoly: NavigationPolygon) -> void:
	if not navpoly:
		return
	
	navpoly.clear_outlines()
	for outline in interaction_polygon:
		navpoly.add_outline(outline)

	# Restore the NavigationRegion2D position
	$Perimeter.position = interaction_polygon_position


func _bake_navigation(source_geometry: NavigationMeshSourceGeometryData2D = null) -> void:
	# This is a convenience method to bake the navigation polygon
	if not $Perimeter or not $Perimeter is NavigationRegion2D:
		return
	
	var navpoly: NavigationPolygon = $Perimeter.navigation_polygon
	if not navpoly:
		return
	
	# If no source geometry is specified, use an empty one.
	if not source_geometry:
		source_geometry = NavigationMeshSourceGeometryData2D.new()
	
	# Now use the perimeter's navigation polygon for baking
	NavigationServer2D.bake_from_source_geometry_data(navpoly, source_geometry)
	# Make sure the region is up to date and linked to the map
	NavigationServer2D.region_set_navigation_polygon(region_rid, navpoly)
	# Force navigation update using the existing map relationship
	NavigationServer2D.map_force_update(map_rid)



## Clears all prop-generated navigation obstacles and restores the original walkable area state.
func clear_prop_obstacles() -> void:
	var perimeter = get_node_or_null("Perimeter")
	if not perimeter or not perimeter is NavigationRegion2D:
		return

	# Create a fresh navigation polygon
	var navpoly = NavigationPolygon.new()
	
	# Add the original outlines
	for outline in interaction_polygon:
		navpoly.add_outline(outline)
	
	# Assign the polygon to the perimeter first - this establishes the relationship
	perimeter.navigation_polygon = navpoly

	_bake_navigation()

	# Restore position
	perimeter.position = interaction_polygon_position


## Sets up navigation obstacles using projected obstructions.
## This is the preferred method for carving out areas in a NavigationPolygon.
func setup_prop_obstacles(obstacles: Array[NavigationObstacle2D]) -> void:
	var perimeter = get_node_or_null("Perimeter")
	if not perimeter or not perimeter is NavigationRegion2D:
		return

	_load_navigation_polygon(perimeter.navigation_polygon)

	# Create source geometry data for baking
	var source_geometry = NavigationMeshSourceGeometryData2D.new()

	# Add each obstacle as a projected obstruction BEFORE parsing
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
	
	_bake_navigation(source_geometry)

	# Wait a frame to ensure navigation is properly updated
	await get_tree().process_frame


#endregion

#region SetGet #####################################################################################
func _set_enabled(value: bool) -> void:
	enabled = value
	notify_property_list_changed()


#endregion

#region Private ####################################################################################
#endregion
