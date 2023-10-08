@tool
# This logic has been taken almost as-is from Vinicius Gerevini's
# Aseprite Wizard plugin. Credits goes to him for the real magic.
# See: https://godotengine.org/asset-library/asset/713
extends RefCounted


const RESULT_CODE = preload("res://addons/popochiu/editor/config/result_codes.gd")
const _DEFAULT_AL = "" # Empty string equals default "Global" animation library

# Vars configured on initialization
var _config: RefCounted
var _file_system: EditorFileSystem
var _aseprite: RefCounted

# Vars configured on animations creation
var _target_node: Node
var _player: AnimationPlayer
var _options: Dictionary
var _tags_subset: Array


# Class-logic vars
var _tags_options_lookup = {}
var _target_sprite: Sprite2D
var _output: Dictionary


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(config, aseprite: RefCounted, editor_file_system: EditorFileSystem = null):
	_config = config
	_file_system = editor_file_system
	_aseprite = aseprite

# Public access to the creation of animations. Params are passed downstream almost entirely.
# If tags_subset is not empty, only the animations tags contained in that list will be imported.
# NOTE: the tags list must contain valid tag dictionaries, not just strings.

# RESTART_FROM_HERE: I need to split this class in two. A good chunk of code is
# the same for characters and rooms, but some functions are better implemented
# vertically for the two cases! Starting from this public method.
# The version for rooms MUST expose a public method such as create_single_animation() or
# create_tag_animation().
func create_animations(target_node: Node, player: AnimationPlayer, options: Dictionary, tags_subset: Array = []):
	# Chores
	_target_node = target_node
	_player = player
	_options = options
	_tags_subset = tags_subset

	# Checks
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH

	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND

	if not FileAccess.file_exists(options.source):
		return RESULT_CODE.ERR_SOURCE_FILE_NOT_FOUND

	if not DirAccess.dir_exists_absolute(options.output_folder):
		return RESULT_CODE.ERR_OUTPUT_FOLDER_NOT_FOUND

	_target_sprite = _find_sprite_in_target()

	if _target_sprite == null:
		return RESULT_CODE.ERR_NO_SPRITE_FOUND
	
	if typeof(options.get("tags")) != TYPE_ARRAY:
		return RESULT_CODE.ERR_TAGS_OPTIONS_ARRAY_EMPTY

	if (options.wipe_old_animations):
		_remove_animations_from_player(player)

	# RESTART_FROM_HERE: this can be avoided by having two different classes
	# the code above here must be super()-ized

	# If no tags are specified, import all of them
	if _tags_subset.is_empty():
		_load_tags_options_lookup(options.get("tags"))
		
		var result = await _create_animations_from_file()
		
		if result != RESULT_CODE.SUCCESS:
			printerr(RESULT_CODE.get_error_message(result))
	else:
		# CLEANUP: from the inspector dock `_on_import_pressed()` method
		# we are receiving the whole set of tags, some of them not to be
		# imported (import flag disabled by the user interface).
		# Then we artificially limit the tags list in this method to
		# allow rooms to import one tag at the time.
		# That's a bit of a mess in terms of separation of concerns.
		# Maybe we should expose different methods from this class to
		# create animations, like create_all_animations() and create_animation(tag)
		_load_tags_options_lookup(_tags_subset)
		for tag in _tags_subset:
			var result = await _create_animations_from_tag(tag)

			if result != RESULT_CODE.SUCCESS:
				printerr(RESULT_CODE.get_error_message(result))


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _load_tags_options_lookup(tags: Array = []):
	for t in tags:
		_tags_options_lookup[t.tag_name] = t


func _find_sprite_in_target() -> Node:
	if not _target_node.has_node("Sprite2D"):
		return null
	return _target_node.get_node("Sprite2D")


func _remove_animations_from_player(player: AnimationPlayer):
	player.remove_animation_library(_DEFAULT_AL)


# RESTART_FROM_HERE: this function is still good, but maybe it has to be
# available only in character class?

func _create_animations_from_file():
	## TODO: See _aseprite.export_layer() when the time comes to add layers selection
	_output = _aseprite.export_file(_options.source, _options.output_folder, _options)

	if _output.is_empty():
		return RESULT_CODE.ERR_ASEPRITE_EXPORT_FAILED

	await _scan_filesystem()	

	var result = _import()

	if _config.should_remove_source_files():
		DirAccess.remove_absolute(_output.data_file)
		await _scan_filesystem()

	return result

