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
const VERTEX_HIT_RADIUS := 8.0
const EDGE_HIT_DISTANCE := 6.0
const MIN_VERTICES := 3

# Public vars
var visible: bool = true
var category: PolygonCategory = PolygonCategory.INTERACTION

# Appearance
var fill_color: Color = Color(1.0, 1.0, 0.0, 0.15)
var outline_color: Color = Color.YELLOW
var vertex_color: Color = Color.WHITE
var vertex_size: float = 6.0
var outline_width: float = 2.0

# Private vars
# The node that holds the polygon data
var _source_node: Node2D
# For NavigationRegion2D, which outline index this gizmo represents
var _outline_index: int = -1
# Cached polygon vertices in local coordinates
var _vertices: PackedVector2Array = PackedVector2Array()
# State
var _grabbed_vertex_index: int = -1
var _is_grabbed: bool = false
var _grab_mouse_pos: Vector2
var _grab_vertex_pos: Vector2
# Vertex handles in viewport coordinates (cached during draw)
var _vertex_handles_viewport: PackedVector2Array = PackedVector2Array()
# Edge midpoints in viewport coordinates (for add-vertex hit testing)
var _edge_midpoints_viewport: PackedVector2Array = PackedVector2Array()
# The hovered vertex index (-1 if none)
var _hovered_vertex_index: int = -1
# The hovered edge index (-1 if none)
var _hovered_edge_index: int = -1


#region Public #####################################################################################

func _init(
    source_node: Node2D,
    polygon_category: PolygonCategory,
    outline_index: int = -1
) -> void:
    _source_node = source_node
    category = polygon_category
    _outline_index = outline_index
    _read_vertices()


# Coordinate pairs for the default square polygon used when the source node has
# no vertices yet. A 32x32 square centered on the node origin, matching the
# default polygon we use for newly created Popochiu objects.
const DEFAULT_POLYGON_COORDS := [[-16, -16], [16, -16], [16, 16], [-16, 16]]


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
        for pair in DEFAULT_POLYGON_COORDS:
            _vertices.append(Vector2(pair[0], pair[1]))
        _write_vertices()


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


# Get the full polygon data as a PackedVector2Array (for undo/redo snapshots)
func get_polygon_snapshot() -> PackedVector2Array:
    _read_vertices()
    return _vertices.duplicate()


# Restore polygon data from a snapshot (for undo/redo)
func restore_polygon_snapshot(snapshot: PackedVector2Array) -> void:
    _vertices = snapshot.duplicate()
    _write_vertices()


# Draw the polygon on the viewport overlay
func draw(viewport: Control) -> void:
    if not visible:
        return
    if not is_instance_valid(_source_node) or not _source_node.is_inside_tree():
        return

    # Re-read vertices to stay in sync
    _read_vertices()

    if _vertices.size() < 2:
        return

    # Compute the transform: local → global → viewport
    var source_transform := _source_node.get_global_transform()
    var viewport_transform := _source_node.get_viewport_transform()
    var combined_transform := viewport_transform * source_transform

    # Transform all vertices to viewport coordinates
    _vertex_handles_viewport.clear()
    _edge_midpoints_viewport.clear()
    for vertex in _vertices:
        _vertex_handles_viewport.append(combined_transform * vertex)

    # Compute edge midpoints for "insert vertex" hit testing
    for i in range(_vertex_handles_viewport.size()):
        var next_i := (i + 1) % _vertex_handles_viewport.size()
        _edge_midpoints_viewport.append(
            (_vertex_handles_viewport[i] + _vertex_handles_viewport[next_i]) * 0.5
        )

    # Draw filled polygon (translucent)
    if _vertex_handles_viewport.size() >= 3:
        var fill := fill_color
        viewport.draw_colored_polygon(_vertex_handles_viewport, fill)

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

    # Draw vertex handles
    for i in range(_vertex_handles_viewport.size()):
        var v_color := vertex_color
        # Highlight hovered or grabbed vertex
        if i == _grabbed_vertex_index and _is_grabbed:
            v_color = outline_color.lightened(0.7)
        elif i == _hovered_vertex_index and not _is_grabbed:
            v_color = outline_color.lightened(0.5)

        # Draw outline for vertex handle
        viewport.draw_rect(
            Rect2(_vertex_handles_viewport[i] - Vector2(vertex_size, vertex_size),
                Vector2(vertex_size * 2, vertex_size * 2)),
            Color.BLACK, false, 2.0
        )
        # Draw solid vertex handle
        viewport.draw_rect(
            Rect2(_vertex_handles_viewport[i] - Vector2(vertex_size, vertex_size),
                Vector2(vertex_size * 2, vertex_size * 2)),
            v_color, true
        )

    # If hovering an edge (and not grabbing), draw a preview vertex on the edge
    if _hovered_edge_index >= 0 and not _is_grabbed:
        var midpoint := _edge_midpoints_viewport[_hovered_edge_index]
        viewport.draw_rect(
            Rect2(midpoint - Vector2(vertex_size * 0.7, vertex_size * 0.7),
                Vector2(vertex_size * 1.4, vertex_size * 1.4)),
            outline_color.lightened(0.3), true
        )


