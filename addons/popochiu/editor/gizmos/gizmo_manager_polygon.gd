@tool
class_name GizmoManagerPolygon
extends RefCounted
# Manages polygon gizmos for the currently edited Popochiu object.
# Aggregates multiple polygon child nodes into a unified editing experience,
# supporting interaction polygons, obstacle polygons, and walkable area perimeters.

# State
var _target_node: Node2D
var _undo: EditorUndoRedoManager
var _gizmos: Array[GizmoPolygon2D] = []
var _grabbed_gizmo: GizmoPolygon2D
var _grabbed_snapshot: PackedVector2Array
# Visibility per category
var _visibility: Dictionary = {
	GizmoPolygon2D.PolygonCategory.INTERACTION: false,
	GizmoPolygon2D.PolygonCategory.OBSTACLE: false,
	GizmoPolygon2D.PolygonCategory.WALKABLE_AREA: false,
}
# Appearance settings (read from editor config)
var _colors: Dictionary = {}
var _fill_alpha: float = 0.15
var _vertex_handler_size: float = 6.0


#region Godot ######################################################################################
func _init(undo_manager: EditorUndoRedoManager) -> void:
	_undo = undo_manager


#endregion

#region Private ####################################################################################
# Scan a node for polygon children and create gizmos for them
func _scan_polygons(node: Node2D) -> void:
	if node == null or not is_instance_valid(node):
		return

	# Interaction polygons: CollisionPolygon2D children in the polygon group.
	# The false, false arguments restrict the search to direct children only
	# and do not require nodes to be owned by the scene root.
	for child in node.find_children("*", "CollisionPolygon2D", false, false):
		if not child.is_in_group(PopochiuEditorHelper.POPOCHIU_OBJECT_POLYGON_GROUP):
			continue
		var gizmo := GizmoPolygon2D.new(child, GizmoPolygon2D.PolygonCategory.INTERACTION)
		_set_gizmo_theme(gizmo)
		_gizmos.append(gizmo)

	# Walkable area perimeters: NavigationRegion2D children in the polygon group.
	# One gizmo is created per outline stored in the NavigationPolygon resource.
	for child in node.find_children("*", "NavigationRegion2D", false, false):
		if not child.is_in_group(PopochiuEditorHelper.POPOCHIU_OBJECT_POLYGON_GROUP):
			continue
		var nav_poly: NavigationPolygon = child.navigation_polygon
		if not nav_poly:
			continue
		for i in range(nav_poly.get_outline_count()):
			var gizmo := GizmoPolygon2D.new(
				child, GizmoPolygon2D.PolygonCategory.WALKABLE_AREA, i
			)
			_set_gizmo_theme(gizmo)
			_gizmos.append(gizmo)

	# Obstacle polygons: any NavigationObstacle2D direct child.
	# No group check needed — obstacle nodes are never shared with other categories.
	for child in node.find_children("*", "NavigationObstacle2D", false, false):
		var gizmo := GizmoPolygon2D.new(child, GizmoPolygon2D.PolygonCategory.OBSTACLE)
		_set_gizmo_theme(gizmo)
		_gizmos.append(gizmo)


# Apply appearance settings to a gizmo based on its category
func _set_gizmo_theme(gizmo: GizmoPolygon2D) -> void:
	var cat := gizmo.category
	gizmo.visible = _visibility.get(cat, false)

	match cat:
		GizmoPolygon2D.PolygonCategory.INTERACTION:
			gizmo.outline_color = _colors.get(
				"interaction", Color.YELLOW
			)
		GizmoPolygon2D.PolygonCategory.OBSTACLE:
			gizmo.outline_color = _colors.get(
				"obstacle", Color.VIOLET
			)
		GizmoPolygon2D.PolygonCategory.WALKABLE_AREA:
			gizmo.outline_color = _colors.get(
				"walkable_area", Color.GREEN
			)

	gizmo.fill_color = Color(gizmo.outline_color, _fill_alpha)
	gizmo.vertex_color = Color.WHITE
	gizmo.vertex_size = _vertex_handler_size


# After editing a walkable area polygon, rebake the navigation mesh.
# The bake is deferred so it does not collide with a bake that is
# already in progress (Godot raises an error in that case).
func _rebake_if_walkable_area(gizmo: GizmoPolygon2D) -> void:
	if gizmo.category != GizmoPolygon2D.PolygonCategory.WALKABLE_AREA:
		return
	var source := gizmo.get_source_node()
	if source is NavigationRegion2D and source.navigation_polygon:
		if source.is_baking():
			# Wait for the current bake to finish, then rebake once
			if not source.bake_finished.is_connected(_deferred_rebake.bind(source)):
				source.bake_finished.connect(
					_deferred_rebake.bind(source), CONNECT_ONE_SHOT
				)
		else:
			source.bake_navigation_polygon()


