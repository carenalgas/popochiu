@tool
class_name PopochiuPolygonsHelper
extends Object

## Static helper that traces an interaction polygon from a sprite's alpha channel.
##
## The pipeline parameters are read from the Project Settings under
## [code]popochiu/auto_tracer/[/code] and configured via [PopochiuConfig]:
## 1. Optionally denoise the image ([member PopochiuConfig.AUTOTRACE_NOISE_REDUCTION]).
## 2. Build a [BitMap] from the alpha channel.
## 3. Optionally grow the bitmap mask ([member PopochiuConfig.AUTOTRACE_MASK_PADDING]).
## 4. Extract polygon outlines ([member PopochiuConfig.AUTOTRACE_APPROXIMATION]).
## 5. Optionally expand/contract the outline ([member PopochiuConfig.AUTOTRACE_OUTLINE_MARGIN]).
## 6. Optionally merge into a single convex hull ([member PopochiuConfig.AUTOTRACE_CONVEX_OUTLINE]).


#region Public #####################################################################################

## Traces the interaction polygon of [param clickable] from the alpha channel of its sprite.
## Supports [PopochiuProp] and [PopochiuCharacter] (both expose a [Sprite2D] child named
## [code]Sprite2D[/code]).
## The resulting polygon is written to the [CollisionPolygon2D] child named
## [code]InteractionPolygon[/code] and registered with [member PopochiuEditorHelper.undo_redo]
## so the action can be undone.
## Returns [code]false[/code] if no suitable sprite is found or tracing produced no polygons.
static func trace_interaction_polygon(clickable: Node) -> bool:
	var sprite := clickable.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null or sprite.texture == null:
		PopochiuUtils.print_warning(
			"PopochiuPolygonsHelper: no Sprite2D with a texture found on '%s'." % clickable.name
		)
		return false

	var interaction_polygon_node := (
		clickable.get_node_or_null("InteractionPolygon") as CollisionPolygon2D
	)
	if interaction_polygon_node == null:
		PopochiuUtils.print_warning(
			"PopochiuPolygonsHelper: no InteractionPolygon node found on '%s'." % clickable.name
		)
		return false

	var image := _get_sprite_image(sprite)
	if image == null:
		return false

	var polygon_levels := _compute_polygon(
		image,
		PopochiuConfig.get_autotrace_approximation(),
		PopochiuConfig.get_autotrace_outline_margin(),
		PopochiuConfig.get_autotrace_mask_padding(),
		PopochiuConfig.is_autotrace_noise_reduction(),
		PopochiuConfig.is_autotrace_convex_outline()
	)

	if polygon_levels.is_empty() or polygon_levels[0].is_empty():
		PopochiuUtils.print_warning(
			"PopochiuPolygonsHelper: tracing produced no polygons for '%s'." % clickable.name
		)
		return false

	# Use the first polygon from the outermost bezel level.
	# For collision purposes a single polygon outline is sufficient.
	var result_polygon: PackedVector2Array = polygon_levels[0][0]

	# Convert from bitmap space (top-left = 0,0) to the clickable's local coordinate space.
	# Uses a full Transform2D so the sprite node's position, rotation, and scale within the
	# parent are all accounted for.
	var bitmap_to_local := _compute_bitmap_to_local_transform(sprite)
	result_polygon = bitmap_to_local * result_polygon

	var previous_polygon := interaction_polygon_node.polygon.duplicate()

	PopochiuEditorHelper.undo_redo.create_action(
		"Autotrace interaction polygon for " + clickable.name
	)
	PopochiuEditorHelper.undo_redo.add_do_property(
		interaction_polygon_node, "polygon", result_polygon
	)
	PopochiuEditorHelper.undo_redo.add_undo_property(
		interaction_polygon_node, "polygon", previous_polygon
	)
	PopochiuEditorHelper.undo_redo.commit_action()

	# Notify the gizmo plugin with the exact node that changed, so only its gizmo
	# gets marked dirty and the viewport overlay is redrawn.
	PopochiuEditorHelper.signal_bus.interaction_polygon_autotraced.emit(interaction_polygon_node)

	return true

#endregion


#region Private ####################################################################################

# Returns the rect within the texture that represents the currently displayed frame, expressed
# in the texture's own pixel space.
# Handles two cases that can combine:
#   1. region_enabled: the visible area is limited to region_rect.
#   2. hframes/vframes > 1: the base rect (full texture or region_rect) is subdivided into a
#      grid of equal frames; only the cell at [member Sprite2D.frame] is displayed.
# When neither applies the full texture rect is returned.
static func _get_sprite_frame_rect(sprite: Sprite2D) -> Rect2:
	# Start from the base rect (explicit region or full texture).
	var base_rect: Rect2
	if sprite.region_enabled:
		base_rect = sprite.region_rect
	else:
		base_rect = Rect2(
			Vector2.ZERO,
			Vector2(sprite.texture.get_width(), sprite.texture.get_height())
		)

	# When hframes/vframes subdivide the base rect, isolate the current frame cell.
	if sprite.hframes > 1 or sprite.vframes > 1:
		var frame_w := base_rect.size.x / sprite.hframes
		var frame_h := base_rect.size.y / sprite.vframes
		var col := sprite.frame % sprite.hframes
		# Integer division gives the row index within the grid.
		var row := sprite.frame / sprite.hframes
		return Rect2(
			base_rect.position + Vector2(col * frame_w, row * frame_h),
			Vector2(frame_w, frame_h)
		)

	return base_rect


