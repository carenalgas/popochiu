@tool
extends "res://addons/popochiu/editor/importers/aseprite/docks/aseprite_importer_dock.gd"

var _animation_creator = preload(
	"res://addons/popochiu/editor/importers/aseprite/animation_creator_sprite2d.gd"
).new()


#region Public ######################################################################################
func init():
	# Instantiate animation creator
	_animation_creator.init(_aseprite, file_system)

	super()

## Returns false for characters (no autoplay by default).
func _get_default_autoplay_behavior() -> bool:
	return false


#endregion


#region Private ####################################################################################
func _on_import_pressed():
	# Set everything up
	# This will populate _root_node and _options class variables
	super()
	
	var result = await _animation_creator.create_all_animations(
		target_node, _options
	)
	_importing = false

	if typeof(result) == TYPE_INT and result != RESULT_CODE.SUCCESS:
		PopochiuUtils.print_error(RESULT_CODE.get_error_message(result))
		_show_message("Some errors occurred. Please check output panel.", "Warning!")
	else:
		_show_message("%d animation tags processed." % [_tags_cache.size()], "Done!")


func _customize_tag_ui(tag_row: AnimationTagRow):
	pass

## Returns true for characters as they typically use looping animations.
func _get_default_loop_behavior() -> bool:
	return true


# Exclusive autoplay logic for character animations.
func _on_autoplay_toggle_pressed(selected_row: AnimationTagRow):
	pass


#endregion


#region Protected ##################################################################################
## Selects the animation in the character's AnimationPlayer.
func _select_animation(tag_name: String) -> void:
	if not is_instance_valid(target_node) or not tag_name:
		return
	
	# Character scenes already have the AnimationPlayer as a direct child
	var animation_player = target_node.get_node_or_null("AnimationPlayer")
	if not is_instance_valid(animation_player):
		PopochiuUtils.print_warning("No AnimationPlayer found in character node")
		return
	
	# Select the AnimationPlayer node in the editor
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(animation_player)
	
	# Find the animation by tag name (converting to snake_case as that's how animations are named)
	var animation_name = tag_name.to_snake_case()
	if animation_player.has_animation(animation_name):
		# Set the animation as the current one in the AnimationPlayer
		animation_player.assigned_animation = animation_name
	else:
		PopochiuUtils.print_warning("No animation named '%s' found in character's AnimationPlayer" % animation_name)

#endregion
