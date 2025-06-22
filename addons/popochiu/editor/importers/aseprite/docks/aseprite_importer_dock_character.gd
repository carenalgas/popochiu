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
	# Connect the autoplay toggle for exclusive selection logic.
	tag_row.autoplays_toggle.pressed.connect(
		func():
			_on_autoplay_toggle_pressed(tag_row)
	)

## Returns true for characters as they typically use looping animations.
func _get_default_loop_behavior() -> bool:
	return true


# Exclusive autoplay logic for character animations.
func _on_autoplay_toggle_pressed(selected_row: AnimationTagRow):
	var toggle_on = selected_row.autoplays_toggle.button_pressed

	# Turn off all other autoplay toggles.
	for row in %Tags.get_children():
		if row != selected_row:
			row.autoplays_toggle.set_pressed_no_signal(false)

	# Turn on the selected toggle, if it was off.
	selected_row.autoplays_toggle.set_pressed_no_signal(toggle_on)

	# Save config after change.
	_save_config()


#endregion