# RESTART_FROM_HERE: same as above, should it belong to animation_creator_room subclass only?

func _create_animations_from_tag(tag: Dictionary):
	print(">>>>>>>> Creating animations for all tags")
	## TODO: See _aseprite.export_layer() when the time comes to add layers selection
	_output = _aseprite.export_tag(_options.source, tag.tag_name, _options.output_folder, _options)
	
	if _output.is_empty():
		return RESULT_CODE.ERR_ASEPRITE_EXPORT_FAILED

	await _scan_filesystem()	

	var result = _import()

	if _config.should_remove_source_files():
		DirAccess.remove_absolute(_output.data_file)
		await _scan_filesystem()

	#return result


# RESTART_FROM_HERE: from here, downstream, check the whole implementation
# and externalize everything that's different.
# this import function should be ok, I guess
func _import():
	var source_file = _output.data_file
	var sprite_sheet = _output.sprite_sheet

	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return file.get_open_error()

	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var content = test_json_conv.get_data()

	if not _aseprite.is_valid_spritesheet(content):
		return RESULT_CODE.ERR_INVALID_ASEPRITE_SPRITESHEET

	_setup_texture(sprite_sheet, content)
	var result = _configure_animations(content)
	if result != RESULT_CODE.SUCCESS:
		return result

	return RESULT_CODE.SUCCESS


func _load_texture(sprite_sheet: String) -> Texture2D:
	var texture = ResourceLoader.load(sprite_sheet, 'Image', ResourceLoader.CACHE_MODE_IGNORE)
	texture.take_over_path(sprite_sheet)
	return texture


# RESTART_FROM_HERE: this is SURELY to be externalized! It's the most important
# culprit actually

func _configure_animations(content: Dictionary):
	var frames = _aseprite.get_content_frames(content)

	if not _player.has_animation_library(_DEFAULT_AL):
		_player.add_animation_library(_DEFAULT_AL, AnimationLibrary.new())

	if content.meta.has("frameTags") and content.meta.frameTags.size() > 0:
		var result = RESULT_CODE.SUCCESS
		# RESTART_FROM_HERE: this is not necessary, BUT the output JSON is
		# needed to know how long the animation is... too bad it contains
		# the whole set of tags, so we must take the tag.from and tag.to and do
		# from 1 to tag.to+1 - tag.from + 1 (do the math an you'll see that's correct)
		for tag in content.meta.frameTags:
			if not _tags_options_lookup.get(tag.tag_name).get("import"):
				continue
			var selected_frames = frames.slice(tag.from, tag.to+1) # slice is [)
			result = _add_animation_frames(tag.name, selected_frames, tag.direction)
			if result != RESULT_CODE.SUCCESS:
				break
		return result
	else:
		return _add_animation_frames("default", frames)


# RESTART_FROM_HERE: ====================================
# what follows SHOULD be OK to keep as it is. The problem is all above.
# Cardinality is paramount here.

func _add_animation_frames(anim_name: String, frames: Array, direction = 'forward'):
	# TODO: ATM there is no way to assign a walk/talk/grab/idle animation
	# with a different name than the standard ones. The engine is searching for
	# lowercase names in the AnimationPlayer, thus we are forcing snake_case
	# animations name conversion.
	# We have to add methods or properties to the Character to assign different
	# animations (but maybe we can do with anim_prefix or other strategies).
	var animation_name = anim_name.to_snake_case()
	var is_loopable = _tags_options_lookup.get(anim_name).get("loops")

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


## TODO: insert validate tokens in amination name

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


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SPRITE NODE LOGIC ░░░░
# What follow is logic specifically gathered for Sprite elements. TextureRect should 
# be treated in a different way (see texture_rect_animation_creator.gd file in
# original Aseprite Wizard plugin by Vinicius Gerevini)
func _setup_texture(sprite_sheet: String, content: Dictionary):
	var texture = _load_texture(sprite_sheet)
	_target_sprite.texture = texture

	if content.frames.is_empty():
		return

	_target_sprite.hframes = content.meta.size.w / content.frames[0].sourceSize.w
	_target_sprite.vframes = content.meta.size.h / content.frames[0].sourceSize.h


func _create_meta_tracks(animation: Animation):
	var texture_track = _get_property_track_path("texture")
	var texture_track_index = _create_track(_target_sprite, animation, texture_track)
	animation.track_insert_key(texture_track_index, 0, _target_sprite.texture)

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

