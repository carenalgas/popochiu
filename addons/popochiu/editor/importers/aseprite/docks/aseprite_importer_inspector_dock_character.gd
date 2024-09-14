@tool
extends "res://addons/popochiu/editor/importers/aseprite/docks/aseprite_importer_inspector_dock.gd"

var _animation_player_path: String
var _animation_creator = preload(
	"res://addons/popochiu/editor/importers/aseprite/animation_creator.gd"
).new()

#region Godot ######################################################################################
func _ready():
	if not target_node.has_node("AnimationPlayer"):
		PopochiuUtils.print_error(
			RESULT_CODE.get_error_message(RESULT_CODE.ERR_NO_ANIMATION_PLAYER_FOUND)
		)
		return

	_animation_player_path = target_node.get_node("AnimationPlayer").get_path()

	# Instantiate animation creator
	_animation_creator.init(_aseprite, file_system)

	super()


#endregion

#region Private ####################################################################################
func _on_import_pressed():
	# Set everything up
	# This will populate _root_node and _options class variables
	super()
	
	if _animation_player_path == "" or not _root_node.has_node(_animation_player_path):
		_show_message("AnimationPlayer not found")
		_importing = false
		return
	
	var result = await _animation_creator.create_character_animations(
		target_node, _root_node.get_node(_animation_player_path), _options
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
