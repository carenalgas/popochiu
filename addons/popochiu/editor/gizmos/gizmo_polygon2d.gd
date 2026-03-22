@tool
class_name GizmoPolygon2D
extends RefCounted
# A gizmo that draws and allows editing of a polygon on the viewport overlay.
# It connects to a polygon source node (CollisionPolygon2D, NavigationRegion2D, or
# NavigationObstacle2D) and reads/writes vertex data from/to it.

# The category of polygon this gizmo represents
enum PolygonCategory {
	INTERACTION,
	OBSTACLE,
	WALKABLE_AREA
}

# Constants for hit detection
const EDGE_HIT_DISTANCE := 6.0
# Under this vertices count deletion won't be allowed
const MIN_VERTICES := 3
# Coordinate pairs for the default square polygon used when the source node has
# no vertices yet. A 32x32 square centered on the node origin, matching the
# default polygon we use for newly created Popochiu objects.
const DEFAULT_POLYGON_COORDS := [
    Vector2(-16, -16),
    Vector2(16, -16),
    Vector2(16, 16),
    Vector2(-16, 16)
]

# Public vars
var visible: bool = true
var interactive: bool = true
var category: PolygonCategory = PolygonCategory.INTERACTION

# Appearance
var fill_color: Color = Color(1.0, 1.0, 0.0, 0.15)
var outline_color: Color = Color.YELLOW
var vertex_color: Color = Color.WHITE
var vertex_size: float = 6.0:
	set(value):
		_on_vertex_size_changed(value)
var outline_width: float = 2.0

# Private vars
# The node that holds the polygon data
var _source_node: Node2D
# For NavigationRegion2D, which outline index this gizmo represents
var _outline_index: int = -1
# Cached polygon vertices in local coordinates
var _vertices: PackedVector2Array = PackedVector2Array()
# When true, _read_vertices() will re-read from the source node on next draw
var _dirty: bool = true
# State
var _grabbed_vertex_index: int = -1
var _is_grabbed: bool = false
var _grab_offset: Vector2  # Distance between vertex center and mouse at grab time
# Vertex handles in viewport coordinates (cached during draw)
var _vertex_handles_viewport: PackedVector2Array = PackedVector2Array()
# Vertex handle rectangles in viewport coordinates (cached during draw)
var _vertex_handle_rects: Array[Rect2] = []
# Cached combined transforms (updated each draw, reused by drag/grab)
var _combined_xform: Transform2D
var _combined_inverse: Transform2D
# Cached vertex size vectors (updated when vertex_size changes)
var _vertex_half_size: Vector2 = Vector2(6.0, 6.0)
var _vertex_full_size: Vector2 = Vector2(12.0, 12.0)
# The hovered vertex index (-1 if none)
var _hovered_vertex_index: int = -1
# The hovered edge index (-1 if none)
var _hovered_edge_index: int = -1
# The projected mouse position on the hovered edge (viewport coordinates)
var _hovered_edge_point: Vector2


#region Public #####################################################################################

func _init(
	source_node: Node2D,
	polygon_category: PolygonCategory,
	outline_index: int = -1
) -> void:
	_source_node = source_node
	category = polygon_category
	_outline_index = outline_index
	# Populate the cached Vector2 size helpers before any drawing can occur
	_update_vertex_size_cache()
	# Ensure the first draw() call reads fresh data from the source node
	_dirty = true
	# Populate the gizmo's appearance based on the current editor settings
	_read_vertices()


# Get the full polygon data as a PackedVector2Array (for undo/redo snapshots)
func get_polygon_snapshot() -> PackedVector2Array:
	_read_vertices()
	return _vertices.duplicate()


# Restore polygon data from a snapshot (for undo/redo)
func restore_polygon_snapshot(snapshot: PackedVector2Array) -> void:
	_vertices = snapshot.duplicate()
	_write_vertices()


# Signal that vertex data may have changed externally (e.g. undo/redo
# from another gizmo or the inspector). Next draw will re-read.
func mark_dirty() -> void:
	_dirty = true


