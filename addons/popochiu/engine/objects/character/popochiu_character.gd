# Any Object that can move, walk, navigate rooms, have an inventory, etc.
@tool
@icon('res://addons/popochiu/icons/character.png')
class_name PopochiuCharacter
extends PopochiuClickable
# TODO: Use a state machine

enum FlipsWhen { NONE, MOVING_RIGHT, MOVING_LEFT }
enum Looking {UP, UP_RIGHT, RIGHT, RIGHT_DOWN, DOWN, DOWN_LEFT, LEFT, UP_LEFT}

signal started_walk_to(character, start, end)
signal stoped_walk

@export var text_color := Color.WHITE
@export var flips_when: FlipsWhen = FlipsWhen.NONE
@export var voices := []:
	set = set_voices # (Array, Dictionary)
@export var follow_player := false
@export var walk_speed := 200.0
@export var can_move := true
@export var ignore_walkable_areas := false

var last_room := ''
var anim_suffix := ''
var is_moving := false
var emotion := ''

var _looking_dir: int = Looking.DOWN

@onready var dialog_pos: Marker2D = $DialogPos


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	super()
	
	if not Engine.is_editor_hint():
		set_process(follow_player)
	else:
		hide_helpers()
		set_process(true)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _play_idle() -> void:
	pass


func _play_walk(target_pos: Vector2) -> void:
	pass


func _play_talk() -> void:
	pass


func _play_grab() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func queue_idle() -> Callable:
	return func (): await idle()
	
	
func idle() -> void:
	if E.cutscene_skipped:
		await get_tree().process_frame
		return
	
	if has_node('Sprite2D'):
		match flips_when:
			FlipsWhen.MOVING_LEFT:
				$Sprite2D.flip_h = _looking_dir == Looking.LEFT
			FlipsWhen.MOVING_RIGHT:
				$Sprite2D.flip_h = _looking_dir == Looking.RIGHT
	
	# Call the virtual that plays the idle animation
	_play_idle()
	
	await get_tree().create_timer(0.2).timeout


func queue_walk(target_pos: Vector2) -> Callable:
	return func (): await walk(target_pos)


func walk(target_pos: Vector2) -> void:
	is_moving = true
	_looking_dir = Looking.LEFT if target_pos.x < position.x else Looking.RIGHT
	
	if has_node('Sprite2D'):
		match flips_when:
			FlipsWhen.MOVING_LEFT:
				$Sprite2D.flip_h = target_pos.x < position.x
			FlipsWhen.MOVING_RIGHT:
				$Sprite2D.flip_h = target_pos.x > position.x
	
	if E.cutscene_skipped:
		is_moving = false
		E.main_camera.follow_smoothing_enabled = false
		
		await get_tree().process_frame
		
		position = target_pos
		E.main_camera.position = target_pos
		
		await get_tree().process_frame
		
		E.main_camera.follow_smoothing_enabled = true
		
		return
	
	# Call the virtual that plays the walk animation
	_play_walk(target_pos)
	
	# Trigger the signal for the room  to start moving the character
	started_walk_to.emit(self, position, target_pos)
	
	await C.character_move_ended
	
	is_moving = false


func queue_stop_walking() -> Callable:
	return func (): await stop_walking()
	
	
func stop_walking() -> void:
	is_moving = false
	
	stoped_walk.emit()
	
	await get_tree().process_frame


func queue_face_up() -> Callable:
	return func (): await face_up()


func face_up() -> void:
	_looking_dir = Looking.UP
	await idle()


func queue_face_up_right() -> Callable:
	return func (): await face_up_right()


func face_up_right() -> void:
	_looking_dir = Looking.UP_RIGHT
	await idle()


func queue_face_down() -> Callable:
	return func (): await face_down()


func face_down() -> void:
	_looking_dir = Looking.DOWN
	await idle()


func queue_face_left() -> Callable:
	return func (): await face_left()


func face_left() -> void:
	_looking_dir = Looking.LEFT
	await idle()


func queue_face_right() -> Callable:
	return func (): await face_right()


func face_right() -> void:
	_looking_dir = Looking.RIGHT
	await idle()


func queue_face_clicked() -> Callable:
	return func (): await face_clicked()


func face_clicked() -> void:
	if E.clicked.global_position < global_position:
		if has_node('Sprite2D'):
			$Sprite2D.flip_h = flips_when == FlipsWhen.MOVING_LEFT
		
		await face_left()
	else:
		if has_node('Sprite2D'):
			$Sprite2D.flip_h = flips_when == FlipsWhen.MOVING_RIGHT
		
		await face_right()


func queue_say(dialog: String) -> Callable:
	return func (): await say(dialog)


func say(dialog: String) -> void:
	if E.cutscene_skipped:
		await get_tree().process_frame
		return
	
	# Call the virtual that plays the talk animation
	_play_talk()
	
	var vo_name := _get_vo_cue(emotion)
	if vo_name:
		A.play(vo_name, false, global_position)
	
	C.character_spoke.emit(self, dialog)
	
	await G.continue_clicked
	
	emotion = ''
	idle()
	
	G.done(true)


func queue_grab() -> Callable:
	return func (): await grab()


func grab() -> void:
	if E.cutscene_skipped:
		await get_tree().process_frame
		return
	
	# Call the virtual that plays the grab animation
	_play_grab()
	
	await C.character_grab_done
	
	idle()


func hide_helpers() -> void:
	super()
	
	if is_instance_valid(dialog_pos): dialog_pos.hide()


func show_helpers() -> void:
	super()
	if is_instance_valid(dialog_pos): dialog_pos.show()


func queue_walk_to(pos: Vector2) -> Callable:
	return func(): await walk_to(pos)


func walk_to(pos: Vector2) -> void:
	walk(E.current_room.to_global(pos))
	
	await C.character_move_ended


func queue_walk_to_prop(id: String) -> Callable:
	return func(): await walk_to_prop(id)


func walk_to_prop(id: String) -> void:
	_walk_to_clickable(E.current_room.get_prop(id))
	
	await C.character_move_ended


func queue_walk_to_hotspot(id: String) -> Callable:
	return func(): await walk_to_hotspot(id)


func walk_to_hotspot(id: String) -> void:
	_walk_to_clickable(E.current_room.get_hotspot(id))
	
	await C.character_move_ended


func queue_walk_to_marker(id: String) -> Callable:
	return func(): await walk_to_marker(id)


func walk_to_marker(id: String) -> void:
	walk(E.current_room.get_point(id))

	await C.character_move_ended


func queue_set_emotion(new_emotion: String) -> Callable:
	return func(): emotion = new_emotion


func queue_ignore_walkable_areas(new_value: bool) -> Callable:
	return func(): ignore_walkable_areas = new_value


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
			notify_property_list_changed()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _translate() -> void:
	if Engine.is_editor_hint() or not is_inside_tree(): return
	description = E.get_text(_description_code)


func _get_vo_cue(emotion := '') -> String:
	for v in voices:
		if v.emotion.to_lower() == emotion.to_lower():
			var cue_name: String = v.cue
			
			if v.variations:
				if not v.has('not_played') or v.not_played.is_empty():
					v['not_played'] = range(v.variations)
				
				var idx: int = (v['not_played'] as Array).pop_at(
					PopochiuUtils.get_random_array_idx(v['not_played'])
				)
				
				cue_name += '_' + str(idx + 1).pad_zeros(2)
			
			return cue_name
	return ''


func _walk_to_clickable(node: PopochiuClickable) -> void:
	if not is_instance_valid(node):
		await get_tree().process_frame
		return
	
	walk(node.to_global(node.walk_to_point))
