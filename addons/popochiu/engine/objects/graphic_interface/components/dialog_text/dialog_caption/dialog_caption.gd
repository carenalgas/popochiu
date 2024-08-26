extends PopochiuDialogText


#region Virtual ####################################################################################
func _modify_size(msg: String, target_position: Vector2) -> void:
	var _size := await _calculate_size(msg)
	
	# Define size and position (before calculating overflow)
	rich_text_label.size.y = _size.y
	rich_text_label.position.y = get_meta(DFLT_POSITION).y - (_size.y - get_meta(DFLT_SIZE).y)


#endregion

#region Private ####################################################################################
func _append_text(msg: String, props: Dictionary) -> void:
	rich_text_label.text = "[center][color=%s]%s[/color][/center]" % [props.color.to_html(), msg]


#endregion
