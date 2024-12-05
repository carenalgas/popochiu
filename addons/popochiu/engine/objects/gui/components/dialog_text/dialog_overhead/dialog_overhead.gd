extends PopochiuDialogText


#region Private ####################################################################################
func _modify_size(msg: String, target_position: Vector2) -> void:
	var _size := await _calculate_size(msg)
	# Define size and position (before calculating overflow)
	rich_text_label.size = _size
	rich_text_label.position = target_position - rich_text_label.size / 2.0
	rich_text_label.position.y -= rich_text_label.size.y / 2.0
	# Calculate overflow and reposition
	if rich_text_label.position.x < 0.0:
		rich_text_label.position.x = limit_margin
	elif rich_text_label.position.x + rich_text_label.size.x + continue_icon_size.x > _x_limit:
		rich_text_label.position.x = (
			_x_limit - limit_margin - rich_text_label.size.x - continue_icon_size.x
		)
	if rich_text_label.position.y < 0.0:
		rich_text_label.position.y = limit_margin
	elif rich_text_label.position.y + rich_text_label.size.y > _y_limit:
		rich_text_label.position.y = _y_limit - limit_margin - rich_text_label.size.y


func _set_default_label_size(lbl: Label) -> void:
	lbl.size.y = get_meta(DFLT_SIZE).y


func _append_text(msg: String, props: Dictionary) -> void:
	msg = _correct_line_breaks(msg)
	
	var center: float = floor(rich_text_label.position.x + (rich_text_label.size.x / 2))
	if center == props.position.x:
		rich_text_label.text = "[center]%s[/center]" % msg
	elif center < props.position.x:
		rich_text_label.text = "[right]%s[/right]" % msg


func _get_icon_from_position() -> float:
	return rich_text_label.size.y / 2.0 - 1.0


func _get_icon_to_position() -> float:
	return rich_text_label.size.y / 2.0 + 3.0


## Appends text for the dialog caption
## Ensures that where a printing a word would see it wrap to the next line that the newline
## is forced into the text. Without this the tween in dialog_text.gd would print part of the word
## until it runs out of space, then erase the part word and rewrite it on the next line which looks
## messy.
func _correct_line_breaks(msg: String) -> String:
	rich_text_label.text = msg
	var number_of_lines_of_text := rich_text_label.get_line_count()
	if number_of_lines_of_text > 1:
		var current_line_number := 0
		for current_character in range(0, rich_text_label.text.length()):
			if rich_text_label.get_character_line(current_character) > current_line_number:
				current_line_number += 1
				if rich_text_label.text[current_character-1] == " ":
					rich_text_label.text[current_character-1] = "\n"
				elif rich_text_label.text[current_character-1] != "\n":
					rich_text_label.text = rich_text_label.text.left(current_character) + "\n" +\
					rich_text_label.text.right(-current_character)

				if current_line_number == number_of_lines_of_text - 1:
					break
	return rich_text_label.text

	
#endregion
