@tool
@icon('res://addons/popochiu/icons/character.png')
class_name PopochiuCharacter
extends PopochiuClickable
## Any object that can move, walk, navigate rooms, or have an inventory.

## Determines when to flip the [b]$Sprite2D[/b] child.
enum FlipsWhen {
	## The [b]$Sprite2D[/b] child is not flipped.
	NONE,
	## The [b]$Sprite2D[/b] child is flipped when the character is looking to the right.
	LOOKING_RIGHT,
	## The [b]$Sprite2D[/b] child is flipped when the character is looking to the left.
	LOOKING_LEFT
}
## Determines the direction the character is facing
enum Looking {
	## The character is facing up [code](0, -y)[/code].
	UP,
	## The character is facing up-right [code](x, -y)[/code].
	UP_RIGHT,
	## The character is facing right [code](x, 0)[/code].
	RIGHT,
	## The character is facing down-right [code](x, y)[/code].
	DOWN_RIGHT,
	## The character is facing down [code](0, y)[/code].
	DOWN,
	## The character is facing down-left [code](-x, y)[/code].
	DOWN_LEFT,
	## The character is facing left [code](-x, 0)[/code].
	LEFT,
	## The character is facing up-left [code](-x, -y)[/code].
	UP_LEFT
}

## Emitted when the character starts walking. As parameters, it sends itself, the starting position
## and the ending position. [PopochiuRoom]s connect to this signal in order to make characters move
## inside them from one point to another.
signal started_walk_to(character: PopochiuCharacter, start: Vector2, end: Vector2)
## Emitted when the character is forced to stop while walking.
signal stopped_walk
## Emitted when the character reaches the ending position when moving from one point to another.
signal move_ended

## The [Color] in which the dialogue lines of the character are rendered.
@export var text_color := Color.WHITE
## Depending on its value, the [b]$Sprite2D[/b] child will be flipped horizontally depending on
## which way the character is facing. If the value is [constant NONE], then the
## [b]$Sprite2D[/b] child won't be flipped.
@export var flips_when: FlipsWhen = FlipsWhen.NONE
## Array of [Dictionary] where each element has
## [code]{ emotion: String, variations: Array[PopochiuAudioCue] }[/code].
## You can use this to define which [PopochiuAudioCue]s to play when the character speaks using a 
## specific emotion.
@export var voices := [] : set = set_voices
## Whether the character should follow the player-controlled character (PC) when it moves through
## the room.
@export var follow_player := false
## The offset between the player-controlled character (PC) and this character when it follows the
## former one.
@export var follow_player_offset := Vector2(20,0)
## Array of [Dictionary] where each element has [code]{ emotion: String, avatar: Texture }[/code].
## You can use this to define which [Texture] to use as avatar for the character when it speaks
## using a specific emotion.
@export var avatars := [] : set = set_avatars
## The speed at which the character will move in pixels per frame.
@export var walk_speed := 200.0
## Whether the character can or not move.
@export var can_move := true
## Whether the character ignores or not walkable areas. If [code]true[/code], the character will
## move to any point in the room clicked by players without taking into account the walkable areas
## in it.
@export var ignore_walkable_areas := false
## Whether the character will move only when the frame changes on its animation.
@export var anti_glide_animation: bool = false
# This category is used by the Aseprite Importer in order to allow the creation of a section in the
# Inspector for the character.
@export_category("Aseprite")

## The stored position of the character. Used when [member anti_glide_animation] is
## [code]true[/code].
var position_stored = null
## Stores the [member PopochiuRoom.script_name] of the preiously visited [PopochiuRoom].
var last_room := ''
## The suffix text to add to animation names.
var anim_suffix := ''
## Whether the character is or not moving through the room.
var is_moving := false
## The current emotion used by the character.
var emotion := ''
## 
var on_scaling_region: Dictionary = {}
## Stores the default walk speed defined in [member walk_speed]. Used by [PopochiuRoom] when scaling
## the character if it is inside a [PopochiuRegion] that modifies the scale.
var default_walk_speed := 0
## Stores the default scale. Used by [PopochiuRoom] when scaling the character if it is inside a
## [PopochiuRegion] that modifies the scale.
var default_scale := Vector2.ONE

var _looking_dir: int = Looking.DOWN

