extends PopochiuDialogText

@onready var left_avatar: TextureRect = %LeftAvatar
@onready var right_avatar: TextureRect = %RightAvatar


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Connect to child signals
	text_show_started.connect(show)
	text_show_finished.connect(hide)
	
	# Connect to singletons signals
	C.character_spoke.connect(_update_avatar)
	
	hide()


#endregion

#region Private ####################################################################################
func _update_avatar(chr: PopochiuCharacter, _msg := '') -> void:
	if not rich_text_label.visible: return
	
	left_avatar.texture = null
	right_avatar.texture = null
	
	var char_pos: Vector2 = PopochiuUtils.get_screen_coords_for(chr).floor() / (
		E.scale if E.settings.scale_gui else Vector2.ONE
	)
	
	if char_pos.x <= E.half_width:
		left_avatar.texture = chr.get_avatar_for_emotion(chr.emotion)
	else:
		right_avatar.texture = chr.get_avatar_for_emotion(chr.emotion)


#endregion
