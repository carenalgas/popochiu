@tool
# This logic has been taken almost as-is from Vinicius Gerevini's
# Aseprite Wizard plugin. Credits goes to him for the real magic.
# See: https://godotengine.org/asset-library/asset/713
extends RefCounted

const RESULT_CODE = preload("res://addons/popochiu/editor/config/result_codes.gd")
const _DEFAULT_AL = "" # Empty string equals default "Global" animation library

# Vars configured on initialization
var _file_system: EditorFileSystem
var _aseprite: RefCounted

# Vars configured on animations creation
var _target_node: Node
var _player: AnimationPlayer
var _options: Dictionary

# Class-logic vars
var _spritesheet_metadata = {}
var _target_sprite: Sprite2D
var _output: Dictionary


#region Public #####################################################################################
func init(aseprite: RefCounted, editor_file_system: EditorFileSystem = null):
	_file_system = editor_file_system
	_aseprite = aseprite


## Public interfaces, dedicated to specific popochiu objects
func create_character_animations(character: Node, player: AnimationPlayer, options: Dictionary):
	# Chores
	_target_node = character
	_player = player
	_options = options

	# Duly check everything is valid and cleanup animations
	var result = _perform_common_checks()
	if result != RESULT_CODE.SUCCESS:
		return result

	# Create the spritesheet
	result = await _create_spritesheet_from_file()
	if result != RESULT_CODE.SUCCESS:
		return result

	# Load tags information
	result = await _load_spritesheet_metadata()
	if result != RESULT_CODE.SUCCESS:
		return result

	# Set the texture in the sprite and configure
	# the animations in the AnimationPlayer
	_setup_texture()
	result = _configure_animations()

	return result


func create_prop_animations(prop: Node, aseprite_tag: String, options: Dictionary):
	# Chores
	_target_node = prop
	# TODO: if the prop has no AnimationPlayer, add one!
	_player = prop.get_node("AnimationPlayer")
	_options = options

	var prop_animation_name = aseprite_tag.to_snake_case()

	# Duly check everything is valid and cleanup animations
	var result = _perform_common_checks()
	if result != RESULT_CODE.SUCCESS:
		return result

	# Create the spritesheet
	result = await _create_spritesheet_from_tag(aseprite_tag)
	if result != RESULT_CODE.SUCCESS:
		return result

	# Load tags information
	result = await _load_spritesheet_metadata(aseprite_tag)
	if result != RESULT_CODE.SUCCESS:
		return result

	# Set the texture in the sprite and configure
	# the animations in the AnimationPlayer
	_setup_texture()
	result = _configure_animations()

	# Sorry, mom...
	_player.autoplay = prop.name.to_snake_case()

	return result


#endregion

#region Private ####################################################################################
## This function creates a spritesheet with the whole file content
func _create_spritesheet_from_file():
	## TODO: See _aseprite.export_layer() when the time comes to add layers selection
	_output = _aseprite.export_file(_options.source, _options.output_folder, _options)
	if _output.is_empty():
		return RESULT_CODE.ERR_ASEPRITE_EXPORT_FAILED
	return RESULT_CODE.SUCCESS


## This function creates a spritesheet with the frames of a specific tag
## WARNING: it's case sensitive
func _create_spritesheet_from_tag(selected_tag: String):
	## TODO: See _aseprite.export_layer() when the time comes to add layers selection
	_output = _aseprite.export_tag(_options.source, selected_tag, _options.output_folder, _options)
	if _output.is_empty():
		return RESULT_CODE.ERR_ASEPRITE_EXPORT_FAILED
	return RESULT_CODE.SUCCESS


