@tool
class_name PopochiuAnimationCreatorTextureRect
extends "res://addons/popochiu/editor/importers/aseprite/animation_creator_base.gd"

## Animation creator specialized for TextureRect nodes.
## Used for inventory items that use region-based animation with AtlasTexture.


#region Protected #################################################################################
func _find_sprite_in_target() -> Node:
	# For inventory items, the target node itself is the TextureRect.
	if _target_node is TextureRect:
		return _target_node
	return null


func _setup_texture() -> void:
	# Load texture in target sprite.
	var base_texture = ResourceLoader.load(
		_spritesheet_metadata.sprite_sheet, 'Image', ResourceLoader.CACHE_MODE_IGNORE
	)
	base_texture.take_over_path(_spritesheet_metadata.sprite_sheet)

	if _spritesheet_metadata.frames.is_empty():
		return

	# Create an AtlasTexture for TextureRect to support region animation.
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = base_texture
	
	# Set initial region to first frame.
	var first_frame: Dictionary = _spritesheet_metadata.frames[0]
	atlas_texture.region = Rect2(
		first_frame.frame.x, 
		first_frame.frame.y, 
		first_frame.sourceSize.w, 
		first_frame.sourceSize.h
	)
	_target_sprite.texture = atlas_texture
	
	# Store frame dimensions for later use in animations.
	_target_sprite.set_meta("frame_width", first_frame.sourceSize.w)
	_target_sprite.set_meta("frame_height", first_frame.sourceSize.h)


func _get_frame_property_track() -> String:
	return _get_property_track_path("texture:region")


func _get_frame_key(frame: Dictionary) -> Variant:
	# For TextureRect, use region-based animation.
	var frame_width = _target_sprite.get_meta("frame_width", frame.sourceSize.w)
	var frame_height = _target_sprite.get_meta("frame_height", frame.sourceSize.h)
	return Rect2(frame.frame.x, frame.frame.y, frame_width, frame_height)


func _create_meta_tracks(animation: Animation) -> void:
	# TextureRect doesn't need hframes/vframes tracks, only visibility.
	var visible_track: String = _get_property_track_path("visible")
	var visible_track_index: int = _create_track(_target_sprite, animation, visible_track)
	animation.track_insert_key(visible_track_index, 0, true)


#endregion