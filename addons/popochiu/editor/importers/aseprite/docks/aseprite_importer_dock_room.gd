@tool
extends "res://addons/popochiu/editor/importers/aseprite/docks/aseprite_importer_dock.gd"

var _animation_creator := preload(\
"res://addons/popochiu/editor/importers/aseprite/animation_creator_sprite2d.gd").new()



#region Public ######################################################################################
func init() -> void:
	# Instantiate animation creator
	_animation_creator.init(_aseprite, file_system)

	super()

# Returns false for room props (no autoplay by default).
func _get_default_autoplay_behavior() -> bool:
	return false


# The room importer supports "group tags": one prop with several animations.
func _supports_groups() -> bool:
	return true


#endregion


#region Private ####################################################################################
func _on_import_pressed() -> void:
	# Set everything up
	# This will populate _root_node and _options class variables
	super()

	var props_container := _root_node.get_node("Props")
	var result: int = RESULT_CODE.SUCCESS

	var grouper := PopochiuAsepriteTagGrouper.new()
	var analysis := grouper.analyze(_options.get("tags"))

	# Build a lookup of the tag configurations (with user toggles) by name
	var tags_by_name := {}
	for tag in _options.get("tags"):
		tags_by_name[tag.tag_name] = tag

	# Track the tags that are actually imported in this run, so that props whose
	# source tag was removed or whose group became invalid are not re-imported
	# from stale metadata.
	var importable_names := {}

	# Create a prop for each group and each single tag that must be imported,
	# and populate it with the right sprite.
	for group in analysis.get("groups", []):
		# Misconfigured groups are skipped entirely and reported at the end
		if not group.get("is_valid", true):
			continue

		var group_cfg: Dictionary = tags_by_name.get(group.name, {})
		if not group_cfg.get("import", true):
			continue

		# Only keep the children the user wants to import as animations
		var children := []
		for child in group.get("children", []):
			var child_cfg: Dictionary = tags_by_name.get(child.tag_name, {})
			if not child_cfg.get("import", true):
				continue
			var child_import: Dictionary = child.duplicate()
			child_import.loops = child_cfg.get("loops", false)
			child_import.autoplays = child_cfg.get("autoplays", false)
			children.push_back(child_import)

		# No animation to import for this group: don't create the prop
		if children.is_empty():
			continue

		# Always convert to PascalCase as a standard
		# TODO: check Godot 4 standards, I can't find info
		var prop_name: String = group.name.to_pascal_case()

		# In case the prop is there, use the one we already have
		var prop: PopochiuProp = props_container.get_node_or_null(prop_name)
		if prop == null:
			# Create a new prop if necessary, specifying the interaction flags.
			prop = _create_prop(
				prop_name,
				group_cfg.get("prop_clickable", true),
				group_cfg.get("prop_visible", true)
			)
		else:
			# Force flags (a bit redundant but they may have been changed
			# in the Importer interface, for already imported props)
			prop.clickable = group_cfg.get("prop_clickable", true)
			prop.visible = group_cfg.get("prop_visible", true)

		var group_import: Dictionary = group.duplicate()
		group_import.children = children
		prop.set_meta("ANIM_NAME", group.name)
		prop.set_meta("ANIM_GROUP", group_import)
		importable_names[group.name] = true

	for tag in analysis.get("singles", []):
		# Ignore unwanted tags
		if not tag.get("import", true): continue

		# Always convert to PascalCase as a standard
		# TODO: check Godot 4 standards, I can't find info
		var prop_name: String = tag.tag_name.to_pascal_case()

		# In case the prop is there, use the one we already have
		var prop: PopochiuProp = props_container.get_node_or_null(prop_name)
		if prop == null:
			# Create a new prop if necessary, specifying the interaction flags.
			prop = _create_prop(
				prop_name,
				tag.get("prop_clickable", true),
				tag.get("prop_visible", true)
			)
		else:
			# Force flags (a bit redundant but they may have been changed
			# in the Importer interface, for already imported props)
			prop.clickable = tag.get("prop_clickable", true)
			prop.visible = tag.get("prop_visible", true)

		prop.set_meta("ANIM_NAME", tag.tag_name)
		prop.set_meta("ANIM_AUTOPLAY", tag.get("autoplays", false))
		prop.set_meta("ANIM_GROUP", {})
		importable_names[tag.tag_name] = true

	for prop in props_container.get_children():
		if not prop.has_meta("ANIM_NAME"): continue

		# Skip props whose source tag is no longer importable in this run
		# (the tag was removed from the file or its group became invalid)
		if not importable_names.has(prop.get_meta("ANIM_NAME", "")):
			prop.remove_meta("ANIM_NAME")
			prop.remove_meta("ANIM_AUTOPLAY")
			prop.remove_meta("ANIM_GROUP")
			continue

		# Make the output folder match the prop's folder
		_options.output_folder = prop.scene_file_path.get_base_dir()

		var group_meta: Dictionary = prop.get_meta("ANIM_GROUP", {})
		if not group_meta.is_empty() and not group_meta.get("children", []).is_empty():
			# Import the group as a single prop with several animations
			result = await _animation_creator.create_group_animations(prop, group_meta, _options)

			# Only one child can autoplay per group (enforced by the UI)
			_animation_creator.setup_autoplay(
				_get_autoplay_child(group_meta.get("children", []))
			)
		else:
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
		# If autotrace is enabled, trace the interaction polygon from the sprite's alpha channel
		# before packing the scene, so the polygon is included in the saved resource.
		if %AutotracePolygonsCheckButton.is_pressed():
			PopochiuPolygonsHelper.trace_interaction_polygon_direct(prop)

	for prop in props_container.get_children():
		if not prop.has_meta("ANIM_NAME"): continue
		# Save the prop
		result = await _save_prop(prop)

	# TODO: maybe check if this is better done with signals
	_importing = false

	var has_errors := typeof(result) == TYPE_INT and result != RESULT_CODE.SUCCESS
	var group_errors := _get_group_errors(analysis)

	if has_errors:
		PopochiuUtils.print_error(RESULT_CODE.get_error_message(result))

	for group_error in group_errors:
		PopochiuUtils.print_error(group_error)

	for group_warning in analysis.get("warnings", []):
		PopochiuUtils.print_warning(group_warning)

	if has_errors or not group_errors.is_empty():
		_show_message("Some errors occurred. Please check output panel.", "Warning!")
	else:
		await get_tree().create_timer(0.1).timeout

		# Once the popup is closed, call _clean_props()
		_show_message(
			"%d animation tags processed." % [_tags_cache.size()],
			"Done!"
		)


