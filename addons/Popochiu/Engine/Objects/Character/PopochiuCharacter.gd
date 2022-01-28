tool
class_name PopochiuCharacter, 'res://addons/Popochiu/icons/character.png'
extends Clickable
# Cualquier objeto que pueda hablar, caminar, moverse entre habitaciones, tener
# inventario, entre otras muchas cosas.

# TODO: Crear la máquina de estados

signal started_walk_to(character, start, end)
signal stoped_walk

export var dflt_walk_animation := 'walk_r'
export var text_color := Color.white
export var walk_speed := 200.0
export var is_player := false
export var texture: Texture setget _set_texture
export var vo_name := ''
export var follow_player := false

var room := ''
var last_room := ''
var anim_suffix := ''
var is_moving := false

var _looking_dir := 'd'

onready var sprite: Sprite = $Sprite
onready var dialog_pos: Position2D = $DialogPos


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	if not Engine.editor_hint:
		idle(false)
		set_process(follow_player)
	else:
		set_process(true)
		hide_helpers()


func _process(_delta: float) -> void:
	if Engine.editor_hint: ._process(_delta)
	elif is_instance_valid(C.player):
		global_position = C.player.global_position


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func walk(target_pos: Vector2, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	is_moving = true
	
	$Sprite.flip_h = target_pos.x < position.x
#	_looking_dir = 'l' if $Sprite.flip_h else 'r'
#	_looking_dir = 'l' if $Sprite.flip_h else 'r'

	if E.cutscene_skipped:
		is_moving = false
		E.main_camera.smoothing_enabled = false
		yield(get_tree(), 'idle_frame')
		position = target_pos
		E.main_camera.position = target_pos
		yield(get_tree(), 'idle_frame')
		E.main_camera.smoothing_enabled = true
		return
	
	var anim_name := 'walk_%s' % _looking_dir + anim_suffix
	if $AnimationPlayer.has_animation(anim_name):
		$AnimationPlayer.play(anim_name)
	else:
		$AnimationPlayer.play(dflt_walk_animation)

	emit_signal('started_walk_to', self, position, target_pos)
	yield(C, 'character_move_ended')
	is_moving = false


func stop_walking(is_in_queue := true) -> void:
	if is_in_queue: yield()
	is_moving = false
	emit_signal('stoped_walk')
	yield(get_tree(), 'idle_frame')


func idle(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	var anim_name := 'idle_%s' % _looking_dir + anim_suffix

	if $AnimationPlayer.has_animation(anim_name):
		$AnimationPlayer.play(anim_name)
	
	if E.cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return
	
	yield(get_tree().create_timer(0.2), 'timeout')


func face_up(is_in_queue := true) -> void:
	if is_in_queue: yield()
	_looking_dir = 'u'
	yield(idle(false), 'completed')


func face_up_right(is_in_queue := true) -> void:
	if is_in_queue: yield()
	_looking_dir = 'ur'
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

	if E.cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return

	C.emit_signal('character_spoke', self, dialog)

#	if vo_name:
#		A.play(vo_name, global_position, false)
	
	var anim_name := 'talk_%s' % _looking_dir + anim_suffix
	
	if $AnimationPlayer.has_animation(anim_name):
		$AnimationPlayer.play(anim_name)

	yield(G, 'continue_clicked')
	idle(false)


func grab(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	if E.cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return
	
	$AnimationPlayer.play('grab_%s' % _looking_dir)
	
	if get_node_or_null('AnimatedSprite'):
		yield($AnimatedSprite, 'animation_finished')
	else:
		yield($AnimationPlayer, 'animation_finished')

	idle(false)


func get_dialog_pos() -> float:
	return $DialogPos.position.y


# Quita un ítem del inventario del personaje (¿o del jugador?)
func remove_inventory() -> void:
	pass


func hide_helpers() -> void:
	.hide_helpers()
	
	if is_instance_valid(dialog_pos): dialog_pos.hide()


func show_helpers() -> void:
	.show_helpers()
	if is_instance_valid(dialog_pos): dialog_pos.show()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _set_texture(value: Texture) -> void:
	texture = value
	$Sprite.texture = value


func _translate() -> void:
	if Engine.editor_hint or not is_inside_tree(): return
	description = E.get_text(_description_code)