# Called after a running bake finishes so we can safely rebake with the
# latest outline data.
func _deferred_rebake(source: NavigationRegion2D) -> void:
	if is_instance_valid(source) and source.navigation_polygon:
		source.bake_navigation_polygon()


#endregion

#region Public #####################################################################################
# Initialize or refresh appearance settings from editor config
func initialize_gizmos() -> void:
	_colors["interaction"] = PopochiuEditorConfig.get_editor_setting(
		PopochiuEditorConfig.GIZMOS_POLY_INTERACTION_COLOR
	)
	_colors["obstacle"] = PopochiuEditorConfig.get_editor_setting(
		PopochiuEditorConfig.GIZMOS_POLY_OBSTACLE_COLOR
	)
	_colors["walkable_area"] = PopochiuEditorConfig.get_editor_setting(
		PopochiuEditorConfig.GIZMOS_POLY_WALKABLE_AREA_COLOR
	)
	_fill_alpha = PopochiuEditorConfig.get_editor_setting(
		PopochiuEditorConfig.GIZMOS_POLY_FILL_ALPHA
	)
	_vertex_handler_size = PopochiuEditorConfig.get_editor_setting(
		PopochiuEditorConfig.GIZMOS_POLY_VERTEX_HANDLER_SIZE
	)

	# Re-apply to existing gizmos
	for gizmo in _gizmos:
		_set_gizmo_theme(gizmo)


# Handle a newly selected object. Build gizmos for its polygon children.
func handle_object(object: Object, edited_root: Node) -> bool:
	# If the object is a WalkableArea, handle it directly
	if object is PopochiuWalkableArea:
		_target_node = object
		_gizmos.clear()
		_grabbed_gizmo = null
		_scan_polygons(object)
		return _gizmos.size() > 0

	# If the object is a clickable (Prop, Hotspot, Character, Region), handle it
	if object is PopochiuClickable or object is PopochiuRegion:
		_target_node = object
		_gizmos.clear()
		_grabbed_gizmo = null
		_scan_polygons(object)
		return _gizmos.size() > 0

	# If we are in a room and the user just selected the room root or something else,
	# scan for walkable area polygons at the room level if visible
	if edited_root is PopochiuRoom:
		_target_node = null
		_gizmos.clear()
		_grabbed_gizmo = null
		# Scan all walkable areas in the room for their polygons
		var wa_container := edited_root.find_child("WalkableAreas")
		if wa_container:
			for child in wa_container.get_children():
				if child is PopochiuWalkableArea:
					_scan_polygons(child)
		return _gizmos.size() > 0

	reset()
	return false


# Draw all visible polygon gizmos
func draw_gizmos(viewport_control: Control) -> void:
	for gizmo in _gizmos:
		if gizmo.visible and gizmo.is_valid():
			gizmo.draw(viewport_control)


# Try to grab a vertex or insert a vertex on an edge. Returns true if handled.
func try_grab_gizmo(event: InputEventMouseButton) -> bool:
	if _gizmos.is_empty():
		return false

	var pos := event.position

	# First pass: check for vertex hits (highest priority)
	for gizmo in _gizmos:
		if not gizmo.visible or not gizmo.is_valid():
			continue
		var vertex_index := gizmo.hit_test_vertex(pos)
		if vertex_index >= 0:
			_grabbed_gizmo = gizmo
			_grabbed_snapshot = gizmo.get_polygon_snapshot()
			gizmo.grab_vertex(vertex_index, pos)
			_undo.create_action("Move polygon vertex")
			return true

	# Second pass: check for edge hits (insert new vertex)
	for gizmo in _gizmos:
		if not gizmo.visible or not gizmo.is_valid():
			continue
		var edge_index := gizmo.hit_test_edge(pos)
		if edge_index >= 0:
			_grabbed_gizmo = gizmo
			_grabbed_snapshot = gizmo.get_polygon_snapshot()
			var new_vertex_index := gizmo.insert_vertex_on_edge(edge_index, pos)
			if new_vertex_index >= 0:
				gizmo.grab_vertex(new_vertex_index, pos)
				_undo.create_action("Add polygon vertex")
				return true

	return false


# Release the currently grabbed vertex
func release_gizmo() -> bool:
	if not _grabbed_gizmo:
		return false

	_grabbed_gizmo.release_vertex()

	# Record the undo/redo with full polygon snapshots
	var source := _grabbed_gizmo.get_source_node()
	var after_snapshot := _grabbed_gizmo.get_polygon_snapshot()

	# Restore the "before" state for the undo property
	_grabbed_gizmo.restore_polygon_snapshot(_grabbed_snapshot)
	_add_undo_polygon_property(_grabbed_gizmo, _grabbed_snapshot)

	# Set the "after" state for the do property
	_grabbed_gizmo.restore_polygon_snapshot(after_snapshot)
	_add_do_polygon_property(_grabbed_gizmo, after_snapshot)

	_undo.commit_action()

	# Rebake navigation if this was a walkable area
	_rebake_if_walkable_area(_grabbed_gizmo)

	_grabbed_gizmo = null
	_grabbed_snapshot = PackedVector2Array()
	return true