## A to the [b]$DialogPos[/b] child. Used by the GUI to calculate where to render the dialogue lines
## said by the character when it speaks.
@onready var dialog_pos: Marker2D = $DialogPos


#region Godot ######################################################################################
func _ready():
	super()
	default_walk_speed = walk_speed
	default_scale = Vector2(scale)
	if not Engine.is_editor_hint():
		set_process(follow_player)
	else:
		hide_helpers()
		set_process(true)
	
	for child in get_children():
		if not child is Sprite2D:
			continue
		child.frame_changed.connect(_update_position)
		
func _get_property_list():
	return [
		{
			name = "popochiu_placeholder",
			type = TYPE_NIL,
		}
	]


#endregion

#region Virtual ####################################################################################
## Use it to play the idle animation of the character.
## [i]Virtual[/i].
func _play_idle() -> void:
	play_animation('idle')


## Use it to play the walk animation of the character.
## [i]Virtual[/i].
func _play_walk(target_pos: Vector2) -> void:
	# Set the default parameters for play_animation()
	var animation_label = 'walk'
	var animation_fallback = 'idle'
	
	play_animation(animation_label, animation_fallback)


## Use it to play the talk animation of the character.
## [i]Virtual[/i].
func _play_talk() -> void:
	play_animation('talk')


## Use it to play the grab animation of the character.
## [i]Virtual[/i].
func _play_grab() -> void:
	play_animation('grab')


#endregion

#region Public #####################################################################################
## Puts the character in the idle state by playing its idle animation, then waits for
## [code]0.2[/code] seconds.
## If the characer has a [b]$Sprite2D[/b] child, it makes it flip based on the [member flips_when]
## value.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_idle() -> Callable:
	return func (): await idle()
	
	
## Puts the character in the idle state by playing its idle animation, then waits for
## [code]0.2[/code] seconds.
## If the characer has a [b]$Sprite2D[/b] child, it makes it flip based on the [member flips_when]
## value.
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


## Makes the character move to [param target_pos] and plays its walk animation.
## If the characer has a [b]$Sprite2D[/b] child, it makes it flip based on the [member flips_when]
## value.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk(target_pos: Vector2) -> Callable:
	return func (): await walk(target_pos)


## Makes the character move to [param target_pos] and plays its walk animation.
## If the characer has a [b]$Sprite2D[/b] child, it makes it flip based on the [member flips_when]
## value.
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

func take_turn(target_pos: Vector2):
	face_direction(target_pos)
	_play_walk(target_pos)

## Makes the character stop moving and emits [signal stopped_walk].
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_stop_walking() -> Callable:
	return func (): await stop_walking()


## Makes the character stop moving and emits [signal stopped_walk].
func stop_walking() -> void:
	is_moving = false
	
	stopped_walk.emit()
	
	await get_tree().process_frame


## Makes the character to look up by setting [member _looking_dir] to [constant UP] and waits until
## [method idle] finishes.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_up() -> Callable:
	return func (): await face_up()


## Makes the character to look up by setting [member _looking_dir] to [constant UP] and waits until
## [method idle] finishes.
func face_up() -> void:
	_looking_dir = Looking.UP
	await idle()


## Makes the character to look up and right by setting [member _looking_dir] to [constant UP_RIGHT]
## and waits until [method idle] finishes.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_up_right() -> Callable:
	return func (): await face_up_right()


## Makes the character to look up and right by setting [member _looking_dir] to [constant UP_RIGHT]
## and waits until [method idle] finishes.
func face_up_right() -> void:
	_looking_dir = Looking.UP_RIGHT
	await idle()


## Makes the character to look right by setting [member _looking_dir] to [constant RIGHT] and waits
## until [method idle] finishes.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_right() -> Callable:
	return func (): await face_right()


## Makes the character to look right by setting [member _looking_dir] to [constant RIGHT] and waits
## until [method idle] finishes.
func face_right() -> void:
	_looking_dir = Looking.RIGHT
	await idle()


## Makes the character to look down and right by setting [member _looking_dir] to
## [constant DOWN_RIGHT] and waits until [method idle] finishes.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_down_right() -> Callable:
	return func (): await face_down_right()


