extends PopochiuDialogText

## Determines when to flip the portrait texture horizontally.
enum FlipsWhen {
	## The portrait texture is not flipped.
	NONE,
	## The portrait texture is flipped when the character is looking to the right.
	LOOKING_RIGHT,
	## The portrait texture is flipped when the character is looking to the left.
	LOOKING_LEFT
}

## Depending on its value, the portrait texture will be flipped horizontally based on
## which way the character is facing. If the value is [constant NONE], then the
## portrait won't be flipped.
@export var flips_when: FlipsWhen = FlipsWhen.NONE

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

	var flip_h: bool = (
		flips_when == FlipsWhen.LOOKING_LEFT and chr.is_facing_any([
			PopochiuCharacter.Looking.LEFT,
			PopochiuCharacter.Looking.UP_LEFT,
			PopochiuCharacter.Looking.DOWN_LEFT
		])
	) or (
		flips_when == FlipsWhen.LOOKING_RIGHT and chr.is_facing_any([
			PopochiuCharacter.Looking.RIGHT,
			PopochiuCharacter.Looking.UP_RIGHT,
			PopochiuCharacter.Looking.DOWN_RIGHT
		])
	)
	
	if char_pos.x <= PopochiuUtils.e.half_width:
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
