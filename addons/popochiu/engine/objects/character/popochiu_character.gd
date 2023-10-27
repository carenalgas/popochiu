## Any Object that can move, walk, navigate rooms, have an inventory, etc.
@tool
@icon('res://addons/popochiu/icons/character.png')
class_name PopochiuCharacter
extends PopochiuClickable
# TODO: Use a state machine

enum FlipsWhen { NONE, LOOKING_RIGHT, LOOKING_LEFT }
enum Looking {UP, UP_RIGHT, RIGHT, DOWN_RIGHT, DOWN, DOWN_LEFT, LEFT, UP_LEFT}

signal started_walk_to(character, start, end)
signal stopped_walk
signal move_ended

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

func _get_property_list():
	var properties = []
	properties.append({
		name = "Aseprite",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY
	})
	# This is needed or the category won't be shown in the
	# inspector. AsepriteImporterInspectorPlugin hides it.
	properties.append({
		name = "popochiu_placeholder",
		type = TYPE_NIL,
	})

	return properties


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _play_idle() -> void:
	play_animation('idle')


func _play_walk(target_pos: Vector2) -> void:
	# Set the default parameters for play_animation()
	var animation_label = 'walk'
	var animation_fallback = 'idle'
	play_animation(animation_label, animation_fallback)


func _play_talk() -> void:
	play_animation('talk')


func _play_grab() -> void:
	play_animation('grab')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func queue_idle() -> Callable:
	return func (): await idle()
	
	
func idle() -> void:
	if E.cutscene_skipped:
		await get_tree().process_frame
		return

	if has_node('Sprite2D'):
		match flips_when:
			FlipsWhen.LOOKING_LEFT:
				$Sprite2D.flip_h = _looking_dir == Looking.LEFT
			FlipsWhen.LOOKING_RIGHT:
				$Sprite2D.flip_h = _looking_dir == Looking.RIGHT
	
	# Call the virtual that plays the idle animation
	_play_idle()
	
	await get_tree().create_timer(0.2).timeout


func queue_walk(target_pos: Vector2) -> Callable:
	return func (): await walk(target_pos)


func walk(target_pos: Vector2) -> void:
	is_moving = true
	_looking_dir = Looking.LEFT if target_pos.x < position.x else Looking.RIGHT

	# Make the char face in the correct direction
	face_direction(target_pos)
	# The ROOM will take care of moving the character
	# and face her in the correct direction from here

	if has_node('Sprite2D'):
		match flips_when:
			FlipsWhen.LOOKING_LEFT:
				$Sprite2D.flip_h = target_pos.x < position.x
			FlipsWhen.LOOKING_RIGHT:
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
	
	# Trigger the signal for the room to start moving the character
	started_walk_to.emit(self, position, target_pos)
	await move_ended
	is_moving = false


func queue_stop_walking() -> Callable:
	return func (): await stop_walking()
	
	
func stop_walking() -> void:
	is_moving = false
	
	stopped_walk.emit()
	
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
			$Sprite2D.flip_h = flips_when == FlipsWhen.LOOKING_LEFT
		
		await face_left()
	else:
		if has_node('Sprite2D'):
			$Sprite2D.flip_h = flips_when == FlipsWhen.LOOKING_RIGHT
		
		await face_right()


func queue_say(dialog: String, emo := "") -> Callable:
	return func (): await say(dialog, emo)


func say(dialog: String, emo := "") -> void:
	if E.cutscene_skipped:
		await get_tree().process_frame
		return
	
	if not emo.is_empty():
		emotion = emo
	
	# Call the virtual that plays the talk animation
	_play_talk()
	
	var vo_name := _get_vo_cue(emotion)
	if not vo_name.is_empty() and A.get(vo_name):
		A[vo_name].play(false, global_position)
	
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
	await walk(E.current_room.to_global(pos))


func queue_walk_to_clicked(offset := Vector2.ZERO) -> Callable:
	return func (): await walk_to_clicked(offset)


