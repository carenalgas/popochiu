@tool
class_name PopochiuPolygonsHelper
extends Object

## Static helper that traces an interaction polygon from a sprite's alpha channel.
##
## The pipeline follows these steps, each controlled by a constant:
## 1. Optionally denoise the image with a two-way resize ([constant TRACE_TWO_WAY_RESIZE]).
## 2. Build a [BitMap] from the alpha channel.
## 3. Optionally grow the bitmap mask ([constant TRACE_GROWTH]).
## 4. Extract polygon outlines via [method BitMap.opaque_to_polygons]
##    ([constant TRACE_EPSILON]).
## 5. Optionally expand/contract the outline ([constant TRACE_BEZEL]).
## 6. Optionally replace all polygons with a single convex hull
##    ([constant TRACE_CONVEX_HULL]).

# ---- Tracing parameters -----------------------------------------------------------------------

## Controls how closely the traced outline follows the pixel boundary.
## Lower values produce more accurate but more complex polygons; higher values simplify the result.
const TRACE_EPSILON := 3.5

## Number of pixels to grow the bitmap mask before tracing.
## Positive values expand the masked area, making the polygon slightly larger than the sprite.
const TRACE_GROWTH := 2

## Pixels to expand (positive) or contract (negative) the traced polygon boundary.
## Applied via [method Geometry2D.offset_polygon] after tracing.
const TRACE_BEZEL := 0

## When true, the image is scaled down by half and then back to its original size before tracing.
## This removes single-pixel noise and produces simpler polygon outlines for detailed sprites.
const TRACE_TWO_WAY_RESIZE := false

## When true, all traced polygon points are merged into a single convex hull polygon.
## Useful when the sprite silhouette is simple and concavity is not needed for interaction.
const TRACE_CONVEX_HULL := true


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
		TRACE_EPSILON,
		TRACE_BEZEL,
		TRACE_GROWTH,
		TRACE_TWO_WAY_RESIZE,
		TRACE_CONVEX_HULL
	)

	if polygon_levels.is_empty() or polygon_levels[0].is_empty():
		PopochiuUtils.print_warning(
			"PopochiuPolygonsHelper: tracing produced no polygons for '%s'." % clickable.name
		)
		return false

	# Use the first polygon from the outermost bezel level.
	# For collision purposes a single polygon outline is sufficient.
	var result_polygon: PackedVector2Array = polygon_levels[0][0]

	# Convert from bitmap space (top-left = 0,0) to the sprite's local coordinate space.
	var bitmap_to_local_offset := _compute_bitmap_to_local_offset(sprite)
	for i in result_polygon.size():
		result_polygon[i] += bitmap_to_local_offset

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


# Returns the vector that converts bitmap-space coordinates (origin at top-left) to the sprite's
# local coordinate space (origin at the sprite node position).
# Accounts for the sprite's centering flag, offset, and the current animation frame.
static func _compute_bitmap_to_local_offset(sprite: Sprite2D) -> Vector2:
	var frame_size := _get_sprite_frame_rect(sprite).size

	if sprite.centered:
		# A centered sprite displays with the frame center aligned to the node origin.
		# Bitmap (0,0) therefore maps to local (-w/2 + offset.x, -h/2 + offset.y).
		return Vector2(-frame_size.x / 2.0, -frame_size.y / 2.0) + sprite.offset
	else:
		# A non-centered sprite displays with the frame top-left at the node origin.
		# Bitmap (0,0) maps directly to local (offset.x, offset.y).
		return sprite.offset


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

