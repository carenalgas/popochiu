# This logic has been taken almost as-is from Vinicius Gerevini's
# Aseprite Wizard plugin. Credits goes to him for the real magic.
# See: https://godotengine.org/asset-library/asset/713
extends Reference

var result_code = preload("./config/result_codes.gd")
var _aseprite = preload("./aseprite_controller.gd").new()

var _config
var _file_system

var _tags_options_lookup = {}

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░

func init(config, editor_file_system: EditorFileSystem = null):
	_config = config
	_file_system = editor_file_system
	_aseprite.init(config)


func create_animations(target_node: Node, player: AnimationPlayer, options: Dictionary):
	if not _aseprite.test_command():
		return result_code.ERR_ASEPRITE_CMD_NOT_FOUND

	var dir = Directory.new()
	if not dir.file_exists(options.source):
		return result_code.ERR_SOURCE_FILE_NOT_FOUND

	if not dir.dir_exists(options.output_folder):
		return result_code.ERR_OUTPUT_FOLDER_NOT_FOUND

	var target_sprite = _find_sprite_in_target(target_node)

	if target_sprite == null:
		return result_code.ERR_NO_SPRITE_FOUND
	
	if typeof(options.get("tags")) != TYPE_ARRAY:
		return result_code.ERR_TAGS_OPTIONS_ARRAY_EMPTY
		
	_load_tags_options_lookup(options.get("tags"))

	if (options.wipe_old_animations):
		_remove_animations_from_player(player)
	
	var result = _create_animations_from_file(target_sprite, player, options)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")

	if result != result_code.SUCCESS:
		printerr(result_code.get_error_message(result))


## TODO: Keep this as reference to populate a checkable list of layers
func list_layers(file: String, only_visibles = false) -> Array:
	return _aseprite.list_layers(file, only_visibles)


func list_tags(file: String) -> Array:
	return _aseprite.list_tags(file)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _load_tags_options_lookup(tags: Array = []):
	for t in tags:
		_tags_options_lookup[t.tag_name] = t


func _find_sprite_in_target(target_sprite: Node) -> Node:
	if not target_sprite.has_node("Sprite"):
		return null
	return target_sprite.get_node("Sprite")


func _create_animations_from_file(target_sprite: Node, player: AnimationPlayer, options: Dictionary):
	var output

	## TODO: See _aseprite.export_layer() when the time comes to add layers selection
	output = _aseprite.export_file(options.source, options.output_folder, options)

	if output.empty():
		return result_code.ERR_ASEPRITE_EXPORT_FAILED

	yield(_scan_filesystem(), "completed")

	var result = _import(target_sprite, player, output, options)

	if _config.should_remove_source_files():
		var dir = Directory.new()
		dir.remove(output.data_file)

	return result

func _remove_animations_from_player(player):
	var animations = player.get_animation_list()
	for a in animations:
		if player.has_animation(a):
			player.remove_animation(a)


func _import(target_sprite: Node, player: AnimationPlayer, data: Dictionary, options: Dictionary):
	var source_file = data.data_file
	var sprite_sheet = data.sprite_sheet

	var file = File.new()
	var err = file.open(source_file, File.READ)
	if err != OK:
		return err

	var content = parse_json(file.get_as_text())
	
	if not _aseprite.is_valid_spritesheet(content):
		return result_code.ERR_INVALID_ASEPRITE_SPRITESHEET

	_setup_texture(target_sprite, sprite_sheet, content)
	var result = _configure_animations(target_sprite, player, content)
	if result != result_code.SUCCESS:
		return result

	return result_code.SUCCESS


func _load_texture(sprite_sheet: String) -> Texture:
	var texture = ResourceLoader.load(sprite_sheet, 'Image', true)
	texture.take_over_path(sprite_sheet)
	return texture


func _configure_animations(target_sprite: Node, player: AnimationPlayer, content: Dictionary):
	var frames = _aseprite.get_content_frames(content)
	if content.meta.has("frameTags") and content.meta.frameTags.size() > 0:
		var result = result_code.SUCCESS
		for tag in content.meta.frameTags:
			if not _tags_options_lookup.get(tag.name).get("import"):
				continue
			var selected_frames = frames.slice(tag.from, tag.to)
			result = _add_animation_frames(target_sprite, player, tag.name, selected_frames, tag.direction)
			result = result_code.SUCCESS
			if result != result_code.SUCCESS:
				break
		return result
	else:
		return _add_animation_frames(target_sprite, player, "default", frames)


func _add_animation_frames(target_sprite: Node, player: AnimationPlayer, anim_name: String, frames: Array, direction = 'forward'):
	var animation_name = anim_name
	var is_loopable = _tags_options_lookup.get(anim_name).get("loops")

	# TODO: This is not getting rid of old animations! We can add an option for that
	if not player.has_animation(animation_name):
		player.add_animation(animation_name, Animation.new())

	# Here is where animations are created.
	# TODO: we need to "fork" the logic so that Character has a single spritesheet
	# containing all tags, while Rooms/Props and Inventory Items has a single spritesheet
	# for each tag, so that you can have each prop with its own animation (PnC)
	var animation = player.get_animation(animation_name)
	_create_meta_tracks(target_sprite, player, animation)
	var frame_track = _get_property_track_path(player, target_sprite, "frame")
	var frame_track_index = _create_track(target_sprite, animation, frame_track)

	if direction == 'reverse':
		frames.invert()

	var animation_length = 0

	for frame in frames:
		var frame_key = _get_frame_key(target_sprite, frame)
		animation.track_insert_key(frame_track_index, animation_length, frame_key)
		animation_length += frame.duration / 1000 ## NOTE: animation_length is in seconds

	if direction == 'pingpong':
		frames.remove(frames.size() - 1)
		if is_loopable:
			frames.remove(0)
		frames.invert()

		for frame in frames:
			var frame_key = _get_frame_key(target_sprite, frame)
			animation.track_insert_key(frame_track_index, animation_length, frame_key)
			animation_length += frame.duration / 1000

	animation.length = animation_length
	animation.loop = is_loopable

	return result_code.SUCCESS


func _create_track(target_sprite: Node, animation: Animation, track: String):
	var track_index = animation.find_track(track)

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
	yield(_file_system, "filesystem_changed")


func _remove_properties_from_path(path: NodePath) -> NodePath:
	var string_path := path as String
	if !(":" in string_path):
		return string_path as NodePath

	var property_path := path.get_concatenated_subnames() as String
	string_path.erase((string_path).length() - property_path.length() - 1, property_path.length() + 1)
	return string_path as NodePath



# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SPRITE NODE LOGIC ░░░░
# What follow is logic specifically gathered for Sprite elements. TextureRect should 
# be treated in a different way (see texture_rect_animation_creator.gd file in
# original Aseprite Wizard plugin by Vinicius Gerevini)

func _setup_texture(sprite: Node, sprite_sheet: String, content: Dictionary):
	var texture = _load_texture(sprite_sheet)
	sprite.texture = texture

	if content.frames.empty():
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

