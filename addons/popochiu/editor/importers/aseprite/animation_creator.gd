@tool
# This logic has been taken almost as-is from Vinicius Gerevini's
# Aseprite Wizard plugin. Credits goes to him for the real magic.
# See: https://godotengine.org/asset-library/asset/713
extends RefCounted


const RESULT_CODE = preload("res://addons/popochiu/editor/config/result_codes.gd")
const _DEFAULT_AL = "" # Empty string equals default "Global" animation library

var _aseprite = preload("./aseprite_controller.gd").new()

var _config: RefCounted
var _file_system: EditorFileSystem
var _tags_options_lookup = {}

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(config, editor_file_system: EditorFileSystem = null):
	_config = config
	_file_system = editor_file_system
	_aseprite.init(config)


func check_aseprite() -> int:
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH

	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND
	
	return RESULT_CODE.SUCCESS


func create_animations(target_node: Node, player: AnimationPlayer, options: Dictionary):
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH

	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND

	if not FileAccess.file_exists(options.source):
		return RESULT_CODE.ERR_SOURCE_FILE_NOT_FOUND

	if not DirAccess.dir_exists_absolute(options.output_folder):
		return RESULT_CODE.ERR_OUTPUT_FOLDER_NOT_FOUND

	var target_sprite = _find_sprite_in_target(target_node)

	if target_sprite == null:
		return RESULT_CODE.ERR_NO_SPRITE_FOUND
	
	if typeof(options.get("tags")) != TYPE_ARRAY:
		return RESULT_CODE.ERR_TAGS_OPTIONS_ARRAY_EMPTY
		
	_load_tags_options_lookup(options.get("tags"))

	if (options.wipe_old_animations):
		_remove_animations_from_player(player)
	
	var result = await _create_animations_from_file(target_sprite, player, options)
	
	if result != RESULT_CODE.SUCCESS:
		printerr(RESULT_CODE.get_error_message(result))


## TODO: Keep this as reference to populate a checkable list of layers
func list_layers(file: String, only_visibles = false):
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH
	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND
	return _aseprite.list_layers(file, only_visibles)


func list_tags(file: String):
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH
	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND
	return _aseprite.list_tags(file)



# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _load_tags_options_lookup(tags: Array = []):
	for t in tags:
		_tags_options_lookup[t.tag_name] = t


func _find_sprite_in_target(target_sprite: Node) -> Node:
	if not target_sprite.has_node("Sprite2D"):
		return null
	return target_sprite.get_node("Sprite2D")


func _create_animations_from_file(target_sprite: Node, player: AnimationPlayer, options: Dictionary):
	var output

	## TODO: See _aseprite.export_layer() when the time comes to add layers selection
	output = _aseprite.export_file(options.source, options.output_folder, options)

	if output.is_empty():
		return RESULT_CODE.ERR_ASEPRITE_EXPORT_FAILED

	await _scan_filesystem()

	var result = _import(target_sprite, player, output, options)

	if _config.should_remove_source_files():
		DirAccess.remove_absolute(output.data_file)
		await _scan_filesystem()

	return result

func _remove_animations_from_player(player: AnimationPlayer):
	player.remove_animation_library(_DEFAULT_AL)


func _import(target_sprite: Node, player: AnimationPlayer, data: Dictionary, options: Dictionary):
	var source_file = data.data_file
	var sprite_sheet = data.sprite_sheet

	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return file.get_open_error()

	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var content = test_json_conv.get_data()
	
	if not _aseprite.is_valid_spritesheet(content):
		return RESULT_CODE.ERR_INVALID_ASEPRITE_SPRITESHEET

	_setup_texture(target_sprite, sprite_sheet, content)
	var result = _configure_animations(target_sprite, player, content)
	if result != RESULT_CODE.SUCCESS:
		return result

	return RESULT_CODE.SUCCESS


func _load_texture(sprite_sheet: String) -> Texture2D:
	var texture = ResourceLoader.load(sprite_sheet, 'Image', ResourceLoader.CACHE_MODE_IGNORE)
	texture.take_over_path(sprite_sheet)
	return texture


