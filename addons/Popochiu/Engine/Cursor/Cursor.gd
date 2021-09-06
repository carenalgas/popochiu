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


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	set_cursor()


func _process(delta):
	$AnimatedSprite.position = $AnimatedSprite.get_global_mouse_position()
	$Sprite.position = $AnimatedSprite.get_global_mouse_position()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func set_cursor(type := Type.IDLE) -> void:
	if is_blocked: return
	
	var anim_name: String = Type.keys()[Type.IDLE]
	if Type.values().has(type):
		anim_name = Type.keys()[type]
	$AnimatedSprite.play(anim_name.to_lower())


func set_item_cursor(texture: Texture) -> void:
	$AnimatedSprite.hide()
	$Sprite.texture = texture
	$Sprite.show()


func remove_item_cursor() -> void:
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
