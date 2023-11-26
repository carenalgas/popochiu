@tool
extends "res://addons/popochiu/editor/importers/aseprite/docks/aseprite_importer_inspector_dock.gd"

var _animation_creator = preload("res://addons/popochiu/editor/importers/aseprite/animation_creator.gd").new()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	# Instantiate animation creator
	_animation_creator.init(config, _aseprite, file_system)

	super()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _on_import_pressed():
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
		var prop_name = tag.tag_name.to_pascal_case()
		
		# In case the prop is there, use the one we already have
		var prop = props_container.get_node_or_null(prop_name)
		if prop == null:
			prop = _create_prop(prop_name, tag.prop_clickable, tag.prop_visible)

		prop.set_meta("ANIM_NAME", tag.tag_name)
		
	for prop in props_container.get_children():
		if not prop.has_meta("ANIM_NAME"): continue
		# TODO: check if animation player exists in prop, if not add it
		#       same for Sprite2D even if it should be there...
		# Import a single tag animation
		result = await _animation_creator.create_prop_animations(
			prop,
			prop.get_meta("ANIM_NAME"),
			_options
		)
	
	for prop in props_container.get_children():
		if not prop.has_meta("ANIM_NAME"): continue
		# Save the prop
		result = await _save_prop(prop)

	# TODO: maybe check if this is better done with signals
	_importing = false

	if typeof(result) == TYPE_INT and result != RESULT_CODE.SUCCESS:
		printerr(RESULT_CODE.get_error_message(result))
		_show_message("Some errors occurred. Please check output panel.", "Warning!")
	else:
		await get_tree().create_timer(0.1).timeout
		_show_message("%d animation tags processed." % [_tags_cache.size()], "Done!")


func _customize_tag_ui(tag_row: AnimationTagRow):
	# Show props-related buttons if we are in a room
	tag_row.show_prop_buttons()


func _create_prop(name: String, is_clickable: bool = true, is_visible: bool = true):
	var factory = PopochiuPropFactory.new(main_dock)
	if factory.create(name, _root_node, is_clickable, is_visible) != ResultCodes.SUCCESS:
		return

	return factory.get_obj_scene()

func _save_prop(prop: PopochiuProp):
	var packed_scene: PackedScene = PackedScene.new()

	# FIXME
	# IMPROVE This function contains a workaround for Godot's GH-81982
	# this is probably not needed if they fix an unwanted behavior in
	# Godot 4.1. See comments below to get rid of the WA as soon as possible.

	# Working around a Godot 4.1 problem with not-owned children
	# See:
	# - https://github.com/godotengine/godot/issues/81982
	# - https://ask.godotengine.org/35684/packedscene-errore-is_a_parent_of-pnode-is-true
	var not_owned_children = []
	for child in prop.get_children():
		if child.owner == prop: continue
		# This node is not owned by the prop
		not_owned_children.append(child)
		# Unparent the offending node
		child.get_parent().remove_child(child)

	# Saving the prop in a sane way
	packed_scene.pack(prop)
	if ResourceSaver.save(packed_scene, prop.scene_file_path) != OK:
		push_error(
			"[Popochiu] Couldn't save animations for prop %s at %s" %
			[prop.name, prop.scene_file_path]
		)
		return ResultCodes.ERR_CANT_SAVE_OBJ_SCENE

	# Working around a Godot 4.1 problem with not-owned children
	# See:
	# - https://github.com/godotengine/godot/issues/81982
	# - https://ask.godotengine.org/35684/packedscene-errore-is_a_parent_of-pnode-is-true
	for child in not_owned_children:
		# Unparent the offending node
		prop.add_child(child)

	return ResultCodes.SUCCESS
