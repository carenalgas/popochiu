extends CanvasLayer

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

var is_blocked := false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	set_cursor()


func _process(delta):
	$AnimatedSprite.position = $AnimatedSprite.get_global_mouse_position()
	$Sprite.position = $AnimatedSprite.get_global_mouse_position()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func set_cursor(type := Type.IDLE, ignore_block := false) -> void:
	if not ignore_block and is_blocked: return
	
	var anim_name: String = Type.keys()[Type.IDLE]
	if Type.values().has(type):
		anim_name = Type.keys()[type]
	$AnimatedSprite.play(anim_name.to_lower())


func set_cursor_texture(texture: Texture, ignore_block := false) -> void:
	if not ignore_block and is_blocked: return
	
	$AnimatedSprite.hide()
	$Sprite.texture = texture
	$Sprite.show()


func remove_cursor_texture() -> void:
	$Sprite.texture = null
	$Sprite.hide()
	$AnimatedSprite.show()


func toggle_visibility(is_visible: bool) -> void:
	$AnimatedSprite.visible = is_visible
	$Sprite.visible = is_visible


func block() -> void:
	is_blocked = true


func unlock() -> void:
	is_blocked = false


func scale_cursor(factor: Vector2) -> void:
	$Sprite.scale = Vector2.ONE * factor
	$AnimatedSprite.scale = Vector2.ONE * factor


func get_position() -> Vector2:
	return $Sprite.position
