extends PanelContainer

@onready var portrait_text: RichTextLabel = %PortraitText
@onready var left_avatar: TextureRect = $HBoxContainer/LeftAvatar
@onready var right_avatar: TextureRect = $HBoxContainer/RightAvatar


func _ready() -> void:
	# Connect to child signals
	portrait_text.text_show_started.connect(show)
	portrait_text.text_show_finished.connect(hide)
	
	# Connect to singletons signals
	C.character_spoke.connect(_update_avatar)
	
	hide()


func _update_avatar(chr: PopochiuCharacter, _msg := '') -> void:
	if not portrait_text.visible: return
	
	left_avatar.texture = null
	right_avatar.texture = null
	
	var char_pos: Vector2 = PopochiuUtils.get_screen_coords_for(chr).floor() / (
		E.scale if E.settings.scale_gui else Vector2.ONE
	)
	
	if char_pos.x <= E.half_width:
		left_avatar.texture = chr.get_avatar_for_emotion(chr.emotion)
	else:
		right_avatar.texture = chr.get_avatar_for_emotion(chr.emotion)