## Makes the character to look down and right by setting [member _looking_dir] to
## [constant DOWN_RIGHT] and waits until [method idle] finishes.
func face_down_right() -> void:
	_looking_dir = Looking.DOWN_RIGHT
	await idle()


## Makes the character to look down by setting [member _looking_dir] to [constant DOWN] and waits
## until [method idle] finishes.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_down() -> Callable:
	return func (): await face_down()


## Makes the character to look down by setting [member _looking_dir] to [constant DOWN] and waits
## until [method idle] finishes.
func face_down() -> void:
	_looking_dir = Looking.DOWN
	await idle()


## Makes the character to look down and left by setting [member _looking_dir] to
## [constant DOWN_LEFT] and waits until [method idle] finishes.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_down_left() -> Callable:
	return func (): await face_down_left()


## Makes the character to look down and left by setting [member _looking_dir] to
## [constant DOWN_LEFT] and waits until [method idle] finishes.
func face_down_left() -> void:
	_looking_dir = Looking.DOWN_LEFT
	await idle()


## Makes the character to look left by setting [member _looking_dir] to [constant LEFT] and waits
## until [method idle] finishes.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_left() -> Callable:
	return func (): await face_left()


## Makes the character to look left by setting [member _looking_dir] to [constant LEFT] and waits
## until [method idle] finishes.
func face_left() -> void:
	_looking_dir = Looking.LEFT
	await idle()


## Makes the character to look up and left by setting [member _looking_dir] to [constant UP_LEFT]
## and waits until [method idle] finishes.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_up_left() -> Callable:
	return func (): await face_up_left()


## Makes the character to look up and left by setting [member _looking_dir] to [constant UP_LEFT]
## and waits until [method idle] finishes.
func face_up_left() -> void:
	_looking_dir = Looking.UP_LEFT
	await idle()


## Makes the character face in the direction of the last clicked [PopochiuClickable], which is
## stored in [member Popochiu.clicked].
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_clicked() -> Callable:
	return func (): await face_clicked()


## Makes the character face in the direction of the last clicked [PopochiuClickable], which is
## stored in [member Popochiu.clicked].
func face_clicked() -> void:
	if E.clicked.global_position < global_position:
		if has_node('Sprite2D'):
			$Sprite2D.flip_h = flips_when == FlipsWhen.LOOKING_LEFT
		
		await face_left()
	else:
		if has_node('Sprite2D'):
			$Sprite2D.flip_h = flips_when == FlipsWhen.LOOKING_RIGHT
		
		await face_right()


## Calls [method _play_talk] and emits [signal character_spoke] sending itself as parameter, and the
## [param dialog] line to show on screen. You can specify the emotion to use with [param emo]. If an
## [AudioCue] is defined for the emotion, it is played. Once the talk animation finishes, the
## characters return to its idle state.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_say(dialog: String, emo := "") -> Callable:
	return func (): await say(dialog, emo)


## Calls [method _play_talk] and emits [signal character_spoke] sending itself as parameter, and the
## [param dialog] line to show on screen. You can specify the emotion to use with [param emo]. If an
## [AudioCue] is defined for the emotion, it is played. Once the talk animation finishes, the
## characters return to its idle state.
func say(dialog: String, emo := "") -> void:
	if E.cutscene_skipped:
		await get_tree().process_frame
		return
	
	# Blocks the graphic interface so players can't interact with it while the
	# dialog line plays
	# NOTE: What if players want NPCs talking without blocking the graphic
	# 		interface?
	G.block()
	
	if not emo.is_empty():
		emotion = emo
	
	# Call the virtual that plays the talk animation
	_play_talk()
	
	var vo_name := _get_vo_cue(emotion)
	if not vo_name.is_empty() and A.get(vo_name):
		A[vo_name].play(false, global_position)
	
	C.character_spoke.emit(self, dialog)
	
	await G.dialog_line_finished
	
	emotion = ''
	idle()
	
	# Unblock the graphic interface with a delay to prevent cursor flickering
	# (rapid state changes) between multiple lines of text or actions in sequence
	G.unblock(true)


## Calls [method _play_grab] and waits until the [signal character_grab_done] is emitted, then goes
## back to [method idle].
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_grab() -> Callable:
	return func (): await grab()


