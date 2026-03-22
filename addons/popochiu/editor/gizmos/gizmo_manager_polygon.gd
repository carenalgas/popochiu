@tool
class_name GizmoManagerPolygon
extends RefCounted
# Manages polygon gizmos for the currently edited Popochiu object.
# Aggregates multiple polygon child nodes into a unified editing experience,
# supporting interaction polygons, obstacle polygons, and walkable area perimeters.

# Enums for passive gizmo scope in room scenes.
# Defined here since it's used in both the gizmo manager and the plugin toolbar.
enum PassiveScope {
	SELECTED_OBJECT,
	ROOM,
}

# State
var _target_node: Node2D
var _undo: EditorUndoRedoManager
var _gizmos: Array[GizmoPolygon2D] = []
var _grabbed_gizmo: GizmoPolygon2D
var _grabbed_snapshot: PackedVector2Array
# Whether editing is enabled per category (controlled by toolbar button).
# When true, the selected object's polygon gizmos are visible AND interactive.
var _editing_enabled: Dictionary = {
	GizmoPolygon2D.PolygonCategory.INTERACTION: true,
	GizmoPolygon2D.PolygonCategory.OBSTACLE: true,
	GizmoPolygon2D.PolygonCategory.WALKABLE_AREA: true,
}
# Whether unselected overlays are enabled per category (from editor settings).
# Controls visibility of non-selected objects' polygons, and the selected
# object's polygons when editing is disabled for that category.
var _always_show: Dictionary = {
	GizmoPolygon2D.PolygonCategory.INTERACTION: false,
	GizmoPolygon2D.PolygonCategory.OBSTACLE: false,
	GizmoPolygon2D.PolygonCategory.WALKABLE_AREA: false,
}
# Passive gizmo scope: selected object only, or all room objects.
var _passive_scope: PassiveScope = PassiveScope.SELECTED_OBJECT
# Dedicated toggle to show/hide walkable-area passive polygons in the room.
var _show_walkable_area_passive: bool = true
# Appearance settings (read from editor config)
var _colors: Dictionary = {}
var _fill_alpha: float = 0.15
var _vertex_handler_size: float = 6.0
# Alpha multiplier applied to non-interactive (passive) gizmos so they
# appear dimmed compared to the actively selected polygon.
var _passive_alpha_factor: float = 0.4


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


# Apply appearance settings to a gizmo based on its category.
# Non-interactive (passive) gizmos are drawn with a reduced alpha so
# the actively selected polygon stands out visually.
func _set_gizmo_theme(gizmo: GizmoPolygon2D) -> void:
	var cat := gizmo.category
	# Visibility depends on the gizmo's role:
	# - Interactive gizmos (selected object, editing ON): always visible
	# - Passive gizmos: visible only when "always show" is enabled
	if gizmo.interactive:
		gizmo.visible = true
	else:
		gizmo.visible = _should_show_passive_gizmo(gizmo)

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

	# Dim passive (non-interactive) gizmos so the selected one stands out
	var alpha_factor := 1.0 if gizmo.interactive else _passive_alpha_factor
	gizmo.outline_color = Color(gizmo.outline_color, gizmo.outline_color.a * alpha_factor)
	gizmo.fill_color = Color(gizmo.outline_color, _fill_alpha * alpha_factor)
	gizmo.vertex_color = Color.WHITE
	gizmo.vertex_size = _vertex_handler_size


# Helper to determine if a gizmo belongs to the currently selected object.
func _is_gizmo_from_target(gizmo: GizmoPolygon2D) -> bool:
	return (
		_target_node != null
		and is_instance_valid(gizmo.get_source_node())
		and gizmo.get_source_node().get_parent() == _target_node
	)


# Helper to determine if a passive gizmo should be visible based on editor settings
# and the current passive scope (defined by toolbar buttons).
func _should_show_passive_gizmo(gizmo: GizmoPolygon2D) -> bool:
	if not _always_show.get(gizmo.category, false):
		return false

	# Walkable areas are controlled exclusively by the dedicated toolbar button,
	# regardless of selected/room passive scope.
	if gizmo.category == GizmoPolygon2D.PolygonCategory.WALKABLE_AREA:
		return _show_walkable_area_passive


	if _passive_scope == PassiveScope.ROOM:
		return true

	return _is_gizmo_from_target(gizmo)


