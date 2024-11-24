extends PopochiuDialogText

@onready var left_avatar_container: PanelContainer = %LeftAvatarContainer
@onready var left_avatar: TextureRect = %LeftAvatar
@onready var right_avatar_container: PanelContainer = %RightAvatarContainer
@onready var right_avatar: TextureRect = %RightAvatar

const _LOOKING_LEFT_DIRS := [
		PopochiuCharacter.Looking.LEFT,
		PopochiuCharacter.Looking.UP_LEFT,
		PopochiuCharacter.Looking.DOWN_LEFT,
		]

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
	
	var flip_h := _LOOKING_LEFT_DIRS.has(chr._looking_dir)
	
	if char_pos.x <= E.half_width:
		left_avatar_container.modulate.a = 1.0
		left_avatar.texture = chr.get_avatar_for_emotion(chr.emotion)
		left_avatar.flip_h = flip_h
	else:
		right_avatar_container.modulate.a = 1.0
		right_avatar.texture = chr.get_avatar_for_emotion(chr.emotion)
		right_avatar.flip_h = flip_h


func _set_default_size() -> void:
	pass


#endregion