func walk_to_clicked(offset := Vector2.ZERO) -> void:
	await _walk_to_node(E.clicked, offset)


func queue_walk_to_prop(id: String, offset := Vector2.ZERO) -> Callable:
	return func(): await walk_to_prop(id, offset)


func walk_to_prop(id: String, offset := Vector2.ZERO) -> void:
	await _walk_to_node(E.current_room.get_prop(id), offset)


func queue_walk_to_hotspot(id: String, offset := Vector2.ZERO) -> Callable:
	return func(): await walk_to_hotspot(id, offset)


func walk_to_hotspot(id: String, offset := Vector2.ZERO) -> void:
	await _walk_to_node(E.current_room.get_hotspot(id), offset)


func queue_walk_to_marker(id: String, offset := Vector2.ZERO) -> Callable:
	return func(): await walk_to_marker(id, offset)


func walk_to_marker(id: String, offset := Vector2.ZERO) -> void:
	await _walk_to_node(E.current_room.get_marker(id), offset)


func queue_set_emotion(new_emotion: String) -> Callable:
	return func(): emotion = new_emotion


func queue_ignore_walkable_areas(new_value: bool) -> Callable:
	return func(): ignore_walkable_areas = new_value


func queue_play_animation(animation_label: String, animation_fallback := 'idle', blocking := false) -> Callable:
	return func(): await play_animation(animation_label, animation_fallback)


func queue_stop_animation():
	return func(): await stop_animation()


func queue_halt_animation():
	return func(): halt_animation()


func queue_pause_animation():
	return func(): pause_animation()


func queue_resume_animation():
	return func(): resume_animation()


func play_animation(animation_label: String, animation_fallback := 'idle'):
	if not has_node("AnimationPlayer"):
		printerr("Can't play character animation. Required AnimationPlayer not found in character %s" % [script_name])
		return

	# Search for a valid animation corresponding to animation_label
	var animation = _get_valid_oriented_animation(animation_label)
	# If is not present, do the same for the the fallback animation.
	if animation == null: animation = _get_valid_oriented_animation(animation_fallback)
	# In neither are available, exit and throw an error to check for the presence of the animations.
	if animation == null: # Again!
		printerr("Neither the requested nor the fallback animation could be found for character %s. Requested: %s - Fallback: %s" % [script_name, animation_label, animation_fallback])
		return
	# Play the animation in the best available orientation
	$AnimationPlayer.play(animation)
	# If the playing is blocking, wait for the animation to finish
	await $AnimationPlayer.animation_finished
	
	# Go back to idle state
	_play_idle()


func stop_animation():
	# If the animation is not looping or is an idle one, do nothing
	if  $AnimationPlayer.get_animation($AnimationPlayer.current_animation) == Animation.LOOP_NONE or \
		$AnimationPlayer.current_animation == 'idle' or \
		$AnimationPlayer.current_animation.begins_with('idle_'):
		return
	# save the loop mode, wait for the anim to be over as designed, then restore the mode
	var animation = $AnimationPlayer.get_animation($AnimationPlayer.current_animation)
	var animation_loop_mode = animation.loop_mode
	animation.loop_mode = Animation.LOOP_NONE
	await $AnimationPlayer.animation_finished
	_play_idle()
	animation.loop_mode = animation_loop_mode


func halt_animation():
	_play_idle()


func pause_animation():
	$AnimationPlayer.pause()


func resume_animation():
	$AnimationPlayer.play()