# Update gizmo states based on the currently selected object and editor settings.
func _refresh_gizmos_state() -> void:
	for gizmo in _gizmos:
		var belongs_to_target := _is_gizmo_from_target(gizmo)
		gizmo.interactive = belongs_to_target and _editing_enabled.get(gizmo.category, false)
		_set_gizmo_theme(gizmo)


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


# Scan every standard container in a room for polygon children.
# This populates _gizmos with entries for every polygon in the scene so
# passive (non-selected) polygons can be drawn alongside the active one.
func _scan_room_containers(room: PopochiuRoom) -> void:
	for container_name in ["Props", "Hotspots", "Regions", "Characters", "WalkableAreas"]:
		var container := room.find_child(container_name)
		if container == null:
			continue
		for child in container.get_children():
			_scan_polygons(child)


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
	_passive_alpha_factor = PopochiuEditorConfig.get_editor_setting(
		PopochiuEditorConfig.GIZMOS_POLY_PASSIVE_ALPHA_FACTOR
	)
	_always_show[GizmoPolygon2D.PolygonCategory.INTERACTION] = PopochiuEditorConfig.get_editor_setting(
		PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_INT
	)
	_always_show[GizmoPolygon2D.PolygonCategory.OBSTACLE] = PopochiuEditorConfig.get_editor_setting(
		PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_OBS
	)
	_always_show[GizmoPolygon2D.PolygonCategory.WALKABLE_AREA] = PopochiuEditorConfig.get_editor_setting(
		PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_WA
	)
	_show_walkable_area_passive = _always_show[GizmoPolygon2D.PolygonCategory.WALKABLE_AREA]

	# Re-apply to existing gizmos
	_refresh_gizmos_state()


# Handle a newly selected object. Build gizmos for every polygon in the scene
# so that non-selected polygons are visible as passive (read-only) overlays,
# while the selected node's polygons remain fully interactive.
func handle_object(object: Object, edited_root: Node) -> bool:
	_gizmos.clear()
	_grabbed_gizmo = null
	_grabbed_snapshot = PackedVector2Array()

	# When editing a Character scene (not a room), scan only the character root.
	# All gizmos are interactive since there is only one object.
	if edited_root is PopochiuCharacter:
		_target_node = edited_root
		_scan_polygons(edited_root)
		_refresh_gizmos_state()
		return _gizmos.size() > 0

	# Room editing mode — scan every container so all polygons in the room
	# are visible. The selected object's gizmos become interactive (editable)
	# while the rest remain passive (read-only).
	if edited_root is PopochiuRoom:
		# Determine which node the user explicitly selected
		if (
			object is PopochiuWalkableArea
			or object is PopochiuClickable
			or object is PopochiuRegion
		):
			_target_node = object
		else:
			# Room root or an unrelated node — overview mode, no editable polygon
			_target_node = null

		# Scan all room containers for polygon children
		_scan_room_containers(edited_root)
		_refresh_gizmos_state()

		return _gizmos.size() > 0

	reset()
	return false


# Draw all visible polygon gizmos.
# Two-pass rendering: passive (non-interactive) gizmos are drawn first so that
# the actively selected polygon renders on top and remains clearly visible.
func draw_gizmos(viewport_control: Control) -> void:
	# First pass — passive gizmos (behind)
	for gizmo in _gizmos:
		if gizmo.visible and gizmo.is_valid() and not gizmo.interactive:
			gizmo.draw(viewport_control)
	# Second pass — interactive gizmos (on top)
	for gizmo in _gizmos:
		if gizmo.visible and gizmo.is_valid() and gizmo.interactive:
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


# Toggle editing for a polygon category. When enabled, the selected object's
# gizmos become visible and interactive. When disabled, they fall back to the
# "always show" passive visibility from the editor settings.
func set_category_editing(category: GizmoPolygon2D.PolygonCategory, enabled: bool) -> void:
	_editing_enabled[category] = enabled
	_refresh_gizmos_state()


# Set passive polygon scope for room scenes.
# SELECTED_OBJECT: passive polygons only for the selected object.
# ROOM: passive polygons for all room objects.
func set_passive_scope(scope: PassiveScope) -> void:
	_passive_scope = scope
	_refresh_gizmos_state()


# Toggle passive walkable-area polygons visibility independently from the
# scope buttons, so users can quickly declutter room overlays.
func set_walkable_area_passive_visibility(visible: bool) -> void:
	_show_walkable_area_passive = visible
	_refresh_gizmos_state()


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
