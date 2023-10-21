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
	var prop: PopochiuProp = null
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
		prop = props_container.get_node_or_null(prop_name)
		if prop == null:
			# TODO: Add "prop visibility" parameter to the create method in the factory
			#       currently all props are created visible.
			prop = await _create_prop(prop_name, tag.prop_clickable)
		
		# TODO: check if animation player exists in prop, if not add it
		#       same for Sprite2D even if it should be there...

		# Import a single tag animation
		result = await _animation_creator.create_prop_animations(
			prop,
			tag.tag_name, # original name
			_options
		)

		# Save the prop scene after adding that stuff
		var packed_scene: PackedScene = PackedScene.new()
		packed_scene.pack(prop)
		if ResourceSaver.save(packed_scene, prop.scene_file_path) != OK:
			push_error(
				"[Popochiu] Couldn't save animations for prop %s at %s" %
				[prop.name, prop.scene_file_path]
			)
			result = ResultCodes.ERR_CANT_SAVE_OBJ_SCENE

		# TODO: maybe check if this is better done with signals
		_importing = false

		prop = null

	if typeof(result) == TYPE_INT and result != RESULT_CODE.SUCCESS:
		printerr(RESULT_CODE.get_error_message(result))
		_show_message("Some errors occurred. Please check output panel.", "Warning!")
	else:
		_show_message("%d animation tags processed." % [_tags_cache.size()], "Done!")



func _customize_tag_ui(tag_row: AnimationTagRow):
	# Show props-related buttons if we are in a room
	tag_row.show_prop_buttons()


func _create_prop(name: String, visible: bool = true, clickable: bool = true):
	var factory = PopochiuPropFactory.new(main_dock)

	if factory.create(name, _root_node, clickable) != ResultCodes.SUCCESS:
		return

	return factory.get_obj_scene()