# Draw the polygon on the viewport overlay
func draw(viewport: Control) -> void:
	if not visible:
		return
	if not is_instance_valid(_source_node) or not _source_node.is_inside_tree():
		return

	# Only re-read vertices when something has changed
	if _dirty:
		_read_vertices()

	if _vertices.size() < 2:
		return

	# Cache the combined transform (reused by grab_vertex / drag_vertex_to)
	_combined_xform = _source_node.get_viewport_transform() * _source_node.get_global_transform()
	_combined_inverse = _combined_xform.affine_inverse()

	# Transform all vertices to viewport coordinates and build handle rects
	_vertex_handles_viewport.clear()
	_vertex_handle_rects.clear()
	for vertex in _vertices:
		var vp := _combined_xform * vertex
		_vertex_handles_viewport.append(vp)
		_vertex_handle_rects.append(Rect2(vp - _vertex_half_size, _vertex_full_size))

	# Draw filled polygon (translucent)
	if _vertex_handles_viewport.size() >= 3:
		viewport.draw_colored_polygon(_vertex_handles_viewport, fill_color)

	# Draw outline edges
	for i in range(_vertex_handles_viewport.size()):
		var next_i := (i + 1) % _vertex_handles_viewport.size()
		var edge_color := outline_color
		# Highlight hovered edge
		if _hovered_edge_index == i and not _is_grabbed:
			edge_color = outline_color.lightened(0.5)
		viewport.draw_line(
			_vertex_handles_viewport[i],
			_vertex_handles_viewport[next_i],
			edge_color,
			outline_width
		)

	# Non-interactive gizmos skip vertex handles and hover previews
	if not interactive:
		return

	# Draw vertex handles from cached rects
	for i in range(_vertex_handle_rects.size()):
		var v_color := vertex_color
		# Highlight hovered or grabbed vertex
		if i == _grabbed_vertex_index and _is_grabbed:
			v_color = outline_color.lightened(0.7)
		elif i == _hovered_vertex_index and not _is_grabbed:
			v_color = outline_color.lightened(0.5)

		viewport.draw_rect(_vertex_handle_rects[i], Color.BLACK, false, 2.0)
		viewport.draw_rect(_vertex_handle_rects[i], v_color, true)

	# If hovering an edge (and not grabbing), draw a preview vertex at the
	# projected mouse position on the edge (shows the actual insertion point)
	if _hovered_edge_index >= 0 and not _is_grabbed:
		var preview_half := _vertex_half_size * 0.7
		var preview_full := _vertex_full_size * 0.7
		viewport.draw_rect(
			Rect2(_hovered_edge_point - preview_half, preview_full),
			outline_color.lightened(0.3), true
		)


# Test if a point (in viewport coordinates) hits a vertex handle.
# Uses the cached handle rects so corners of the square are included.
# Returns the vertex index, or -1 if no hit.
func hit_test_vertex(pos: Vector2) -> int:
	if not interactive:
		return -1
	for i in range(_vertex_handle_rects.size()):
		if _vertex_handle_rects[i].abs().has_point(pos):
			return i
	return -1


# Test if a point (in viewport coordinates) is near an edge.
# Returns the edge index (the index of the starting vertex), or -1.
# Also stores the projected point for preview drawing.
func hit_test_edge(pos: Vector2) -> int:
	if not interactive:
		return -1
	for i in range(_vertex_handles_viewport.size()):
		var next_i := (i + 1) % _vertex_handles_viewport.size()
		var a := _vertex_handles_viewport[i]
		var b := _vertex_handles_viewport[next_i]
		var projected := _project_point_on_segment(pos, a, b)
		if pos.distance_to(projected) <= EDGE_HIT_DISTANCE:
			_hovered_edge_point = projected
			return i
	return -1


# Update hover state based on mouse position. Returns true if any hover state changed.
func update_hover(pos: Vector2) -> bool:
	if not interactive:
		return false
	var old_vertex := _hovered_vertex_index
	var old_edge := _hovered_edge_index

	_hovered_vertex_index = hit_test_vertex(pos)
	if _hovered_vertex_index >= 0:
		_hovered_edge_index = -1
	else:
		_hovered_edge_index = hit_test_edge(pos)

	# Even if the hovered edge didn't change, the projected point may have
	# moved — request a redraw when hovering an edge so the preview tracks.
	var edge_changed := old_edge != _hovered_edge_index
	var vertex_changed := old_vertex != _hovered_vertex_index
	return vertex_changed or edge_changed or _hovered_edge_index >= 0


# Start dragging a vertex.
# Stores the offset between the vertex center and the mouse click position
# so the vertex doesn't jump when the user clicks slightly off-center
# (same approach as Gizmo2D.grab).
func grab_vertex(vertex_index: int, mouse_pos: Vector2) -> void:
	_grabbed_vertex_index = vertex_index
	_is_grabbed = true
	# Compute the vertex center in viewport coordinates from actual local data
	# (the cached _vertex_handles_viewport may be stale after insert_vertex_on_edge).
	# Uses the cached transform when available, falls back to computing it.
	var xform := _combined_xform if _combined_xform != Transform2D() else (
		_source_node.get_viewport_transform() * _source_node.get_global_transform()
	)
	var vertex_center := xform * _vertices[vertex_index]
	_grab_offset = vertex_center - mouse_pos


