tool
class_name PopochiuCharacter, 'res://addons/Popochiu/icons/character.png'
extends 'res://addons/Popochiu/Engine/Objects/Clickable/PopochiuClickable.gd'
# Any Object that can move, walk, navigate rooms, have an inventory, etc.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# TODO: Use a state machine

enum FlipsWhen { NONE, MOVING_RIGHT, MOVING_LEFT }
enum LOOKING {UP, UP_RIGHT, RIGHT, RIGHT_DOWN, DOWN, DOWN_LEFT, LEFT, UP_LEFT}

signal started_walk_to(character, start, end)
signal stoped_walk

export var text_color := Color.white
export var is_player := false
export(FlipsWhen) var flips_when := 0
export(Array, Dictionary) var voices := [] setget set_voices
export var follow_player := false
export var walk_speed := 200.0
export var can_move := true
export var ignore_walkable_areas := false

var last_room := ''
var anim_suffix := ''
var is_moving := false
var emotion := ''

var _looking_dir: int = LOOKING.DOWN

onready var dialog_pos: Position2D = $DialogPos


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	if not Engine.editor_hint:
		idle(false)
		set_process(follow_player)
	else:
		hide_helpers()
		set_process(true)


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
	_looking_dir = LOOKING.LEFT if target_pos.x < position.x else LOOKING.RIGHT
	
	if has_node('Sprite'):
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
	
	play_walk(target_pos)
	
	# Trigger the signal for the room  to start moving the character
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
	
	_looking_dir = LOOKING.UP
	yield(idle(false), 'completed')


func face_up_right(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	_looking_dir = LOOKING.UP_RIGHT
	yield(idle(false), 'completed')


func face_down(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	_looking_dir = LOOKING.DOWN
	yield(idle(false), 'completed')


func face_left(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	_looking_dir = LOOKING.LEFT
	
	yield(idle(false), 'completed')


func face_right(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	_looking_dir = LOOKING.RIGHT
	yield(idle(false), 'completed')


func face_clicked(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	if E.clicked.global_position < global_position:
		if has_node('Sprite'):
			$Sprite.flip_h = flips_when == FlipsWhen.MOVING_LEFT
		
		yield(face_left(false), 'completed')
	else:
		if has_node('Sprite'):
			$Sprite.flip_h = flips_when == FlipsWhen.MOVING_RIGHT
		
		yield(face_right(false), 'completed')


func say(dialog: String, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	if E.cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return
	
	play_talk()
	
	var vo_name := _get_vo_cue(emotion)
	if vo_name:
		A.play_no_block(vo_name, false, global_position)
	
	C.emit_signal('character_spoke', self, dialog)
	
	yield(G, 'continue_clicked')
	
	emotion = ''
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


func set_voices(value: Array) -> void:
	voices = value
	
	for idx in value.size():
		if not value[idx]:
			voices[idx] = {
				emotion = '',
				cue = '',
				variations = 0
			}
			property_list_changed_notify()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _translate() -> void:
	if Engine.editor_hint or not is_inside_tree(): return
	description = E.get_text(_description_code)


func _get_vo_cue(emotion := '') -> String:
	for v in voices:
		if v.emotion.to_lower() == emotion.to_lower():
			var cue_name: String = v.cue
			
			if v.variations:
				if not v.has('not_played') or v.not_played.empty():
					v['not_played'] = range(v.variations)
				
				var idx: int = (v['not_played'] as Array).pop_at(
					U.get_random_array_idx(v['not_played'])
				)
				
				cue_name += '_' + str(idx + 1).pad_zeros(2)
			
			return cue_name
	return ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func play_idle() -> void:
	pass


func play_walk(target_pos: Vector2) -> void:
	pass


func play_talk() -> void:
	pass


func play_grab() -> void:
	pass
