class_name PopochiuCursor
extends CanvasLayer

# TODO: Deprecate this? I'll leave it here while we merge the refactor for the
# 		creation popups because in those the Cursor.Type enum is used.
enum Type {
	NONE,
	ACTIVE,
	DOWN,
	IDLE,
	LEFT,
	LOOK,
	RIGHT,
	SEARCH,
	TALK,
	UP,
	USE,
	WAIT,
}

@export var is_pixel_perfect := false

var is_blocked := false

@onready var main_cursor: AnimatedSprite2D = $MainCursor
@onready var secondary_cursor: Sprite2D = $SecondaryCursor


#region Godot ######################################################################################
func _init() -> void:
	Engine.register_singleton(&"Cursor", self)


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Connect to autoload signals
	PopochiuUtils.e.ready.connect(show_cursor)


func _process(delta):
	var texture_size := (main_cursor.sprite_frames.get_frame_texture(
		main_cursor.animation,
		main_cursor.frame
	) as Texture2D).get_size()
	
	var mouse_position: Vector2 = main_cursor.get_global_mouse_position()
	
	if is_pixel_perfect:
		# Thanks to @whyshchuck
		main_cursor.position = Vector2i(mouse_position)
		secondary_cursor.position = Vector2i(mouse_position)
	else:
		main_cursor.position = mouse_position
		secondary_cursor.position = mouse_position
	
	if main_cursor.position.x < 1.0:
		main_cursor.position.x = 1.0
	elif main_cursor.position.x > PopochiuUtils.e.width - 2.0:
		main_cursor.position.x = PopochiuUtils.e.width - 2.0
	
	if main_cursor.position.y < 1.0:
		main_cursor.position.y = 1.0
	elif main_cursor.position.y > PopochiuUtils.e.height - 2.0:
		main_cursor.position.y = PopochiuUtils.e.height - 2.0


#endregion

#region Public #####################################################################################
func show_cursor(anim_name := "normal", ignore_block := false) -> void:
	if not ignore_block and is_blocked: return
	
	if (
		not anim_name.is_empty()
		and not main_cursor.sprite_frames.has_animation(anim_name)
	):
		PopochiuUtils.print_error("Cursor has no animation: %s" % anim_name)
		return
	
	main_cursor.play(anim_name)
	main_cursor.show()
	secondary_cursor.hide()


func set_secondary_cursor_texture(texture: Texture2D, ignore_block := false) -> void:
	if not ignore_block and is_blocked: return
	
	secondary_cursor.texture = texture
	
	if PopochiuUtils.e.settings.scale_gui:
		# Scale the cursor based the relation of the texture size compared to the main cursor
		# texture size
		secondary_cursor.scale = Vector2.ONE * ceil(
			float(texture.get_height()) / float(get_cursor_height())
		)
	
	secondary_cursor.show()


func remove_secondary_cursor_texture() -> void:
	secondary_cursor.texture = null
	
	if PopochiuUtils.e.settings.scale_gui:
		secondary_cursor.scale = PopochiuUtils.e.scale
	
	secondary_cursor.hide()


func toggle_visibility(is_visible: bool) -> void:
	main_cursor.visible = is_visible
	secondary_cursor.visible = is_visible


func block() -> void:
	is_blocked = true


func unblock() -> void:
	is_blocked = false


func scale_cursor(factor: Vector2) -> void:
	secondary_cursor.scale = factor
	main_cursor.scale = factor


func get_position() -> Vector2:
	return secondary_cursor.position


func replace_frames(new_node: AnimatedSprite2D) -> void:
	main_cursor.sprite_frames = new_node.sprite_frames
	main_cursor.offset = new_node.offset


func hide_main_cursor() -> void:
	main_cursor.hide()


func show_main_cursor() -> void:
	main_cursor.show()


func hide_secondary_cursor() -> void:
	secondary_cursor.hide()


func show_secondary_cursor() -> void:
	secondary_cursor.show()


func get_type_name(idx: int) -> String:
	return Type.keys()[idx].to_snake_case()


func get_cursor_height() -> int:
	var height := 0
	
	if main_cursor.visible:
		height = main_cursor.sprite_frames.get_frame_texture(main_cursor.animation, 0).get_height()
	elif secondary_cursor.visible:
		height = secondary_cursor.texture.get_height()
	
	return height


#endregion