func _load_spritesheet_metadata(selected_tag: String = ""):
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

	# Save tags metadata, starting from user's selection, and retrieving
	# other information from JSON data
	var tags = _options.get("tags").filter(func(tag): return tag.get("import"))

	for t in tags:
		# If a tag is specified, ignore every other ones
		if not selected_tag.is_empty() and selected_tag != t.tag_name: continue
		# Create a lookup table for tags
		_spritesheet_metadata.tags[t.tag_name] = t

	for ft in _aseprite.get_content_meta_tags(content):
		if not _spritesheet_metadata.tags.has(ft.name): continue
		_spritesheet_metadata.tags.get(ft.name).merge({
			from = ft.from,
			to = ft.to,
			direction = ft.direction,
		})
	
	# If a tag is specified, the tags lookup table should contain
	# a single tag information. In this case the to and from properties
	# must be shifted back in the [1 - tag_length] range.
	if not selected_tag.is_empty():
		# Using a temp variable to make this readable
		var t = _spritesheet_metadata.tags[selected_tag]
		# NOTE: imagine this goes from 34 to 54, we need to shift
		# the range back of a 33 amount, so it goes from 1 to (54 - 33)
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


func _configure_animations():
	if not _player.has_animation_library(_DEFAULT_AL):
		_player.add_animation_library(_DEFAULT_AL, AnimationLibrary.new())

	if _spritesheet_metadata.tags.size() > 0:
		var result = RESULT_CODE.SUCCESS
		# RESTART_FROM_HERE: WARNING: in case of prop and inventory, the JSON file contains
		# the whole set of tags, so we must take the tag.from and tag.to and remap the range
		# from "1" to "tag.to +1 - tag.from + 1" (do the math an you'll see that's correct)
		for tag in _spritesheet_metadata.tags.values():
			var selected_frames = _spritesheet_metadata.frames.slice(tag.from, tag.to + 1) # slice is [)
			result = _add_animation_frames(tag.tag_name, selected_frames, tag.direction)
			if result != RESULT_CODE.SUCCESS:
				break
		return result
	else:
		return _add_animation_frames("default", _spritesheet_metadata.frames)


func _add_animation_frames(anim_name: String, frames: Array, direction = 'forward'):
	# TODO: ATM there is no way to assign a walk/talk/grab/idle animation
	# with a different name than the standard ones. The engine is searching for
	# lowercase names in the AnimationPlayer, thus we are forcing snake_case
	# animations name conversion.
	# We have to add methods or properties to the Character to assign different
	# animations (but maybe we can do with anim_prefix or other strategies).
	var animation_name = anim_name.to_snake_case()
	var is_loopable = _spritesheet_metadata.tags.get(anim_name).get("loops")

	# Create animation library if it doesn't exist
	# This is always true if the user selected to wipe old animations.
	# See _remove_animations_from_player() function.
	if not _player.has_animation_library(_DEFAULT_AL):
		_player.add_animation_library(_DEFAULT_AL, AnimationLibrary.new())

	if not _player.get_animation_library(_DEFAULT_AL).has_animation(animation_name):
		_player.get_animation_library(_DEFAULT_AL).add_animation(animation_name, Animation.new())

	# Here is where animations are created.
	# TODO: we need to "fork" the logic so that Character has a single spritesheet
	# containing all tags, while Rooms/Props and Inventory Items has a single spritesheet
	# for each tag, so that you can have each prop with its own animation (PnC)
	var animation = _player.get_animation(animation_name)
	_create_meta_tracks(animation)
	var frame_track = _get_property_track_path("frame")
	var frame_track_index = _create_track(_target_sprite, animation, frame_track)

	if direction == 'reverse':
		frames.reverse()

	var animation_length = 0

	for frame in frames:
		var frame_key = _get_frame_key(frame)
		animation.track_insert_key(frame_track_index, animation_length, frame_key)
		animation_length += frame.duration / 1000 ## NOTE: animation_length is in seconds

	if direction == 'pingpong':
		frames.remove_at(frames.size() - 1)
		if is_loopable:
			frames.remove_at(0)
		frames.reverse()

		for frame in frames:
			var frame_key = _get_frame_key(frame)
			animation.track_insert_key(frame_track_index, animation_length, frame_key)
			animation_length += frame.duration / 1000 ## NOTE: animation_length is in seconds

	animation.length = animation_length
	animation.loop_mode = Animation.LOOP_LINEAR if is_loopable else Animation.LOOP_NONE

	return RESULT_CODE.SUCCESS