# Returns the image data for [param sprite] cropped to its effective display frame.
# For atlas sprites (hframes/vframes > 1), only the current frame cell is returned,
# avoiding tracing the entire atlas and producing a correct polygon size.
static func _get_sprite_image(sprite: Sprite2D) -> Image:
	var full_image := sprite.texture.get_image()
	if full_image == null:
		PopochiuUtils.print_warning("PopochiuPolygonsHelper: could not retrieve image from sprite texture.")
		return null

	var frame_rect := _get_sprite_frame_rect(sprite)
	# Crop to the frame only when the rect doesn't already cover the full texture.
	var full_rect := Rect2(Vector2.ZERO, Vector2(full_image.get_width(), full_image.get_height()))
	if frame_rect != full_rect:
		return full_image.get_region(Rect2i(frame_rect))

	return full_image


# Returns a Transform2D that converts bitmap-space coordinates (origin at top-left) to the
# clickable's local coordinate space (the Area2D parent of the Sprite2D).
# The transform is composed of two steps applied right-to-left:
#   1. A translation that maps bitmap (0,0) to the sprite's own local origin, accounting
#      for the centering flag and the sprite.offset property.
#   2. The sprite node's own transform within its parent (position, rotation, scale),
#      which places the result correctly in the clickable's coordinate space.
static func _compute_bitmap_to_local_transform(sprite: Sprite2D) -> Transform2D:
	var frame_size := _get_sprite_frame_rect(sprite).size

	# Step 1: centering/offset correction (bitmap space → sprite local space).
	var centering_offset: Vector2
	if sprite.centered:
		# The frame center is displayed at the sprite node origin; bitmap (0,0) is offset
		# by half the frame size in the negative direction, plus any explicit offset.
		centering_offset = Vector2(-frame_size.x / 2.0, -frame_size.y / 2.0) + sprite.offset
	else:
		# The frame top-left is at the sprite node origin; only the explicit offset applies.
		centering_offset = sprite.offset

	# Step 2: compose with the sprite node's transform in parent space so that the polygon
	# ends up in the clickable's local coordinate system regardless of the sprite's
	# position, rotation, or scale within the scene tree.
	return sprite.transform * Transform2D(0.0, centering_offset)


# Runs the full polygon-from-bitmap pipeline and returns a list-of-lists-of-polygons.
# The outer list represents bezel levels; each inner list holds polygon outlines for that level.
# When [param bezel] is 0, the result is [[polygons_from_bitmap]].
static func _compute_polygon(
	image: Image,
	epsilon: float,
	bezel: int,
	growth: int,
	use_two_way_resize: bool,
	use_convex_hull: bool
) -> Array:
	# Optionally denoise the image before converting to a bitmap.
	if use_two_way_resize:
		_apply_two_way_resize(image)

	var bitmap := _create_bitmap_from_alpha(image)

	if growth != 0:
		_grow_bitmap_mask(bitmap, growth)

	var raw_polygons := _trace_polygons_from_bitmap(bitmap, epsilon)

	var polygon_levels: Array
	if bezel != 0:
		polygon_levels = _apply_bezel(raw_polygons, bezel)
	else:
		polygon_levels = [raw_polygons]

	if use_convex_hull:
		polygon_levels = _apply_convex_hull(polygon_levels)

	return polygon_levels


# Scales [param image] down by half using nearest-neighbour interpolation, then back to its
# original size. This blurs single-pixel protrusions, yielding simpler polygon outlines.
static func _apply_two_way_resize(image: Image) -> void:
	var original_width := image.get_width()
	var original_height := image.get_height()
	image.resize(original_width / 2, original_height / 2, Image.INTERPOLATE_NEAREST)
	image.resize(original_width, original_height, Image.INTERPOLATE_NEAREST)


# Creates a [BitMap] from the alpha channel of [param image].
# Pixels with alpha above [param alpha_threshold] are treated as opaque (inside the shape).
static func _create_bitmap_from_alpha(image: Image, alpha_threshold: float = 0.0) -> BitMap:
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image, alpha_threshold)
	return bitmap


# Expands or contracts the bitmap mask by [param pixels].
static func _grow_bitmap_mask(bitmap: BitMap, pixels: int) -> void:
	bitmap.grow_mask(pixels, Rect2(Vector2.ZERO, bitmap.get_size()))


# Extracts polygon outlines from the opaque regions of [param bitmap].
# Returns an Array of [PackedVector2Array] in bitmap coordinate space.
static func _trace_polygons_from_bitmap(
	bitmap: BitMap, epsilon: float
) -> Array[PackedVector2Array]:
	return bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, bitmap.get_size()), epsilon)


# Expands or contracts each polygon by [param bezel] pixels via [method Geometry2D.offset_polygon].
# Returns one group of offset outlines per input polygon.
static func _apply_bezel(polygons: Array, bezel: int) -> Array:
	var polygon_levels := []
	for polygon in polygons:
		polygon_levels.append(Geometry2D.offset_polygon(polygon, bezel))
	return polygon_levels


# Flattens all polygon points into a single convex hull and returns [[hull_polygon]].
# The duplicate closing point returned by [method Geometry2D.convex_hull] is removed.
static func _apply_convex_hull(polygon_levels: Array) -> Array:
	var all_points: PackedVector2Array = []
	for polygon_group in polygon_levels:
		for polygon in polygon_group:
			for point in polygon:
				all_points.append(point)

	var hull := Geometry2D.convex_hull(all_points)
	# convex_hull returns a closed polygon where the last point duplicates the first; remove it.
	hull.resize(hull.size() - 1)
	return [[hull]]

#endregion

