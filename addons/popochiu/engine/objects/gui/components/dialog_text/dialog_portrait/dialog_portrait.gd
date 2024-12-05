extends PopochiuDialogText

@onready var left_avatar_container: PanelContainer = %LeftAvatarContainer
@onready var left_avatar: TextureRect = %LeftAvatar
@onready var right_avatar_container: PanelContainer = %RightAvatarContainer
@onready var right_avatar: TextureRect = %RightAvatar


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Connect to singletons signals
	C.character_spoke.connect(_update_avatar)


#endregion

#region Private ####################################################################################
func _update_avatar(chr: PopochiuCharacter, _msg := '') -> void:
	if not rich_text_label.visible:
		return
	
	left_avatar_container.modulate.a = 0.0
	left_avatar.texture = null
	right_avatar_container.modulate.a = 0.0
	right_avatar.texture = null
	
	var char_pos: Vector2 = PopochiuUtils.get_screen_coords_for(chr).floor() / (
		E.scale if E.settings.scale_gui else Vector2.ONE
	)
	
	if char_pos.x <= E.half_width:
		left_avatar_container.modulate.a = 1.0
		left_avatar.texture = chr.get_avatar_for_emotion(chr.emotion)
	else:
		right_avatar_container.modulate.a = 1.0
		right_avatar.texture = chr.get_avatar_for_emotion(chr.emotion)


func _set_default_size() -> void:
	pass


func _append_text(msg: String, props: Dictionary) -> void:
	msg = _correct_line_breaks(msg)
	rich_text_label.text = "[color=%s]%s[/color]" % [props.color.to_html(), msg]
	

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

			var ThisChar = rich_text_label.text[current_character]
			var ThisLine = rich_text_label.get_character_line(current_character)
			if rich_text_label.get_character_line(current_character) > current_line_number:
				current_line_number += 1
				if rich_text_label.text[current_character-1] == " ":
					rich_text_label.text[current_character-1] = "\n"
				elif rich_text_label.text[current_character-1] != "\n":
					rich_text_label.text = rich_text_label.text.left(current_character) + "\n" + rich_text_label.text.right(-current_character)

				if current_line_number == number_of_lines_of_text - 1:
					break
	return rich_text_label.text

#endregion
