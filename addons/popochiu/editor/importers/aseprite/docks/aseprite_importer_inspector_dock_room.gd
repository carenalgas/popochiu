@tool
extends "res://addons/popochiu/editor/importers/aseprite/docks/aseprite_importer_inspector_dock.gd"

var _animation_player_path: String
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
	# - Foreach tag
	#   - If a Prop with the tag_name.to_camel() is not availabe
	#     - Create it from scratch in the Props container
	#   - If the Prop has not a Sprite2D and an AnimationPlayer
	#     - Instantiate both
	#   - Create animation passing the Prop as the target node, and all needed params

#	var result = await _animation_creator.create_animations(target_node, root.get_node(_animation_player_path), options)
#	_importing = false
#
#	if typeof(result) == TYPE_INT and result != RESULT_CODE.SUCCESS:
#		printerr(RESULT_CODE.get_error_message(result))
#		_show_message("Some errors occurred. Please check output panel.", "Warning!")
#	else:
#		_show_message("%d animation tags processed." % [_tags_cache.size()], "Done!")


func _customize_tag_ui(tag_row: AnimationTagRow):
	# Show props-related buttons if we are in a room
	tag_row.show_prop_buttons()
