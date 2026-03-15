@tool
extends "res://addons/popochiu/editor/importers/aseprite/docks/aseprite_importer_dock.gd"

var _animation_creator = preload(\
"res://addons/popochiu/editor/importers/aseprite/animation_creator_sprite2d.gd").new()



#region Public ######################################################################################
func init():
	# Instantiate animation creator
	_animation_creator.init(_aseprite, file_system)

	super()

## Returns false for room props (no autoplay by default).
func _get_default_autoplay_behavior() -> bool:
	return false


#endregion


#region Private ####################################################################################
func _on_import_pressed() -> void:
	# Set everything up
	# This will populate _root_node and _options class variables
	super()

	var props_container = _root_node.get_node("Props")
	var result: int = RESULT_CODE.SUCCESS

	# Create a prop for each tag that must be imported
	# and populate it with the right sprite
	for tag in _options.get("tags"):
		# Ignore unwanted tags
		if not tag.import: continue
			
		# Always convert to PascalCase as a standard
		# TODO: check Godot 4 standards, I can't find info
		var prop_name: String = tag.tag_name.to_pascal_case()
		
		# In case the prop is there, use the one we already have
		var prop = props_container.get_node_or_null(prop_name)
		if prop == null:
			# Create a new prop if necessary, specifying the
			# interaction flags.
			prop = _create_prop(prop_name, tag.prop_clickable, tag.prop_visible)
		else:
			# Force flags (a bit redundant but they may have been changed
			# in the Importer interface, for already imported props)
			prop.clickable = tag.prop_clickable
			prop.visible = tag.prop_visible

		prop.set_meta("ANIM_NAME", tag.tag_name)
		prop.set_meta("ANIM_AUTOPLAY", tag.autoplays)
		
	for prop in props_container.get_children():
		if not prop.has_meta("ANIM_NAME"): continue
		
		# Make the output folder match the prop's folder
		_options.output_folder = prop.scene_file_path.get_base_dir()
		
		# Import a single tag animation
		result = await _animation_creator.create_tag_animations(
			prop,
			prop.get_meta("ANIM_NAME"),
			_options
		)

		if prop.get_meta("ANIM_AUTOPLAY", false):
			# If the item has autoplay enabled, set it up
			_animation_creator.setup_autoplay(prop.get_meta("ANIM_NAME"))
		else:
			# Otherwise, ensure autoplay animation is unset
			_animation_creator.setup_autoplay(PopochiuEditorHelper.EMPTY_STRING)

	for prop in props_container.get_children():
		if not prop.has_meta("ANIM_NAME"): continue
		# Save the prop
		result = await _save_prop(prop)

	# TODO: maybe check if this is better done with signals
	_importing = false

	if typeof(result) == TYPE_INT and result != RESULT_CODE.SUCCESS:
		PopochiuUtils.print_error(RESULT_CODE.get_error_message(result))
		_show_message("Some errors occurred. Please check output panel.", "Warning!")
	else:
		await get_tree().create_timer(0.1).timeout
		
		# Once the popup is closed, call _clean_props()
		_show_message(
			"%d animation tags processed." % [_tags_cache.size()],
			"Done!"
		)


func _customize_tag_ui(tag_row: AnimationTagRow) -> void:
	# Show props-related buttons if we are in a room
	tag_row.show_prop_buttons()


func _customize_filter_ui() -> void:
	# Show props-related buttons in the main bar if we are in a room
	%FilterSeparator.visible = true
	%VisibleBulk.visible = true
	%ClickableBulk.visible = true
	%AutoplaysBulk.visible = true


func _create_prop(name: String, is_clickable: bool = true, is_visible: bool = true):
	var factory = PopochiuPropFactory.new()
	var param := PopochiuPropFactory.PopochiuPropFactoryParam.new()
	param.obj_name = name
	param.room = _root_node
	param.is_interactive = is_clickable
	param.is_visible = is_visible
	
	if factory.create(param) != ResultCodes.SUCCESS:
		return

	return factory.get_obj_scene()

