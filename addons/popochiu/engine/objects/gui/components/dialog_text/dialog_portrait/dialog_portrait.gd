extends PopochiuDialogText

@onready var left_avatar_container: PanelContainer = %LeftAvatarContainer
@onready var left_avatar: TextureRect = %LeftAvatar
@onready var right_avatar_container: PanelContainer = %RightAvatarContainer
@onready var right_avatar: TextureRect = %RightAvatar


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Connect to singletons signals
	PopochiuUtils.c.character_spoke.connect(_update_avatar)


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
		PopochiuUtils.e.scale if PopochiuUtils.e.settings.scale_gui else Vector2.ONE
	)
	
	if char_pos.x <= PopochiuUtils.e.half_width:
		left_avatar_container.modulate.a = 1.0
		left_avatar.texture = chr.get_avatar_for_emotion(chr.emotion)
	else:
		right_avatar_container.modulate.a = 1.0
		right_avatar.texture = chr.get_avatar_for_emotion(chr.emotion)


func _set_default_size() -> void:
	pass


#endregion
