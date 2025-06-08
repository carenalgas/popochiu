@tool
extends "res://addons/popochiu/editor/importers/aseprite/docks/aseprite_importer_inspector_dock.gd"

var _animation_creator = preload(
	"res://addons/popochiu/editor/importers/aseprite/animation_creator.gd"
).new()


#region Public ######################################################################################
func init():
	# Instantiate animation creator
	_animation_creator.init(_aseprite, file_system)

	super()


#endregion


#region Private ####################################################################################
func _on_import_pressed():
	# Set everything up
	# This will populate _root_node and _options class variables
	super()
	
	var result = await _animation_creator.create_character_animations(
		target_node, _options
	)
	_importing = false

	if typeof(result) == TYPE_INT and result != RESULT_CODE.SUCCESS:
		PopochiuUtils.print_error(RESULT_CODE.get_error_message(result))
		_show_message("Some errors occurred. Please check output panel.", "Warning!")
	else:
		_show_message("%d animation tags processed." % [_tags_cache.size()], "Done!")


func _customize_tag_ui(tag_row: AnimationTagRow):
	# Nothing special has to be done for Character tags
	pass


#endregion
