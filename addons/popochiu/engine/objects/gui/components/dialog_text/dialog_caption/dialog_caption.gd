# @popochiu-docs-ignore-class
extends PopochiuDialogText


#region Private ####################################################################################
func _modify_size(msg: String, _target_position: Vector2) -> void:
	var calc_size := await _calculate_size(msg)
	
	# Define size and position (before calculating overflow)
	rich_text_label.size = calc_size
	# Fix #360: Calculate the size of the RichTextLabel accordingly
	rich_text_label.position.x = get_viewport_rect().size.x / 2.0 - rich_text_label.size.x / 2.0
	rich_text_label.position.y = (
		get_meta(DFLT_POSITION).y - (rich_text_label.size.y - get_meta(DFLT_SIZE).y)
	)


func _append_text(msg: String, props: Dictionary) -> void:
	# Fix #360: The color is already set in the [msg] parameter
	rich_text_label.text = "[center]%s[/center]" % msg


#endregion
