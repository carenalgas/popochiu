class_name Character
extends Clickable
# Cualquier objeto que pueda hablar, caminar, moverse entre habitaciones, tener
# inventario, entre otras muchas cosas.

# TODO: Crear la máquina de estados

signal started_walk_to(start, end)

var _looking_dir := 'd'

export var text_color := Color.white
export var walk_speed := 200.0
export var is_player := false

onready var sprite: Sprite = $Sprite


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	# Conectarse a señales del cielo
	C.connect('character_walk_to', self, '_check_walk')
	
	idle(false)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
static func walk_to_clicked() -> void:
	prints('Me lleva la verdura')


func walk(target_pos: Vector2) -> void:
	$AnimationPlayer.play('walk_r')
	$Sprite.flip_h = target_pos.x < position.x


func idle(is_in_queue := true) -> void:
	if is_in_queue: yield()
	$AnimationPlayer.play('idle_%s' % _looking_dir)
	yield(get_tree(), 'idle_frame')


func face_up(is_in_queue := true) -> void:
	if is_in_queue: yield()
	_looking_dir = 'u'
	yield(idle(false), 'completed')


func face_down(is_in_queue := true) -> void:
	if is_in_queue: yield()
	_looking_dir = 'd'
	yield(idle(false), 'completed')


func face_left(is_in_queue := true) -> void:
	if is_in_queue: yield()
	_looking_dir = 'r'
	$Sprite.flip_h = true
	yield(idle(false), 'completed')


func face_right(is_in_queue := true) -> void:
	if is_in_queue: yield()
	_looking_dir = 'r'
	$Sprite.flip_h = false
	yield(idle(false), 'completed')


func say(dialog: String, is_in_queue := true) -> void:
	if is_in_queue: yield()

	C.emit_signal('character_spoke', self, dialog)
	$AnimationPlayer.play('talk_%s' % _looking_dir)
	yield(G, 'continue_clicked')
	idle(false)


# Quita un ítem del inventario del personaje (¿o del jugador?)
func remove_inventory() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _check_walk(n: String, t: Vector2) -> void:
	if n.to_lower() == script_name.to_lower():
		emit_signal('started_walk_to', position, t)