func _configure_animations(target_sprite: Node, player: AnimationPlayer, content: Dictionary):
	var frames = _aseprite.get_content_frames(content)

	if not player.has_animation_library(_DEFAULT_AL):
		player.add_animation_library(_DEFAULT_AL, AnimationLibrary.new())

	if content.meta.has("frameTags") and content.meta.frameTags.size() > 0:
		var result = RESULT_CODE.SUCCESS
		for tag in content.meta.frameTags:
			if not _tags_options_lookup.get(tag.name).get("import"):
				continue
			var selected_frames = frames.slice(tag.from, tag.to+1) # slice is [)
			result = _add_animation_frames(target_sprite, player, tag.name, selected_frames, tag.direction)
			if result != RESULT_CODE.SUCCESS:
				break
		return result
	else:
		return _add_animation_frames(target_sprite, player, "default", frames)


func _add_animation_frames(target_sprite: Node, player: AnimationPlayer, anim_name: String, frames: Array, direction = 'forward'):
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
	if not player.has_animation_library(_DEFAULT_AL):
		player.add_animation_library(_DEFAULT_AL, AnimationLibrary.new())

	if not player.get_animation_library(_DEFAULT_AL).has_animation(animation_name):
		player.get_animation_library(_DEFAULT_AL).add_animation(animation_name, Animation.new())

	# Here is where animations are created.
	# TODO: we need to "fork" the logic so that Character has a single spritesheet
	# containing all tags, while Rooms/Props and Inventory Items has a single spritesheet
	# for each tag, so that you can have each prop with its own animation (PnC)
	var animation = player.get_animation(animation_name)
	_create_meta_tracks(target_sprite, player, animation)
	var frame_track = _get_property_track_path(player, target_sprite, "frame")
	var frame_track_index = _create_track(target_sprite, animation, frame_track)

	if direction == 'reverse':
		frames.reverse()

	var animation_length = 0

	for frame in frames:
		var frame_key = _get_frame_key(target_sprite, frame)
		animation.track_insert_key(frame_track_index, animation_length, frame_key)
		animation_length += frame.duration / 1000 ## NOTE: animation_length is in seconds

	if direction == 'pingpong':
		frames.remove_at(frames.size() - 1)
		if is_loopable:
			frames.remove_at(0)
		frames.reverse()

		for frame in frames:
			var frame_key = _get_frame_key(target_sprite, frame)
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


func _get_property_track_path(player: AnimationPlayer, target_sprite: Node, prop: String) -> String:
	var node_path = player.get_node(player.root_node).get_path_to(target_sprite)
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

func _setup_texture(sprite: Node, sprite_sheet: String, content: Dictionary):
	var texture = _load_texture(sprite_sheet)
	sprite.texture = texture

	if content.frames.is_empty():
		return

	sprite.hframes = content.meta.size.w / content.frames[0].sourceSize.w
	sprite.vframes = content.meta.size.h / content.frames[0].sourceSize.h


func _create_meta_tracks(sprite: Node, player: AnimationPlayer, animation: Animation):
	var texture_track = _get_property_track_path(player, sprite, "texture")
	var texture_track_index = _create_track(sprite, animation, texture_track)
	animation.track_insert_key(texture_track_index, 0, sprite.texture)

	var hframes_track = _get_property_track_path(player, sprite, "hframes")
	var hframes_track_index = _create_track(sprite, animation, hframes_track)
	animation.track_insert_key(hframes_track_index, 0, sprite.hframes)

	var vframes_track = _get_property_track_path(player, sprite, "vframes")
	var vframes_track_index = _create_track(sprite, animation, vframes_track)
	animation.track_insert_key(vframes_track_index, 0, sprite.vframes)

	var visible_track = _get_property_track_path(player, sprite, "visible")
	var visible_track_index = _create_track(sprite, animation, visible_track)
	animation.track_insert_key(visible_track_index, 0, true)

	
func _get_frame_key(sprite:  Node, frame: Dictionary):
	return _calculate_frame_index(sprite,frame)


func _calculate_frame_index(sprite: Node, frame: Dictionary) -> int:
	var column = floor(frame.frame.x * sprite.hframes / sprite.texture.get_width())
	var row = floor(frame.frame.y * sprite.vframes / sprite.texture.get_height())
	return (row * sprite.hframes) + column