# Test if a point (in viewport coordinates) hits a vertex handle.
# Returns the vertex index, or -1 if no hit.
func hit_test_vertex(pos: Vector2) -> int:
    for i in range(_vertex_handles_viewport.size()):
        if pos.distance_to(_vertex_handles_viewport[i]) <= VERTEX_HIT_RADIUS:
            return i
    return -1


# Test if a point (in viewport coordinates) is near an edge.
# Returns the edge index (the index of the starting vertex), or -1.
func hit_test_edge(pos: Vector2) -> int:
    for i in range(_vertex_handles_viewport.size()):
        var next_i := (i + 1) % _vertex_handles_viewport.size()
        var a := _vertex_handles_viewport[i]
        var b := _vertex_handles_viewport[next_i]
        var dist := _point_to_segment_distance(pos, a, b)
        if dist <= EDGE_HIT_DISTANCE:
            return i
    return -1


# Update hover state based on mouse position. Returns true if any hover state changed.
func update_hover(pos: Vector2) -> bool:
    var old_vertex := _hovered_vertex_index
    var old_edge := _hovered_edge_index

    _hovered_vertex_index = hit_test_vertex(pos)
    if _hovered_vertex_index >= 0:
        _hovered_edge_index = -1
    else:
        _hovered_edge_index = hit_test_edge(pos)

    return old_vertex != _hovered_vertex_index or old_edge != _hovered_edge_index


# Start dragging a vertex
func grab_vertex(vertex_index: int, mouse_pos: Vector2) -> void:
    _grabbed_vertex_index = vertex_index
    _is_grabbed = true
    _grab_mouse_pos = mouse_pos
    # Compute the viewport position of the vertex from the actual local data
    # instead of the cached _vertex_handles_viewport, which may be stale
    # (e.g. right after insert_vertex_on_edge).
    if (
        vertex_index >= 0
        and vertex_index < _vertices.size()
        and is_instance_valid(_source_node)
        and _source_node.is_inside_tree()
    ):
        var xform := _source_node.get_viewport_transform() * _source_node.get_global_transform()
        _grab_vertex_pos = xform * _vertices[vertex_index]
    else:
        _grab_vertex_pos = _grab_mouse_pos


# Drag the grabbed vertex to a new mouse position
func drag_vertex_to(mouse_pos: Vector2) -> void:
    if not _is_grabbed or _grabbed_vertex_index < 0:
        return
    if _grabbed_vertex_index >= _vertices.size():
        return

    # Compute offset from grab start
    var delta := mouse_pos - _grab_mouse_pos
    var new_viewport_pos := _grab_vertex_pos + delta

    # Inverse transform from viewport to local coordinates
    var source_transform := _source_node.get_global_transform()
    var viewport_transform := _source_node.get_viewport_transform()
    var combined_inverse := (viewport_transform * source_transform).affine_inverse()
    var new_local_pos := combined_inverse * new_viewport_pos

    _vertices[_grabbed_vertex_index] = new_local_pos
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
    var source_transform := _source_node.get_global_transform()
    var viewport_transform := _source_node.get_viewport_transform()
    var combined_inverse := (viewport_transform * source_transform).affine_inverse()
    var local_pos := combined_inverse * mouse_pos

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

# Compute distance from a point to a line segment
func _point_to_segment_distance(point: Vector2, seg_a: Vector2, seg_b: Vector2) -> float:
    var ab := seg_b - seg_a
    var ap := point - seg_a
    var ab_len_sq := ab.length_squared()
    if ab_len_sq < 0.001:
        return point.distance_to(seg_a)
    var t := clampf(ap.dot(ab) / ab_len_sq, 0.0, 1.0)
    var closest := seg_a + ab * t
    return point.distance_to(closest)


#endregion
