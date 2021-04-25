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
	
	idle()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
static func walk_to_clicked() -> void:
	prints('Me lleva la verdura')


func walk(target_pos: Vector2) -> void:
	$AnimationPlayer.play('walk_r')
	$Sprite.flip_h = target_pos.x < position.x


func idle() -> void:
	$AnimationPlayer.play('idle_%s' % _looking_dir)


func face_up() -> void:
	_looking_dir = 'u'
	$AnimationPlayer.play('idle_u')


func face_down() -> void:
	_looking_dir = 'd'
	$AnimationPlayer.play('idle_d')


func face_left() -> void:
	_looking_dir = 'l'
	$AnimationPlayer.play('idle_r')
	$Sprite.flip_h = true


func face_right() -> void:
	_looking_dir = 'r'
	$AnimationPlayer.play('idle_r')
	$Sprite.flip_h = false


func say(dialog: String, no_yield := false) -> void:
	if not no_yield:
		yield()
	C.emit_signal('character_spoke', self, dialog)
	$AnimationPlayer.play('talk_%s' % _looking_dir)
	yield(G, 'continue_clicked')
	idle()


# Quita un ítem del inventario del personaje (¿o del jugador?)
func remove_inventory() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _check_walk(n: String, t: Vector2) -> void:
	if n.to_lower() == script_name.to_lower():
		emit_signal('started_walk_to', position, t)
