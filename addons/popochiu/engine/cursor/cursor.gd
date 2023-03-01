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
	$AnimatedSprite2D.position = $AnimatedSprite2D.get_global_mouse_position()
	$Sprite2D.position = $AnimatedSprite2D.get_global_mouse_position()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func set_cursor(type := Type.IDLE, ignore_block := false) -> void:
	if not ignore_block and is_blocked: return
	
	var anim_name: String = Type.keys()[Type.IDLE]
	if Type.values().has(type):
		anim_name = Type.keys()[type]
	$AnimatedSprite2D.play(anim_name.to_lower())


func set_cursor_texture(texture: Texture2D, ignore_block := false) -> void:
	if not ignore_block and is_blocked: return
	
	$AnimatedSprite2D.hide()
	$Sprite2D.texture = texture
	$Sprite2D.show()


func remove_cursor_texture() -> void:
	$Sprite2D.texture = null
	$Sprite2D.hide()
	$AnimatedSprite2D.show()


func toggle_visibility(is_visible: bool) -> void:
	$AnimatedSprite2D.visible = is_visible
	$Sprite2D.visible = is_visible


func block() -> void:
	is_blocked = true


func unlock() -> void:
	is_blocked = false


func scale_cursor(factor: Vector2) -> void:
	$Sprite2D.scale = Vector2.ONE * factor
	$AnimatedSprite2D.scale = Vector2.ONE * factor


func get_position() -> Vector2:
	return $Sprite2D.position
