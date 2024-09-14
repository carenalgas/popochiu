@tool
extends "res://addons/popochiu/editor/importers/aseprite/docks/aseprite_importer_inspector_dock.gd"

var _animation_creator = preload(\
"res://addons/popochiu/editor/importers/aseprite/animation_creator.gd").new()


#region Godot ######################################################################################
func _ready():
	# Instantiate animation creator
	_animation_creator.init(_aseprite, file_system)

	super()


#endregion

#region Private ####################################################################################
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
		
	for prop in props_container.get_children():
		if not prop.has_meta("ANIM_NAME"): continue
		# TODO: check if animation player exists in prop, if not add it
		#       same for Sprite2D even if it should be there...
		
		# Make the output folder match the prop's folder
		_options.output_folder = prop.scene_file_path.get_base_dir()
		
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
		PopochiuUtils.print_error(RESULT_CODE.get_error_message(result))
		_show_message("Some errors occurred. Please check output panel.", "Warning!")
	else:
		await get_tree().create_timer(0.1).timeout
		
		# Once the popup is closed, call _clean_props()
		_show_message(
			"%d animation tags processed." % [_tags_cache.size()],
			"Done!"
		)


func _customize_tag_ui(tag_row: AnimationTagRow):
	# Show props-related buttons if we are in a room
	tag_row.show_prop_buttons()


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

func _save_prop(prop: PopochiuProp):
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(prop)
	if ResourceSaver.save(packed_scene, prop.scene_file_path) != OK:
		PopochiuUtils.print_error(
			"Couldn't save animations for prop %s at %s" %
			[prop.name, prop.scene_file_path]
		)
		return ResultCodes.ERR_CANT_SAVE_OBJ_SCENE
	return ResultCodes.SUCCESS


#endregion
