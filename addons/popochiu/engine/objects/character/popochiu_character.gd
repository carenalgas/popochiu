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
@export var is_player := false
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
@onready var agent = $NavigationAgent2D


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	super()
	
	if not Engine.is_editor_hint():
		idle()
		set_process(follow_player)
	else:
		hide_helpers()
		set_process(true)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func play_idle() -> void:
	pass


func play_walk(target_pos: Vector2) -> void:
	pass


func play_talk() -> void:
	pass


func play_grab() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func idle() -> Callable:
	return func (): await idle_now()
	
	
func idle_now() -> void:
	if E.cutscene_skipped:
		await get_tree().process_frame
		return
	
	if has_node('Sprite'):
		match flips_when:
			FlipsWhen.MOVING_LEFT:
				$Sprite.flip_h = _looking_dir == Looking.LEFT
			FlipsWhen.MOVING_RIGHT:
				$Sprite.flip_h = _looking_dir == Looking.RIGHT
	
	# Call the virtual that plays the idle animation
	play_idle()
	
	await get_tree().create_timer(0.2).timeout


func walk(target_pos: Vector2) -> Callable:
	return func (): await walk_now(target_pos)


func walk_now(target_pos: Vector2) -> void:
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
	play_walk(target_pos)
	
	# Trigger the signal for the room  to start moving the character
	started_walk_to.emit(self, position, target_pos)
	
	await C.character_move_ended
	
	is_moving = false


func stop_walking() -> Callable:
	return func (): await stop_walking_now()
	
	
func stop_walking_now() -> void:
	is_moving = false
	
	stoped_walk.emit()
	
	await get_tree().process_frame


func face_up() -> Callable:
	return func (): await face_up_now()


func face_up_now() -> void:
	_looking_dir = Looking.UP
	await idle_now()


func face_up_right() -> Callable:
	return func (): await face_up_right_now()


func face_up_right_now() -> void:
	_looking_dir = Looking.UP_RIGHT
	await idle_now()


func face_down() -> Callable:
	return func (): await face_down_now()


func face_down_now() -> void:
	_looking_dir = Looking.DOWN
	await idle_now()


func face_left() -> Callable:
	return func (): await face_left_now()


func face_left_now() -> void:
	_looking_dir = Looking.LEFT
	await idle_now()


func face_right() -> Callable:
	return func (): await face_right_now()


func face_right_now() -> void:
	_looking_dir = Looking.RIGHT
	await idle_now()


func face_clicked() -> Callable:
	return func (): await face_clicked_now()


func face_clicked_now() -> void:
	if E.clicked.global_position < global_position:
		if has_node('Sprite2D'):
			$Sprite2D.flip_h = flips_when == FlipsWhen.MOVING_LEFT
		
		await face_left_now()
	else:
		if has_node('Sprite2D'):
			$Sprite2D.flip_h = flips_when == FlipsWhen.MOVING_RIGHT
		
		await face_right_now()


func say(dialog: String) -> Callable:
	return func (): await say_now(dialog)


func say_now(dialog: String) -> void:
	if E.cutscene_skipped:
		await get_tree().process_frame
		return
	
	# Call the virtual that plays the talk animation
	play_talk()
	
	var vo_name := _get_vo_cue(emotion)
	if vo_name:
		A.play(vo_name, false, global_position)
	
	C.character_spoke.emit(self, dialog)
	
	await G.continue_clicked
	
	emotion = ''
	idle_now()


func grab() -> Callable:
	return func (): await grab_now()


func grab_now() -> void:
	if E.cutscene_skipped:
		await get_tree().process_frame
		return
	
	# Call the virtual that plays the grab animation
	play_grab()
	
	await C.character_grab_done
	
	idle_now()


func hide_helpers() -> void:
	super()
	
	if is_instance_valid(dialog_pos): dialog_pos.hide()


func show_helpers() -> void:
	super()
	if is_instance_valid(dialog_pos): dialog_pos.show()


func walk_to(pos: Vector2) -> Callable:
	return func(): await walk_to_now(pos)


func walk_to_now(pos: Vector2) -> void:
	C.character_walk_to_now(script_name, pos)
	
	await C.character_move_ended


func walk_to_prop(id: String) -> Callable:
	return func(): await walk_to_prop_now(id)


func walk_to_prop_now(id: String) -> void:
	_walk_to_clickable(E.current_room.get_prop(id))
	
	await C.character_move_ended


func walk_to_hotspot(id: String) -> Callable:
	return func(): await walk_to_hotspot_now(id)


func walk_to_hotspot_now(id: String) -> void:
	_walk_to_clickable(E.current_room.get_hotspot(id))
	
	await C.character_move_ended


func walk_to_room_point(id: String) -> Callable:
	return func(): await walk_to_room_point_now(id)


func walk_to_room_point_now(id: String) -> void:
	C.character_walk_to_now(script_name, E.current_room.get_point(id))

	await C.character_move_ended


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
					U.get_random_array_idx(v['not_played'])
				)
				
				cue_name += '_' + str(idx + 1).pad_zeros(2)
			
			return cue_name
	return ''


func _walk_to_clickable(node: PopochiuClickable) -> void:
	if not node:
		await get_tree().process_frame
		return
	
	C.character_walk_to_now(
		script_name, node.to_global(node.walk_to_point)
	)