func face_direction(destination: Vector2):
	# Get the vector from the origin to the destination.
	var vectX = destination.x - position.x
	var vectY = destination.y - position.y
	# Determine the angle of the movement vector.
	var rad = atan2(vectY, vectX)
	var angle = rad_to_deg(rad)
	# Tolerance in degrees, to avoid U D L R are only
	# achieved on precise angles such as 0 90 180 deg.
	var t = 22.5
	# Determine the direction the character is facing.
	# Remember: Y coordinates have opposite sign in Godot.
	# this means that negative angles are up movements.
	# Set the direction using the _looking property.
	# We cannot use the face_* functions because they
	# set the state as IDLE.
	if angle >= -(0 + t) and angle < (0 + t):
		_looking_dir = Looking.RIGHT
	elif angle >= (0 + t) and angle < (90 - t):
		_looking_dir = Looking.DOWN_RIGHT
	elif angle >= (90 - t) and angle < (90 + t):
		_looking_dir = Looking.DOWN
	elif angle >= (90 + t) and angle < (180 - t):
		_looking_dir = Looking.DOWN_LEFT
	elif angle >= (180 - t) or angle <= -(180 -t ):
		_looking_dir = Looking.LEFT
	elif angle <= -(0 + t) and angle > -(90 - t):
		_looking_dir = Looking.UP_RIGHT
	elif angle <= -(90 - t) and angle > -(90 + t):
		_looking_dir = Looking.UP
	elif angle <= -(90 + t) and angle > -(180 - t):
		_looking_dir = Looking.UP_LEFT


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func get_dialog_pos() -> float:
	return $DialogPos.position.y


func set_voices(value: Array) -> void:
	voices = value
	
	for idx in value.size():
		if not value[idx]:
			var arr: Array[AudioCueSound] = []
			
			voices[idx] = {
				emotion = '',
				variations = arr
			}
			
			notify_property_list_changed()
		elif not value[idx].variations.is_empty():
			if value[idx].variations[-1] == null:
				value[idx].variations[-1] = AudioCueSound.new()
			
			notify_property_list_changed()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _translate() -> void:
	if Engine.is_editor_hint() or not is_inside_tree(): return
	description = E.get_text(_description_code)


func _get_vo_cue(emotion := '') -> String:
	for v in voices:
		if v.emotion.to_lower() == emotion.to_lower():
			var cue_name := ""
			
			if not v.variations.is_empty():
				if not v.has('not_played') or v.not_played.is_empty():
					v['not_played'] = range(v.variations.size())
				
				var idx: int = (v['not_played'] as Array).pop_at(
					PopochiuUtils.get_random_array_idx(v['not_played'])
				)
				
				cue_name = v.variations[idx].resource_name
			
			return cue_name
	return ''


func _get_valid_oriented_animation(animation_label):
	var suffixes = []
	# Based on the character facing direction, define a set of
	# animation suffixes in èreference order.
	# Notice how we seek for opposite directions for left and
	# right. Flipping is done in other functions. We just define
	# a preference order for animations when available.
	match _looking_dir:
		Looking.DOWN_LEFT: suffixes = ['_dl', '_l', '_dr', '_r']
		Looking.UP_LEFT: suffixes = ['_ul', '_l', '_ur', '_r']
		Looking.LEFT: suffixes = ['_l', '_r']
		Looking.UP_RIGHT: suffixes = ['_ur', '_r', '_ul', '_l']
		Looking.DOWN_RIGHT: suffixes = ['_dr', '_r', '_dl', '_l']
		Looking.RIGHT: suffixes = ['_r', '_l']
		Looking.DOWN: suffixes = ['_d', '_l', '_r']
		Looking.UP: suffixes = ['_u', '_l', '_r']
	# Add an empty suffix to support the most
	# basic animation case  (ex. just "walk").
	suffixes = suffixes + ['']
	# The list of prefixes is in order of preference
	# Eg. walk_dl, walk_l, walk
	# Scan the AnimationPlayer and return the first that matches.
	for suffix in suffixes:
		var animation = "%s%s" % [animation_label, suffix]
		if $AnimationPlayer.has_animation(animation):
			return animation
	# No valid animation is found.
	printerr('Animation not found %s' % [animation_label])
	return null


func _walk_to_node(node: Node2D, offset: Vector2) -> void:
	if not is_instance_valid(node):
		await get_tree().process_frame
		return

	await walk(node.to_global(node.walk_to_point if node is PopochiuClickable else Vector2.ZERO) + offset)