## Calls [method _play_grab] and waits until the [signal character_grab_done] is emitted, then goes
## back to [method idle].
func grab() -> void:
	if E.cutscene_skipped:
		await get_tree().process_frame
		return
	
	# Call the virtual that plays the grab animation
	_play_grab()
	
	await C.character_grab_done
	
	idle()


## Calls [method PopochiuClickable.hide_helpers] and then hides the `$DialogPos` child.
func hide_helpers() -> void:
	super()
	
	if is_instance_valid(dialog_pos):
		dialog_pos.hide()


## Calls [method PopochiuClickable.show_helpers] and then shows the `$DialogPos` child.
func show_helpers() -> void:
	super()
	
	if is_instance_valid(dialog_pos):
		dialog_pos.show()


## Makes the character walk to [param pos].
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to(pos: Vector2) -> Callable:
	return func(): await walk_to(pos)


## Makes the character walk to [param pos].
func walk_to(pos: Vector2) -> void:
	await walk(E.current_room.to_global(pos))


## Makes the character walk to the last clicked [PopochiuClickable], which is stored in
## [member Popochiu.clicked]. You can set an [param offset] relative to the target position.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to_clicked(offset := Vector2.ZERO) -> Callable:
	return func (): await walk_to_clicked(offset)


## Makes the character walk to the last clicked [PopochiuClickable], which is stored in
## [member Popochiu.clicked]. You can set an [param offset] relative to the target position.
func walk_to_clicked(offset := Vector2.ZERO) -> void:
	await _walk_to_node(E.clicked, offset)


## Makes the character walk to the [PopochiuProp] (in the current room) which
## [member PopochiuClickable.script_name] is equal to [param id]. You can set an [param offset]
## relative to the target position.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to_prop(id: String, offset := Vector2.ZERO) -> Callable:
	return func(): await walk_to_prop(id, offset)


## Makes the character walk to the [PopochiuProp] (in the current room) which
## [member PopochiuClickable.script_name] is equal to [param id]. You can set an [param offset]
## relative to the target position.
func walk_to_prop(id: String, offset := Vector2.ZERO) -> void:
	await _walk_to_node(E.current_room.get_prop(id), offset)


## Makes the character walk to the [PopochiuHotspot] (in the current room) which
## [member PopochiuClickable.script_name] is equal to [param id]. You can set an [param offset]
## relative to the target position.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to_hotspot(id: String, offset := Vector2.ZERO) -> Callable:
	return func(): await walk_to_hotspot(id, offset)


## Makes the character walk to the [PopochiuHotspot] (in the current room) which
## [member PopochiuClickable.script_name] is equal to [param id]. You can set an [param offset]
## relative to the target position.
func walk_to_hotspot(id: String, offset := Vector2.ZERO) -> void:
	await _walk_to_node(E.current_room.get_hotspot(id), offset)


## Makes the character walk to the [Marker2D] (in the current room) which [member Node.name] is
## equal to [param id]. You can set an [param offset] relative to the target position.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to_marker(id: String, offset := Vector2.ZERO) -> Callable:
	return func(): await walk_to_marker(id, offset)


## Makes the character walk to the [Marker2D] (in the current room) which [member Node.name] is
## equal to [param id]. You can set an [param offset] relative to the target position.
func walk_to_marker(id: String, offset := Vector2.ZERO) -> void:
	await _walk_to_node(E.current_room.get_marker(id), offset)


## Sets [member emotion] to [param new_emotion] when in a [method Popochiu.queue].
func queue_set_emotion(new_emotion: String) -> Callable:
	return func(): emotion = new_emotion


## Sets [member ignore_walkable_areas] to [param new_value] when in a [method Popochiu.queue].
func queue_ignore_walkable_areas(new_value: bool) -> Callable:
	return func(): ignore_walkable_areas = new_value


## Plays the [param animation_label] animation. You can specify a fallback animation to play with
## [param animation_fallback] in case the former one doesn't exists.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_play_animation(
	animation_label: String, animation_fallback := 'idle', blocking := false
) -> Callable:
	return func(): await play_animation(animation_label, animation_fallback)


