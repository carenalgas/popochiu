extends PopochiuDialogText


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	continue_icon.hide()


#endregion

#region Virtual ####################################################################################
func _modify_size(msg: String, target_position: Vector2) -> void:
	var _size := await _calculate_size(msg)
	
	# Define size and position (before calculating overflow)
	rich_text_label.size = _size
	rich_text_label.position = target_position - size / 2.0
	rich_text_label.position.y -= size.y / 2.0

	# Calculate overflow and reposition
	if rich_text_label.position.x < 0.0:
		rich_text_label.position.x = limit_margin
	elif rich_text_label.position.x + rich_text_label.size.x > _x_limit:
		rich_text_label.position.x = _x_limit - limit_margin - rich_text_label.size.x
	if rich_text_label.position.y < 0.0:
		rich_text_label.position.y = limit_margin
	elif rich_text_label.position.y + rich_text_label.size.y > _y_limit:
		rich_text_label.position.y = _y_limit - limit_margin - rich_text_label.size.y


#endregion

#region Public #####################################################################################
func disappear() -> void:
	super()
	
	continue_icon.hide()
	continue_icon.modulate.a = 1.0
	
	if is_instance_valid(continue_icon_tween) and continue_icon_tween.is_running():
		continue_icon_tween.kill()


#endregion

#region Private ####################################################################################
func _set_default_label_size(lbl: Label) -> void:
	lbl.size.y = get_meta(DFLT_SIZE).y


func _append_text(msg: String, props: Dictionary) -> void:
	var center := floor(position.x + (size.x / 2))
	if center == props.position.x:
		rich_text_label.append_text("[center]%s[/center]" % msg)
	elif center < props.position.x:
		rich_text_label.append_text("[right]%s[/right]" % msg)
	else:
		rich_text_label.append_text(msg)


func _get_icon_from_position() -> float:
	return size.y / 2.0 - 1.0


func _get_icon_to_position() -> float:
	return size.y / 2.0 + 3.0


#endregion
