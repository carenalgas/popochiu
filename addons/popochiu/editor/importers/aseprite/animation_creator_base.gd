@tool
class_name PopochiuAnimationCreatorBase
extends RefCounted

## Base class for Popochiu animation creators.
## Defines the common interface and shared functionality for creating animations
## from Aseprite files for different node types.

const RESULT_CODE = preload("res://addons/popochiu/editor/config/result_codes.gd")
const _DEFAULT_AL = PopochiuEditorHelper.EMPTY_STRING # Empty string equals default "Global" animation library

# Vars configured on initialization
var _file_system: EditorFileSystem
var _aseprite: RefCounted

# Vars configured on animations creation
var _target_node: Node
var _player: AnimationPlayer
var _options: Dictionary

# Class-logic vars
var _spritesheet_metadata: Dictionary = {}
var _target_sprite: CanvasItem
var _output: Dictionary


#region Public #####################################################################################
## Initialize the animation creator with required dependencies.
func init(aseprite: RefCounted, editor_file_system: EditorFileSystem = null) -> void:
	_file_system = editor_file_system
	_aseprite = aseprite


## Create animations from all tags in the Aseprite file.
func create_all_animations(target_node: Node, options: Dictionary) -> int:
	return await _create_animations(target_node, options, PopochiuEditorHelper.EMPTY_STRING)


## Create animations from a specific Aseprite tag.
func create_tag_animations(target_node: Node, aseprite_tag: String, options: Dictionary) -> int:
	return await _create_animations(target_node, options, aseprite_tag)


## Configure autoplay based on the specified mode and context.
func setup_autoplay(animation: String = PopochiuEditorHelper.EMPTY_STRING) -> void:
	_player.autoplay = PopochiuEditorHelper.EMPTY_STRING  # Reset autoplay to default
	if not animation.is_empty():
		_player.autoplay = animation.to_snake_case()


#endregion


#region Protected #################################################################################
## Main animation creation logic that handles both full-file and tag-based imports.
func _create_animations(target_node: Node, options: Dictionary, tag: String = PopochiuEditorHelper.EMPTY_STRING) -> int:
	var result := _setup_common(target_node, options)
	if result != RESULT_CODE.SUCCESS:
		return result

	# Perform common checks
	result = _perform_common_checks()
	if result != RESULT_CODE.SUCCESS:
		return result

	# Create the spritesheet based on whether we're importing a tag or the full file
	if tag.is_empty():
		result = await _create_spritesheet_from_file()
	else:
		result = await _create_spritesheet_from_tag(tag)
	
	if result != RESULT_CODE.SUCCESS:
		return result

	# Load tags information
	result = await _load_spritesheet_metadata(tag)
	if result != RESULT_CODE.SUCCESS:
		return result

	# Set the texture and configure animations
	_setup_texture()
	result = _configure_animations()
	
	return result


## Common setup for all animation creators.
func _setup_common(target_node: Node, options: Dictionary) -> int:
	_target_node = target_node
	_player = _find_animation_player()
	if _player == null:
		PopochiuUtils.print_error(
			RESULT_CODE.get_error_message(RESULT_CODE.ERR_NO_ANIMATION_PLAYER_FOUND)
		)
		return RESULT_CODE.ERR_NO_ANIMATION_PLAYER_FOUND
	
	_options = options
	return RESULT_CODE.SUCCESS


## Find the AnimationPlayer node. Can be overridden by subclasses.
func _find_animation_player() -> AnimationPlayer:
	return _target_node.get_node("AnimationPlayer")


## Find the target sprite node. Must be implemented by subclasses.
func _find_sprite_in_target() -> Node:
	assert(false, "_find_sprite_in_target must be implemented by subclasses")
	return null


## Setup texture for the target sprite. Must be implemented by subclasses.
func _setup_texture() -> void:
	assert(false, "_setup_texture must be implemented by subclasses")


## Get the appropriate property track path. Must be implemented by subclasses.
func _get_frame_property_track() -> String:
	assert(false, "_get_frame_property_track must be implemented by subclasses")
	return PopochiuEditorHelper.EMPTY_STRING


## Get the frame key for animation. Must be implemented by subclasses.
func _get_frame_key(frame: Dictionary) -> Variant:
	assert(false, "_get_frame_key must be implemented by subclasses")
	return null


## Create meta tracks for the animation. Must be implemented by subclasses.
func _create_meta_tracks(animation: Animation) -> void:
	assert(false, "_create_meta_tracks must be implemented by subclasses")


#endregion


#region Private ####################################################################################
## Create a spritesheet with the whole file content.
func _create_spritesheet_from_file() -> int:
	_output = _aseprite.export_file(_options.source, _options.output_folder, _options)
	if _output.is_empty():
		return RESULT_CODE.ERR_ASEPRITE_EXPORT_FAILED
	return RESULT_CODE.SUCCESS


## Create a spritesheet with the frames of a specific tag.
func _create_spritesheet_from_tag(selected_tag: String) -> int:
	_output = _aseprite.export_tag(_options.source, selected_tag, _options.output_folder, _options)
	if _output.is_empty():
		return RESULT_CODE.ERR_ASEPRITE_EXPORT_FAILED
	return RESULT_CODE.SUCCESS


