@tool
class_name PopochiuAnimationCreatorSprite2D
extends "res://addons/popochiu/editor/importers/aseprite/animation_creator_base.gd"

## Animation creator specialized for Sprite2D nodes.
## Used for characters and room props that use frame-based animation.


#region Protected #################################################################################
func _find_sprite_in_target() -> Node:
	if _target_node.has_node("Sprite2D"):
		return _target_node.get_node("Sprite2D")
	return null


func _setup_texture() -> void:
	# Load texture in target sprite.
	var base_texture = ResourceLoader.load(
		_spritesheet_metadata.sprite_sheet, 'Image', ResourceLoader.CACHE_MODE_IGNORE
	)
	base_texture.take_over_path(_spritesheet_metadata.sprite_sheet)
	_target_sprite.texture = base_texture

	if _spritesheet_metadata.frames.is_empty():
		return

	# Set hframes and vframes for Sprite2D.
	_target_sprite.hframes = (
		_spritesheet_metadata.meta.size.w / _spritesheet_metadata.frames[0].sourceSize.w
	)
	_target_sprite.vframes = (
		_spritesheet_metadata.meta.size.h / _spritesheet_metadata.frames[0].sourceSize.h
	)


func _get_frame_property_track() -> String:
	return _get_property_track_path("frame")


func _get_frame_key(frame: Dictionary) -> Variant:
	return _calculate_frame_index(_target_sprite, frame)


func _create_meta_tracks(animation: Animation) -> void:
	# Create hframes/vframes tracks for Sprite2D.
	var hframes_track: String = _get_property_track_path("hframes")
	var hframes_track_index: int = _create_track(_target_sprite, animation, hframes_track)
	animation.track_insert_key(hframes_track_index, 0, _target_sprite.hframes)

	var vframes_track: String = _get_property_track_path("vframes")
	var vframes_track_index: int = _create_track(_target_sprite, animation, vframes_track)
	animation.track_insert_key(vframes_track_index, 0, _target_sprite.vframes)

	# Common visible track.
	var visible_track: String = _get_property_track_path("visible")
	var visible_track_index: int = _create_track(_target_sprite, animation, visible_track)
	animation.track_insert_key(visible_track_index, 0, true)


#endregion

#region Private ####################################################################################
func _calculate_frame_index(sprite: Sprite2D, frame: Dictionary) -> int:
	var column := floor(frame.frame.x * sprite.hframes / sprite.texture.get_width())
	var row := floor(frame.frame.y * sprite.vframes / sprite.texture.get_height())
	return (row * sprite.hframes) + column


#endregion