func _save_prop(prop: PopochiuProp) -> int:
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(prop)
	if ResourceSaver.save(packed_scene, prop.scene_file_path) != OK:
		PopochiuUtils.print_error(
			"Couldn't save animations for prop %s at %s" %
			[prop.name, prop.scene_file_path]
		)
		return ResultCodes.ERR_CANT_SAVE_OBJ_SCENE
	return ResultCodes.SUCCESS


func _get_scene_path_for_tag(tag_name: String) -> String:
	if not is_instance_valid(target_node) or not tag_name:
		return PopochiuEditorHelper.EMPTY_STRING

	# In a room, props are in the "Props" node
	var props_container = target_node.get_node_or_null("Props")
	if not is_instance_valid(props_container):
		PopochiuUtils.print_warning("No Props container found in room. Are you sure this is a valid room?")
		return PopochiuEditorHelper.EMPTY_STRING

	# Find the prop with the matching name (converted to PascalCase)
	var prop_name = tag_name.to_pascal_case()
	var prop = props_container.get_node_or_null(prop_name)

	if not is_instance_valid(prop):
		PopochiuUtils.print_warning("No prop named '%s' found in room. Did you import this animation?" % prop_name)
		return PopochiuEditorHelper.EMPTY_STRING

	return prop.scene_file_path


#endregion


#region Protected ##################################################################################
## Selects the animation in the room prop's AnimationPlayer.
## This involves opening the prop scene and then selecting the AnimationPlayer.
func _select_animation(tag_name: String) -> void:
	var prop_name = tag_name.to_pascal_case()
	var prop_scene_path = _get_scene_path_for_tag(tag_name)
	if prop_scene_path.is_empty():
		PopochiuUtils.print_warning("Prop '%s' does not have a scene file path. The prop may be corrupted, try to reimport it." % prop_name)
		return

	# Open the prop's scene
	EditorInterface.open_scene_from_path(prop_scene_path)

	# Wait a frame to ensure the scene is fully loaded
	await PopochiuEditorHelper.frame_processed()

	# Get the current scene root (should be the prop now)
	var prop_scene_root = EditorInterface.get_edited_scene_root()
	if not is_instance_valid(prop_scene_root):
		PopochiuUtils.print_warning("Failed to get edited scene root for prop '%s'. The prop may be corrupted, try to reimport it." % prop_name)
		return

	# Find the AnimationPlayer in the prop scene
	var animation_player = prop_scene_root.get_node_or_null("AnimationPlayer")

	_handle_animation_in_player(tag_name, animation_player, HANDLE_ANIM_SELECT)


## Removes the animation for the given tag from the room prop's AnimationPlayer.
func _delete_animation_for_tag(tag_name: String) -> void:
	var prop_name = tag_name.to_pascal_case()
	var prop_scene_path = _get_scene_path_for_tag(tag_name)
	if prop_scene_path.is_empty():
		PopochiuUtils.print_warning("Prop '%s' does not have a scene file path. The prop may be corrupted, try to reimport it." % prop_name)
		return
	
	# Load the scene without opening it in the editor
	var packed_scene = load(prop_scene_path)
	if not packed_scene:
		PopochiuUtils.print_warning("Failed to load scene for prop '%s'" % prop_name)
		return
	
	# Instance the scene to work with it in memory
	var prop_scene_root = packed_scene.instantiate()
	if not is_instance_valid(prop_scene_root):
		PopochiuUtils.print_warning("Failed to instantiate scene for prop '%s'" % prop_name)
		return
	
	# Find the AnimationPlayer in the prop scene
	var animation_player = prop_scene_root.get_node_or_null("AnimationPlayer")
	_handle_animation_in_player(tag_name, animation_player, HANDLE_ANIM_DELETE)

	PopochiuEditorHelper.pack_scene(prop_scene_root)

	# Clean up the instance
	prop_scene_root.queue_free()

#endregion