## Plays the [param animation_label] animation. You can specify a fallback animation to play with
## [param animation_fallback] in case the former one doesn't exists.
func play_animation(animation_label: String, animation_fallback := 'idle'):
	if not has_node("AnimationPlayer"):
		PopochiuUtils.print_error(
			"Can't play character animation. Required AnimationPlayer not found in character %s" %
			[script_name]
		)
		return

	# Search for a valid animation corresponding to animation_label
	var animation = _get_valid_oriented_animation(animation_label)
	# If is not present, do the same for the the fallback animation.
	if animation == null: animation = _get_valid_oriented_animation(animation_fallback)
	# In neither are available, exit and throw an error to check for the presence of the animations.
	if animation == null: # Again!
		PopochiuUtils.print_error(
			"Neither the requested nor the fallback animation could be found for character %s.\
 Requested: %s - Fallback: %s" % [script_name, animation_label, animation_fallback]
		)
		return
	# Play the animation in the best available orientation
	$AnimationPlayer.play(animation)
	# If the playing is blocking, wait for the animation to finish
	await $AnimationPlayer.animation_finished
	
	# Go back to idle state
	_play_idle()


## Makes the animation that is currently playing to stop. Works only if it is looping and is not an
## idle animation. The animation stops when the current loop finishes.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_stop_animation():
	return func(): await stop_animation()


## Makes the animation that is currently playing to stop. Works only if it is looping and is not an
## idle animation. The animation stops when the current loop finishes.
func stop_animation():
	# If the animation is not looping or is an idle one, do nothing
	if  (
		$AnimationPlayer.get_animation($AnimationPlayer.current_animation) == Animation.LOOP_NONE or
		$AnimationPlayer.current_animation == 'idle' or
		$AnimationPlayer.current_animation.begins_with('idle_')
	):
		return
	
	# Save the loop mode, wait for the anim to be over as designed, then restore the mode
	var animation = $AnimationPlayer.get_animation($AnimationPlayer.current_animation)
	var animation_loop_mode = animation.loop_mode
	animation.loop_mode = Animation.LOOP_NONE
	
	await $AnimationPlayer.animation_finished
	
	_play_idle()
	animation.loop_mode = animation_loop_mode


## Immediately stops the animation that is currently playing by changing to the idle animation.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_halt_animation():
	return func(): halt_animation()


## Immediately stops the animation that is currently playing by changing to the idle animation.
func halt_animation():
	_play_idle()


## Pauses the animation that is currently playing.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_pause_animation():
	return func(): pause_animation()


## Pauses the animation that is currently playing.
func pause_animation():
	$AnimationPlayer.pause()


## Resumes the current animation (that was previously paused).
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_resume_animation():
	return func(): resume_animation()


## Resumes the current animation (that was previously paused).
func resume_animation():
	$AnimationPlayer.play()


## Makes the character look in the direction of [param destination]. The result is one of the values
## defined by [enum Looking].
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


## Returns the [Texture] of the avatar defined for the [param emo] emotion.
## Returns [code]null[/code] if no avatar is found. If there is an avatar defined for the
## [code]""[/code] emotion, that one is returned by default.
func get_avatar_for_emotion(emo := "") -> Texture:
	var texture: Texture = null
	
	while not texture:
		for dic in avatars:
			if dic.emotion == "":
				texture = dic.avatar
			elif dic.emotion == emo:
				texture = dic.avatar
				break
	
	return texture


## Returns the [code]y[/code] value of the [b]$DialogPos[/b] [Marker2D] (the node that defines the
## position of the dialog lines said by the character when it talks).
func get_dialog_pos() -> float:
	return $DialogPos.position.y


#endregion

#region SetGet #####################################################################################
func set_voices(value: Array) -> void:
	voices = value
	
	for idx in value.size():
		if not value[idx]:
			var arr: Array[AudioCueSound] = []
			
			voices[idx] = {
				emotion = '',
				variations = arr
			}
		elif not value[idx].variations.is_empty():
			if value[idx].variations[-1] == null:
				value[idx].variations[-1] = AudioCueSound.new()


func set_avatars(value: Array) -> void:
	avatars = value
	
	for idx in value.size():
		if not value[idx]:
			avatars[idx] = {
				emotion = '',
				avatar = Texture.new(),
			}


#endregion

#region Private ####################################################################################
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

	await walk(
		node.to_global(node.walk_to_point if node is PopochiuClickable else Vector2.ZERO) + offset
	)

func _update_position():
	E.current_room.update_characters_position(self)


#endregion