# Drag the currently grabbed vertex
func drag_gizmo(event: InputEventMouseMotion) -> bool:
	if not _grabbed_gizmo:
		return false

	_grabbed_gizmo.drag_vertex_to(event.position)
	return true


# Cancel the current vertex drag
func cancel_dragging() -> bool:
	if not _grabbed_gizmo:
		return false

	_grabbed_gizmo.cancel_vertex()
	# Restore original polygon state
	_grabbed_gizmo.restore_polygon_snapshot(_grabbed_snapshot)

	_undo.commit_action()
	var source := _grabbed_gizmo.get_source_node()
	if is_instance_valid(source):
		_undo.get_history_undo_redo(
			_undo.get_object_history_id(source)
		).undo()

	_grabbed_gizmo = null
	_grabbed_snapshot = PackedVector2Array()
	return true


# Try to delete a vertex at the given position. Returns true if handled.
func try_delete_vertex(pos: Vector2) -> bool:
	for gizmo in _gizmos:
		if not gizmo.visible or not gizmo.is_valid():
			continue
		var vertex_index := gizmo.hit_test_vertex(pos)
		if vertex_index >= 0:
			var before := gizmo.get_polygon_snapshot()
			if gizmo.delete_vertex(vertex_index):
				var after := gizmo.get_polygon_snapshot()
				_undo.create_action("Delete polygon vertex")
				# Restore before for undo
				gizmo.restore_polygon_snapshot(before)
				_add_undo_polygon_property(gizmo, before)
				# Re-apply after for do
				gizmo.restore_polygon_snapshot(after)
				_add_do_polygon_property(gizmo, after)
				_undo.commit_action()
				_rebake_if_walkable_area(gizmo)
				return true
	return false


# Update hover state for all visible gizmos. Returns true if any changed.
func update_hover(pos: Vector2) -> bool:
	var changed := false
	for gizmo in _gizmos:
		if not gizmo.visible or not gizmo.is_valid():
			continue
		if gizmo.update_hover(pos):
			changed = true
	return changed


# Check if there is an active (grabbed) gizmo
func has_active_gizmo() -> bool:
	return _grabbed_gizmo != null


# Try to delete the currently hovered vertex (used when Delete key is pressed).
# Returns true if a vertex was deleted.
func try_delete_hovered_vertex() -> bool:
	for gizmo in _gizmos:
		if not gizmo.visible or not gizmo.is_valid():
			continue
		if gizmo._hovered_vertex_index >= 0:
			var before := gizmo.get_polygon_snapshot()
			if gizmo.delete_vertex(gizmo._hovered_vertex_index):
				var after := gizmo.get_polygon_snapshot()
				_undo.create_action("Delete polygon vertex")
				gizmo.restore_polygon_snapshot(before)
				_add_undo_polygon_property(gizmo, before)
				gizmo.restore_polygon_snapshot(after)
				_add_do_polygon_property(gizmo, after)
				_undo.commit_action()
				_rebake_if_walkable_area(gizmo)
				return true
	return false


# Set visibility for a polygon category
func set_category_visibility(category: GizmoPolygon2D.PolygonCategory, is_visible: bool) -> void:
	_visibility[category] = is_visible
	for gizmo in _gizmos:
		if gizmo.category == category:
			gizmo.visible = is_visible


# Clear all gizmos and reset state
func reset() -> void:
	_gizmos.clear()
	_target_node = null
	_grabbed_gizmo = null
	_grabbed_snapshot = PackedVector2Array()


#endregion

#region Undo/Redo Helpers ##########################################################################
# Add undo property for polygon data. Handles the different source node types.
func _add_undo_polygon_property(gizmo: GizmoPolygon2D, snapshot: PackedVector2Array) -> void:
	var source := gizmo.get_source_node()
	if source is CollisionPolygon2D:
		_undo.add_undo_property(source, "polygon", snapshot)
	elif source is NavigationObstacle2D:
		_undo.add_undo_property(source, "vertices", snapshot)
	elif source is NavigationRegion2D:
		# For NavigationRegion2D, we need to save/restore the full navigation polygon
		# since outlines are part of the NavigationPolygon resource
		if source.navigation_polygon:
			_undo.add_undo_method(gizmo, "restore_polygon_snapshot", snapshot)


# Add do property for polygon data. Handles the different source node types.
func _add_do_polygon_property(gizmo: GizmoPolygon2D, snapshot: PackedVector2Array) -> void:
	var source := gizmo.get_source_node()
	if source is CollisionPolygon2D:
		_undo.add_do_property(source, "polygon", snapshot)
	elif source is NavigationObstacle2D:
		_undo.add_do_property(source, "vertices", snapshot)
	elif source is NavigationRegion2D:
		if source.navigation_polygon:
			_undo.add_do_method(gizmo, "restore_polygon_snapshot", snapshot)


#endregion
