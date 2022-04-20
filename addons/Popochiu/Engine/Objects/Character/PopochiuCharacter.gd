tool
class_name PopochiuCharacter, 'res://addons/Popochiu/icons/character.png'
extends 'res://addons/Popochiu/Engine/Objects/Clickable/PopochiuClickable.gd'
# Any Object that can move, walk, navigate rooms, has an inventory, etc.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# TODO: Use a state machine

enum FlipsWhen { NONE, MOVING_RIGHT, MOVING_LEFT }

signal started_walk_to(character, start, end)
signal stoped_walk

export var text_color := Color.white
export var is_player := false
export var walk_speed := 200.0
export(FlipsWhen) var flips_when := 0
export var vo_name := ''
export var follow_player := false

var last_room := ''
var anim_suffix := ''
var is_moving := false

var _looking_dir := 'd'

onready var sprite: Sprite = $Sprite
onready var dialog_pos: Position2D = $DialogPos


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	if not Engine.editor_hint:
		idle(false)
		set_process(follow_player)
	else:
		hide_helpers()
		set_process(true)


#func _process(_delta: float) -> void:
#	if Engine.editor_hint: return
#	elif is_instance_valid(C.player):
#		global_position = C.player.global_position


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func idle(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	if E.cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return
	
	play_idle()
	
	yield(get_tree().create_timer(0.2), 'timeout')


func walk(target_pos: Vector2, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	is_moving = true
	
	match flips_when:
		FlipsWhen.MOVING_LEFT:
			$Sprite.flip_h = target_pos.x < position.x
		FlipsWhen.MOVING_RIGHT:
			$Sprite.flip_h = target_pos.x > position.x
	
	if E.cutscene_skipped:
		is_moving = false
		E.main_camera.smoothing_enabled = false
		yield(get_tree(), 'idle_frame')
		position = target_pos
		E.main_camera.position = target_pos
		yield(get_tree(), 'idle_frame')
		E.main_camera.smoothing_enabled = true
		return
	
	play_walk()
	
	# Notify this so the room starts moving the character in the room
	emit_signal('started_walk_to', self, position, target_pos)
	
	yield(C, 'character_move_ended')
	
	is_moving = false


func stop_walking(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	is_moving = false
	
	emit_signal('stoped_walk')
	
	yield(get_tree(), 'idle_frame')


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
	
	_looking_dir = 'l'
	yield(idle(false), 'completed')


func face_right(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	_looking_dir = 'r'
	yield(idle(false), 'completed')


func say(dialog: String, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	if E.cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return
	
	play_talk()
	if vo_name:
		A.play({
			cue_name = vo_name,
			pos = global_position,
			is_in_queue = false
		})
	
	C.emit_signal('character_spoke', self, dialog)
	
	yield(G, 'continue_clicked')
	
	idle(false)


func grab(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	if E.cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return
	
	play_grab()
	
	yield(C, 'character_grab_done')
	
	idle(false)


func hide_helpers() -> void:
	.hide_helpers()
	
	if is_instance_valid(dialog_pos): dialog_pos.hide()


func show_helpers() -> void:
	.show_helpers()
	if is_instance_valid(dialog_pos): dialog_pos.show()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func get_dialog_pos() -> float:
	return $DialogPos.position.y


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _translate() -> void:
	if Engine.editor_hint or not is_inside_tree(): return
	description = E.get_text(_description_code)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func play_idle() -> void:
	pass


func play_walk() -> void:
	pass


func play_talk() -> void:
	pass


func play_grab() -> void:
	pass