## TODO: insert validate tokens in animation name
func _create_track(target_sprite: Node, animation: Animation, track: String):
	var track_index = animation.find_track(track, Animation.TYPE_VALUE)

	if track_index != -1:
		animation.remove_track(track_index)

	track_index = animation.add_track(Animation.TYPE_VALUE)
	## Here we set a label for the track in the sprite_path:property_changed format
	## so that _get_property_track_path can rebuild it by naming convention
	animation.track_set_path(track_index, track)
	animation.track_set_interpolation_loop_wrap(track_index, false)
	animation.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)

	return track_index


func _get_property_track_path(prop: String) -> String:
	var node_path = _player.get_node(_player.root_node).get_path_to(_target_sprite)
	return "%s:%s" % [node_path, prop]


func _scan_filesystem():
	_file_system.scan()
	await _file_system.filesystem_changed


func _remove_properties_from_path(path: NodePath) -> NodePath:
	var string_path := path as String
	if !(":" in string_path):
		return string_path as NodePath

	var property_path := path.get_concatenated_subnames() as String
	string_path = string_path.substr(0, string_path.length() - property_path.length() - 1)

	return string_path as NodePath


# ---- SPRITE NODE LOGIC ---------------------------------------------------------------------------
## What follow is logic specifically gathered for Sprite elements. TextureRect should 
## be treated in a different way (see texture_rect_animation_creator.gd file in
## original Aseprite Wizard plugin by Vinicius Gerevini)
func _setup_texture():
	# Load texture in target sprite (ignoring cache and forcing a refres)
	var texture = ResourceLoader.load(
		_spritesheet_metadata.sprite_sheet, 'Image', ResourceLoader.CACHE_MODE_IGNORE
	)
	texture.take_over_path(_spritesheet_metadata.sprite_sheet)
	_target_sprite.texture = texture

	if _spritesheet_metadata.frames.is_empty():
		return

	_target_sprite.hframes = (
		_spritesheet_metadata.meta.size.w / _spritesheet_metadata.frames[0].sourceSize.w
	)
	_target_sprite.vframes = (
		_spritesheet_metadata.meta.size.h / _spritesheet_metadata.frames[0].sourceSize.h
	)


func _create_meta_tracks(animation: Animation):
	var hframes_track = _get_property_track_path("hframes")
	var hframes_track_index = _create_track(_target_sprite, animation, hframes_track)
	animation.track_insert_key(hframes_track_index, 0, _target_sprite.hframes)

	var vframes_track = _get_property_track_path("vframes")
	var vframes_track_index = _create_track(_target_sprite, animation, vframes_track)
	animation.track_insert_key(vframes_track_index, 0, _target_sprite.vframes)

	var visible_track = _get_property_track_path("visible")
	var visible_track_index = _create_track(_target_sprite, animation, visible_track)
	animation.track_insert_key(visible_track_index, 0, true)

	
func _get_frame_key(frame: Dictionary):
	return _calculate_frame_index(_target_sprite,frame)


func _calculate_frame_index(sprite: Node, frame: Dictionary) -> int:
	var column = floor(frame.frame.x * sprite.hframes / sprite.texture.get_width())
	var row = floor(frame.frame.y * sprite.vframes / sprite.texture.get_height())
	return (row * sprite.hframes) + column


func _perform_common_checks():
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

	if (_options.wipe_old_animations):
		_remove_animations_from_player(_player)
	
	return RESULT_CODE.SUCCESS


func _find_sprite_in_target() -> Node:
	if not _target_node.has_node("Sprite2D"):
		return null
	return _target_node.get_node("Sprite2D")


func _remove_animations_from_player(player: AnimationPlayer):
	if player.has_animation_library(_DEFAULT_AL):
		player.remove_animation_library(_DEFAULT_AL)


#endregion