# Returns the animation name of the single child that should autoplay (the first
# one with the autoplay toggle on), or an empty string when none is set.
func _get_autoplay_child(children: Array) -> String:
	for child in children:
		if child.get("autoplays", false):
			return child.get("anim_name", "")
	return PopochiuEditorHelper.EMPTY_STRING


# Builds the actionable error messages for misconfigured groups, so they can be
# printed to the Output panel.
func _get_group_errors(analysis: Dictionary) -> Array:
	var errors := []
	for group in analysis.get("groups", []):
		if not group.get("is_valid", true):
			var message: String = group.get("error", "")
			if not message.is_empty():
				errors.push_back("Aseprite importer: Group '%s': %s" % [group.get("name", ""), message])

	if not errors.is_empty():
		errors.push_back(
			"Aseprite importer: no prop was created for the misconfigured group(s) above. "
			+ "Fix the Aseprite file: remove the group tag (its tags will be imported as separate props) "
			+ "or rename the contained tags so they start with the group name."
		)
	return errors


func _customize_tag_ui(tag_row: AnimationTagRow) -> void:
	# Show props-related buttons if we are in a room
	tag_row.show_prop_buttons()


func _customize_filter_ui() -> void:
	# Show props-related buttons in the main bar if we are in a room
	%FilterSeparator.visible = true
	%VisibleBulk.visible = true
	%ClickableBulk.visible = true
	%AutoplaysBulk.visible = true
	%AutotracePolygons.visible = true


func _create_prop(name: String, is_clickable: bool = true, is_visible: bool = true) -> PopochiuProp:
	var factory := PopochiuPropFactory.new()
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