# Drag the grabbed vertex to a new mouse position (viewport coordinates).
# Applies the grab offset so the vertex tracks the mouse without jumping,
# then inverse-transforms to local node space.
func drag_vertex_to(mouse_pos: Vector2) -> void:
	if not _is_grabbed or _grabbed_vertex_index < 0:
		return
	if _grabbed_vertex_index >= _vertices.size():
		return

	var viewport_pos := mouse_pos + _grab_offset
	_vertices[_grabbed_vertex_index] = _combined_inverse * viewport_pos
	_write_vertices()


# Release the grabbed vertex
func release_vertex() -> void:
	_is_grabbed = false
	_grabbed_vertex_index = -1


# Cancel the vertex drag (caller should restore from snapshot)
func cancel_vertex() -> void:
	_is_grabbed = false
	_grabbed_vertex_index = -1


# Insert a new vertex on an edge. Returns the index of the new vertex.
func insert_vertex_on_edge(edge_index: int, mouse_pos: Vector2) -> int:
	if edge_index < 0 or edge_index >= _vertices.size():
		return -1

	# Convert mouse position from viewport to local coordinates
	var local_pos := _combined_inverse * mouse_pos

	# Insert after the edge's starting vertex
	var insert_index := edge_index + 1
	_vertices.insert(insert_index, local_pos)
	_write_vertices()
	return insert_index


# Delete a vertex by index. Returns true if successful (minimum 3 vertices enforced).
func delete_vertex(vertex_index: int) -> bool:
	if vertex_index < 0 or vertex_index >= _vertices.size():
		return false
	if _vertices.size() <= MIN_VERTICES:
		return false

	_vertices.remove_at(vertex_index)
	_write_vertices()
	return true


# Check if the gizmo currently has a grabbed vertex
func has_grabbed_vertex() -> bool:
	return _is_grabbed


# Get the source node
func get_source_node() -> Node2D:
	return _source_node


# Check if this gizmo is still valid (source node exists and is in tree)
func is_valid() -> bool:
	return is_instance_valid(_source_node) and _source_node.is_inside_tree()


#endregion

#region Private ####################################################################################
# Read polygon data from the source node.
# Falls back to DEFAULT_POLYGON when the source node has no vertices yet,
# so the gizmo is always editable without requiring a prior selection.
func _read_vertices() -> void:
	if not is_instance_valid(_source_node) or not _source_node.is_inside_tree():
		_vertices = PackedVector2Array()
		return

	if _source_node is CollisionPolygon2D:
		_vertices = _source_node.polygon.duplicate()
	elif _source_node is NavigationObstacle2D:
		_vertices = PackedVector2Array(_source_node.vertices.duplicate())
	elif (
		_source_node is NavigationRegion2D
		and _source_node.navigation_polygon
		and _outline_index >= 0
		and _outline_index < _source_node.navigation_polygon.get_outline_count()
	):
		_vertices = _source_node.navigation_polygon.get_outline(_outline_index).duplicate()
	else:
		_vertices = PackedVector2Array()

	# If the source node has no polygon yet, initialise it with the default square
	# and immediately write it back so the node is never left with an empty polygon.
	if _vertices.is_empty():
		_vertices.append_array(
			PackedVector2Array(DEFAULT_POLYGON_COORDS)
		)
		_write_vertices()

	# Data is now in sync with the source node, no re-read needed until next write
	_dirty = false


# Write polygon data back to the source node
func _write_vertices() -> void:
	if not is_instance_valid(_source_node) or not _source_node.is_inside_tree():
		return

	if _source_node is CollisionPolygon2D:
		_source_node.polygon = _vertices
	elif _source_node is NavigationRegion2D:
		if _source_node.navigation_polygon and _outline_index >= 0:
			_source_node.navigation_polygon.set_outline(_outline_index, _vertices)
	elif _source_node is NavigationObstacle2D:
		_source_node.vertices = _vertices

	# Viewport handles and cached transforms are now stale; next draw() must re-read
	_dirty = true


# Project a point onto a line segment, clamped to the segment endpoints.
# Returns the closest point on the segment.
func _project_point_on_segment(point: Vector2, seg_a: Vector2, seg_b: Vector2) -> Vector2:
	var ab := seg_b - seg_a
	var ab_len_sq := ab.length_squared()
	if ab_len_sq < 0.001:
		return seg_a
	var t := clampf((point - seg_a).dot(ab) / ab_len_sq, 0.0, 1.0)
	return seg_a + ab * t


# Update the cached vertex size vectors. Called when vertex_size changes.
func _update_vertex_size_cache() -> void:
	_vertex_half_size = Vector2(vertex_size, vertex_size)
	_vertex_full_size = Vector2(vertex_size * 2, vertex_size * 2)


# Setter body for vertex_size. Skips the cache update when the value
# hasn't changed to avoid redundant Vector2 allocations.
func _on_vertex_size_changed(value: float) -> void:
	if value == vertex_size:
		return
	vertex_size = value
	_update_vertex_size_cache()


#endregion
