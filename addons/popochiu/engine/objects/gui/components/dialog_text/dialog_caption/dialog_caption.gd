extends PopochiuDialogText


#region Private ####################################################################################
func _modify_size(msg: String, _target_position: Vector2) -> void:
	var _size := await _calculate_size(msg)

	# Define size and position (before calculating overflow)
	rich_text_label.size.x = _size.x
	rich_text_label.size.y = _size.y
	rich_text_label.position.x = (get_viewport_rect().size.x/2) - (_size.x /2)
	rich_text_label.position.y = get_meta(DFLT_POSITION).y - (_size.y - get_meta(DFLT_SIZE).y)


func _append_text(msg: String, props: Dictionary) -> void:
	msg = _correct_line_breaks(msg)
	rich_text_label.text = "[center][color=%s]%s[/color][/center]" % [props.color.to_html(), msg]


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
					rich_text_label.text = rich_text_label.text.left(current_character) +\
					"\n" + rich_text_label.text.right(-current_character)

				if current_line_number == number_of_lines_of_text - 1:
					break
	return rich_text_label.text

#endregion