func _get_scene_path_for_prop(prop_name: String) -> String:
	if not is_instance_valid(target_node) or not prop_name:
		return PopochiuEditorHelper.EMPTY_STRING

	# In a room, props are in the "Props" node
	var props_container := target_node.get_node_or_null("Props")
	if not is_instance_valid(props_container):
		PopochiuUtils.print_warning("No Props container found in room. Are you sure this is a valid room?")
		return PopochiuEditorHelper.EMPTY_STRING

	# Find the prop with the matching name
	var prop: PopochiuProp = props_container.get_node_or_null(prop_name)

	if not is_instance_valid(prop):
		PopochiuUtils.print_warning("No prop named '%s' found in room. Did you import this animation?" % prop_name)
		return PopochiuEditorHelper.EMPTY_STRING

	return prop.scene_file_path


#endregion


#region Protected ##################################################################################
# Returns the group info for a tag that is a child of a group, or an empty
# dictionary when the tag is a standalone animation.
func _get_group_anim_info(tag_name: String) -> Dictionary:
	var grouper := PopochiuAsepriteTagGrouper.new()
	var analysis := grouper.analyze(_tags_cache)
	for group in analysis.get("groups", []):
		for child in group.get("children", []):
			if child.tag_name == tag_name:
				return { "group_name": group.name, "anim_name": child.anim_name }
	return {}


# Selects the animation in the room prop's AnimationPlayer.
# This involves opening the prop scene and then selecting the AnimationPlayer.
func _select_animation(tag_name: String) -> void:
	var group_info := _get_group_anim_info(tag_name)
	var prop_name: String = group_info.get("group_name", tag_name).to_pascal_case()
	var anim_name: String = group_info.get("anim_name", tag_name)

	var prop_scene_path := _get_scene_path_for_prop(prop_name)
	if prop_scene_path.is_empty():
		PopochiuUtils.print_warning("Prop '%s' does not have a scene file path. The prop may be corrupted, try to reimport it." % prop_name)
		return

	# Open the prop's scene
	EditorInterface.open_scene_from_path(prop_scene_path)

	# Wait a frame to ensure the scene is fully loaded
	await PopochiuEditorHelper.frame_processed()

	# Get the current scene root (should be the prop now)
	var prop_scene_root: Node = EditorInterface.get_edited_scene_root()
	if not is_instance_valid(prop_scene_root):
		PopochiuUtils.print_warning("Failed to get edited scene root for prop '%s'. The prop may be corrupted, try to reimport it." % prop_name)
		return

	# Find the AnimationPlayer in the prop scene
	var animation_player: AnimationPlayer = prop_scene_root.get_node_or_null("AnimationPlayer")

	_handle_animation_in_player(anim_name, animation_player, HANDLE_ANIM_SELECT)


# Removes the animation for the given tag from the room prop's AnimationPlayer.
func _delete_animation_for_tag(tag_name: String) -> void:
	var group_info := _get_group_anim_info(tag_name)
	var prop_name: String = group_info.get("group_name", tag_name).to_pascal_case()
	var anim_name: String = group_info.get("anim_name", tag_name)

	var prop_scene_path := _get_scene_path_for_prop(prop_name)
	if prop_scene_path.is_empty():
		PopochiuUtils.print_warning("Prop '%s' does not have a scene file path. The prop may be corrupted, try to reimport it." % prop_name)
		return
	
	# Load the scene without opening it in the editor
	var packed_scene: PackedScene = load(prop_scene_path)
	if not packed_scene:
		PopochiuUtils.print_warning("Failed to load scene for prop '%s'" % prop_name)
		return
	
	# Instance the scene to work with it in memory
	var prop_scene_root: Node = packed_scene.instantiate()
	if not is_instance_valid(prop_scene_root):
		PopochiuUtils.print_warning("Failed to instantiate scene for prop '%s'" % prop_name)
		return
	
	# Find the AnimationPlayer in the prop scene
	var animation_player: AnimationPlayer = prop_scene_root.get_node_or_null("AnimationPlayer")
	_handle_animation_in_player(anim_name, animation_player, HANDLE_ANIM_DELETE)

	PopochiuEditorHelper.pack_scene(prop_scene_root)

	# Clean up the instance
	prop_scene_root.queue_free()

#endregion
