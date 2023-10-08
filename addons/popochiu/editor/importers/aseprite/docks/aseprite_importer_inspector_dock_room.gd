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
	
	# TODO: Here we have to
	# - Foreach options.get("tags")
	#   - If a Prop named `tag_name.to_camel()` is not availabe
	#     - Create it from scratch in the Props container (invoke the factory)
	#   - If the Prop has not a Sprite2D and an AnimationPlayer
	#     - Instantiate both
	#   - Create animation passing the Prop as the target node, and all needed params
	#   NOTE: THIS REQUIRE TO EXPORT TAGS INSTEAD OF THE ENTIRE FILE.
	#         I must extend the signature of create_animations specifying a tag or a range
	#         or do a create animations for tag or whatever...

	var props_container = _root_node.get_node("Props")
	var prop: PopochiuProp = null
	
	for tag in _options.get("tags"):
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
		var result = await _animation_creator.create_character_animations(
			prop,
			prop.get_node("AnimationPlayer"),
			_options
		)
		# TODO: maybe check if this is better done with signals
		_importing = false

		if typeof(result) == TYPE_INT and result != RESULT_CODE.SUCCESS:
			printerr(RESULT_CODE.get_error_message(result))
			_show_message("Some errors occurred. Please check output panel.", "Warning!")
		else:
			_show_message("%d animation tags processed." % [_tags_cache.size()], "Done!")
		
		prop = null


func _customize_tag_ui(tag_row: AnimationTagRow):
	# Show props-related buttons if we are in a room
	tag_row.show_prop_buttons()


func _create_prop(name: String, visible: bool = true, clickable: bool = true):
	var factory = PopochiuPropFactory.new(main_dock)

	if factory.create(name, _root_node, clickable) != ResultCodes.SUCCESS:
		return

	return factory.get_obj_scene()