func _load_spritesheet_metadata(selected_tag: String = PopochiuEditorHelper.EMPTY_STRING) -> int:
	_spritesheet_metadata = {
		tags = {},
		frames = {},
		meta = {},
		sprite_sheet = {}
	}

	# Refresh filesystem
	await _scan_filesystem()

	# Collect all needed info
	var source_file = _output.data_file
	var sprite_sheet = _output.sprite_sheet
	
	# Try to access, decode and validate Aseprite JSON output
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return file.get_open_error()
		
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var content = test_json_conv.get_data()
	
	if not _aseprite.is_valid_spritesheet(content):
		return RESULT_CODE.ERR_INVALID_ASEPRITE_SPRITESHEET
	
	# Save image metadata from JSON data
	_spritesheet_metadata.meta = content.meta

	# Save frames metadata from JSON data
	_spritesheet_metadata.frames = _aseprite.get_content_frames(content)

	# Save tags metadata, starting from user's selection
	var tags = _options.get("tags").filter(func(tag): return tag.get("import"))

	for t in tags:
		# If a tag is specified, ignore every other ones
		if not selected_tag.is_empty() and selected_tag != t.tag_name: 
			continue
		# Create a lookup table for tags
		_spritesheet_metadata.tags[t.tag_name] = t

	for ft in _aseprite.get_content_meta_tags(content):
		if not _spritesheet_metadata.tags.has(ft.name): 
			continue
		_spritesheet_metadata.tags.get(ft.name).merge({
			from = ft.from,
			to = ft.to,
			direction = ft.direction,
		})
	
	# If a tag is specified, adjust frame range
	if not selected_tag.is_empty():
		var t = _spritesheet_metadata.tags[selected_tag]
		t.to = t.to - t.from + 1
		t.from = 0
		_spritesheet_metadata.tags[selected_tag] = t

	# Save spritesheet path from the command output
	_spritesheet_metadata.sprite_sheet = sprite_sheet

	# Remove the JSON file if config says so
	if PopochiuEditorConfig.should_remove_source_files():
		DirAccess.remove_absolute(_output.data_file)
		await _scan_filesystem()

	return RESULT_CODE.SUCCESS


func _configure_animations() -> int:
	if not _player.has_animation_library(_DEFAULT_AL):
		_player.add_animation_library(_DEFAULT_AL, AnimationLibrary.new())

	if _spritesheet_metadata.tags.size() > 0:
		var result = RESULT_CODE.SUCCESS
		for tag in _spritesheet_metadata.tags.values():
			var selected_frames = _spritesheet_metadata.frames.slice(tag.from, tag.to + 1)
			result = _add_animation_frames(tag.tag_name, selected_frames, tag.direction)
			if result != RESULT_CODE.SUCCESS:
				break
		return result
	else:
		return _add_animation_frames("default", _spritesheet_metadata.frames)


func _add_animation_frames(anim_name: String, frames: Array, direction = 'forward') -> int:
	var animation_name = anim_name.to_snake_case()
	var is_loopable = _spritesheet_metadata.tags.get(anim_name).get("loops")

	# Create animation library if it doesn't exist
	if not _player.has_animation_library(_DEFAULT_AL):
		_player.add_animation_library(_DEFAULT_AL, AnimationLibrary.new())

	if not _player.get_animation_library(_DEFAULT_AL).has_animation(animation_name):
		_player.get_animation_library(_DEFAULT_AL).add_animation(animation_name, Animation.new())

	var animation = _player.get_animation(animation_name)
	_create_meta_tracks(animation)
	
	var frame_track: String = _get_frame_property_track()
	var frame_track_index = _create_track(_target_sprite, animation, frame_track)

	if direction == 'reverse':
		frames.reverse()

	var animation_length = 0

	for frame in frames:
		var frame_key = _get_frame_key(frame)
		animation.track_insert_key(frame_track_index, animation_length, frame_key)
		animation_length += frame.duration / 1000

	if direction == 'pingpong':
		frames.remove_at(frames.size() - 1)
		if is_loopable:
			frames.remove_at(0)
		frames.reverse()

		for frame in frames:
			var frame_key = _get_frame_key(frame)
			animation.track_insert_key(frame_track_index, animation_length, frame_key)
			animation_length += frame.duration / 1000

	animation.length = animation_length
	animation.loop_mode = Animation.LOOP_LINEAR if is_loopable else Animation.LOOP_NONE

	return RESULT_CODE.SUCCESS


func _create_track(target_sprite: Node, animation: Animation, track: String) -> int:
	var track_index = animation.find_track(track, Animation.TYPE_VALUE)

	if track_index != -1:
		animation.remove_track(track_index)

	track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, track)
	animation.track_set_interpolation_loop_wrap(track_index, false)
	animation.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)

	return track_index


func _get_property_track_path(prop: String) -> String:
	var node_path = _player.get_node(_player.root_node).get_path_to(_target_sprite)
	return "%s:%s" % [node_path, prop]


func _scan_filesystem() -> void:
	_file_system.scan()
	await _file_system.filesystem_changed


func _perform_common_checks() -> int:
	# Checks
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH

	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND

	if not FileAccess.file_exists(_options.source):
		return RESULT_CODE.ERR_SOURCE_FILE_NOT_FOUND

	if not DirAccess.dir_exists_absolute(_options.output_folder):
		return RESULT_CODE.ERR_OUTPUT_FOLDER_NOT_FOUND

	_target_sprite = _find_sprite_in_target()

	if _target_sprite == null:
		return RESULT_CODE.ERR_NO_SPRITE_FOUND
	
	if typeof(_options.get("tags")) != TYPE_ARRAY:
		return RESULT_CODE.ERR_TAGS_OPTIONS_ARRAY_EMPTY

	if _options.wipe_old_animations:
		_remove_animations_from_player(_player)
	
	return RESULT_CODE.SUCCESS


func _remove_animations_from_player(player: AnimationPlayer) -> void:
	if player.has_animation_library(_DEFAULT_AL):
		player.remove_animation_library(_DEFAULT_AL)


#endregion