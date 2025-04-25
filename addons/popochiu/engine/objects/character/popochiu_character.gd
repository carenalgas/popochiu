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
	UP_LEFT,
	## The character is facing up [code](0, -y)[/code].
	UP,
	## The character is facing up-right [code](x, -y)[/code].
	UP_RIGHT
	## The character is facing right [code](x, 0)[/code].
}

## Emitted when a [param character] starts moving from [param start] to [param end]. [PopochiuRoom]
## connects to this signal in order to make characters move inside them from one point to another.
signal started_walk_to(character: PopochiuCharacter, start: Vector2, end: Vector2)
## Emitted when the character is forced to stop while walking.
signal stopped_walk
## Emitted when the character reaches the ending position when moving from one point to another.
signal move_ended
## Emitted when the animation to grab things has finished.
signal grab_done

## Empty string constant to perform type checks (String is not nullable in GDScript. See #381, #382).
const EMPTY_STRING = ""

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
@export var voices := []: set = set_voices
## Whether the character should follow the player-controlled character (PC) when it moves through
## the room.
@export var follow_player := false: set = set_follow_player
## The offset between the player-controlled character (PC) and this character when it follows the
## former one.
@export var follow_player_offset := Vector2(20, 0)
## Array of [Dictionary] where each element has [code]{ emotion: String, avatar: Texture }[/code].
## You can use this to define which [Texture] to use as avatar for the character when it speaks
## using a specific emotion.
@export var avatars := []: set = set_avatars
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
## Used by the GUI to calculate where to render the dialogue lines said by the character when it
## speaks.
@export var dialog_pos: Vector2
# This category is used by the Aseprite Importer in order to allow the creation of a section in the
# Inspector for the character.
@export_category("Aseprite")

## The stored position of the character. Used when [member anti_glide_animation] is
## [code]true[/code].
var position_stored = null
## Stores the [member PopochiuRoom.script_name] of the previously visited [PopochiuRoom].
var last_room := EMPTY_STRING
## The suffix text to add to animation names.
var anim_suffix := EMPTY_STRING
## Whether the character is or not moving through the room.
var is_moving := false
## The current emotion used by the character.
var emotion := EMPTY_STRING
##
var on_scaling_region: Dictionary = {}
## Stores the default walk speed defined in [member walk_speed]. Used by [PopochiuRoom] when scaling
## the character if it is inside a [PopochiuRegion] that modifies the scale.
var default_walk_speed := 0
## Stores the default scale. Used by [PopochiuRoom] when scaling the character if it is inside a
## [PopochiuRegion] that modifies the scale.
var default_scale := Vector2.ONE
# Holds the direction the character is looking at.
# Initialized to DOWN.
var _looking_dir: int = Looking.DOWN
# Holds a suffixes fallback list for the animations to play.
# Initialized to the suffixes corresponding to the DOWN direction.
var _animation_suffixes: Array = ['_d', '_dr', '_dl', '_r', '_l', EMPTY_STRING]
# Holds the last PopochiuClickable that the character reached.
var _last_reached_clickable: PopochiuClickable = null
# Holds the animation that's currently selected in the character's AnimationPlayer.
var _current_animation: String = "null"
# Holds the last animation category requested for the character (idle, walk, talk, grab, ...).
var _last_requested_animation_label: String = "null"
# Holds the direction the character was looking at when the current animation was requested.
var _last_requested_animation_dir: int = -1

@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Array of the animation suffixes to search for
# based on the angle the character is facing.
var _valid_animation_suffixes = [
['_r', '_l', '_dr', '_dl', '_d'], #    0 - 22.5 degrees
['_dr', '_dl', '_r' , '_l', '_d'], #  22.5 - 45 degrees
['_dr', '_dl', '_d' , '_r', '_l'], #  45 - 67.5 degrees
['_d', '_dr', '_dl', '_r', '_l'], #   67.5 - 90 degrees
['_d', '_dl', '_dr', '_l', '_r'], #  90 - 112.5 degrees
['_dl', '_dr', '_d', '_l', '_r'], # 112.5 - 135 degrees
['_dl', '_dr', '_l', '_r', '_d'], # 135 - 157.5 degrees
['_l', '_r', '_dl', '_dr', '_d'], # 157.5 - 180 degrees
['_l', '_r', '_ul', '_ur', '_u'], # 180 - 202.5 degrees
['_ul', '_ur', '_l', '_r', '_u'], # 202.5 - 225 degrees
['_ul', '_ur', '_u', '_l', '_r'], # 225 - 247.5 degrees
['_u', '_ul', '_ur', '_l', '_r'], # 247.5 - 270 degrees
['_u', '_ur', '_ul', '_r', '_l'], # 270 - 292.5 degrees
['_ur', '_ul', '_u', '_r', '_l'], # 292.5 - 315 degrees
['_ur', '_ul', '_r', '_l', '_u'], # 315 - 337.5 degrees
['_r', '_l', '_ur', '_ul', '_u']] # 337.5 - 360 degrees

#region Godot ######################################################################################
func _ready():
	super()

	default_walk_speed = walk_speed
	default_scale = Vector2(scale)

	if Engine.is_editor_hint():
		hide_helpers()
		set_process(true)
	else:
		set_process(follow_player)

	for child in get_children():
		if not child is Sprite2D:
			continue
		child.frame_changed.connect(_update_position)

	move_ended.connect(_on_move_ended)


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


func _on_move_ended() -> void:
	pass


#endregion

#region Public #####################################################################################
## Puts the character in the idle state by playing its idle animation, then waits for
## [code]0.2[/code] seconds.
## If the character has a [b]$Sprite2D[/b] child, it makes it flip based on the [member flips_when]
## value.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_idle() -> Callable:
	return func(): await idle()


## Puts the character in the idle state by playing its idle animation, then waits for
## [code]0.2[/code] seconds.
## If the character has a [b]$Sprite2D[/b] child, it makes it flip based on the [member flips_when]
## value.
func idle() -> void:
	if PopochiuUtils.e.cutscene_skipped:
		await get_tree().process_frame
		return

	_flip_left_right(
		_looking_dir in [Looking.LEFT, Looking.DOWN_LEFT, Looking.UP_LEFT],
		_looking_dir in [Looking.RIGHT, Looking.DOWN_RIGHT, Looking.UP_RIGHT]
	)

	# Call the virtual that plays the idle animation
	_play_idle()

	await get_tree().create_timer(0.2).timeout


## Makes the character move to [param target_pos] and plays its walk animation.
## If the character has a [b]$Sprite2D[/b] child, it makes it flip based on the [member flips_when]
## value.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk(target_pos: Vector2) -> Callable:
	return func(): await walk(target_pos)


## Makes the character move to [param target_pos] and plays its walk animation.
## If the character has a [b]$Sprite2D[/b] child, it makes it flip based on the [member flips_when]
## value.
func walk(target_pos: Vector2) -> void:
	is_moving = true
	_last_reached_clickable = null

	# The ROOM will take care of moving the character
	# and face her in the correct direction from here

	_flip_left_right(
		target_pos.x < position.x,
		target_pos.x > position.x
	)

	if PopochiuUtils.e.cutscene_skipped:
		is_moving = false
		await get_tree().process_frame

		position = target_pos
		PopochiuUtils.e.camera.position = target_pos
		await get_tree().process_frame

		return

	# Call the virtual that plays the walk animation
	_play_walk(target_pos)

	# Trigger the signal for the room to start moving the character
	started_walk_to.emit(self, position, target_pos)
	await move_ended

	is_moving = false


func turn_towards(target_pos: Vector2) -> void:
	_flip_left_right(
		target_pos.x < position.x,
		target_pos.x > position.x
	)
	face_direction(target_pos)
	_play_walk(target_pos)

## Makes the character stop moving and emits [signal stopped_walk].[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_stop_walking() -> Callable:
	return func(): await stop_walking()


## Makes the character stop moving and emits [signal stopped_walk].
func stop_walking() -> void:
	is_moving = false

	stopped_walk.emit()

	await get_tree().process_frame


## Makes the character to look up by setting [member _looking_dir] to [constant UP] and waits until
## [method idle] finishes.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_up() -> Callable:
	return func(): await face_up()


## Makes the character to look up by setting [member _looking_dir] to [constant UP] and waits until
## [method idle] finishes.
func face_up() -> void:
	face_direction(position + Vector2.UP)
	await idle()


## Makes the character to look up and right by setting [member _looking_dir] to [constant UP_RIGHT]
## and waits until [method idle] finishes.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_up_right() -> Callable:
	return func(): await face_up_right()


## Makes the character to look up and right by setting [member _looking_dir] to [constant UP_RIGHT]
## and waits until [method idle] finishes.
func face_up_right() -> void:
	face_direction(position + Vector2.UP + Vector2.RIGHT)
	await idle()


## Makes the character to look right by setting [member _looking_dir] to [constant RIGHT] and waits
## until [method idle] finishes.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_right() -> Callable:
	return func(): await face_right()


## Makes the character to look right by setting [member _looking_dir] to [constant RIGHT] and waits
## until [method idle] finishes.
func face_right() -> void:
	face_direction(position + Vector2.RIGHT)
	await idle()


## Makes the character to look down and right by setting [member _looking_dir] to
## [constant DOWN_RIGHT] and waits until [method idle] finishes.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_down_right() -> Callable:
	return func(): await face_down_right()


## Makes the character to look down and right by setting [member _looking_dir] to
## [constant DOWN_RIGHT] and waits until [method idle] finishes.
func face_down_right() -> void:
	face_direction(position + Vector2.DOWN + Vector2.RIGHT)
	await idle()


## Makes the character to look down by setting [member _looking_dir] to [constant DOWN] and waits
## until [method idle] finishes.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_down() -> Callable:
	return func(): await face_down()


## Makes the character to look down by setting [member _looking_dir] to [constant DOWN] and waits
## until [method idle] finishes.
func face_down() -> void:
	face_direction(position + Vector2.DOWN)
	await idle()


## Makes the character to look down and left by setting [member _looking_dir] to
## [constant DOWN_LEFT] and waits until [method idle] finishes.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_down_left() -> Callable:
	return func(): await face_down_left()


## Makes the character to look down and left by setting [member _looking_dir] to
## [constant DOWN_LEFT] and waits until [method idle] finishes.
func face_down_left() -> void:
	face_direction(position + Vector2.DOWN + Vector2.LEFT)
	await idle()


## Makes the character to look left by setting [member _looking_dir] to [constant LEFT] and waits
## until [method idle] finishes.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_left() -> Callable:
	return func(): await face_left()


## Makes the character to look left by setting [member _looking_dir] to [constant LEFT] and waits
## until [method idle] finishes.
func face_left() -> void:
	face_direction(position + Vector2.LEFT)
	await idle()


## Makes the character to look up and left by setting [member _looking_dir] to [constant UP_LEFT]
## and waits until [method idle] finishes.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_up_left() -> Callable:
	return func(): await face_up_left()


## Makes the character to look up and left by setting [member _looking_dir] to [constant UP_LEFT]
## and waits until [method idle] finishes.
func face_up_left() -> void:
	face_direction(position + Vector2.UP + Vector2.LEFT)
	await idle()


## Makes the character face in the direction of the last clicked [PopochiuClickable], which is
## stored in [member Popochiu.clicked].[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_clicked() -> Callable:
	return func(): await face_clicked()


## Makes the character face in the direction of the last clicked [PopochiuClickable], which is
## stored in [member Popochiu.clicked].
func face_clicked() -> void:
	var global_lap = PopochiuUtils.e.clicked.to_global(PopochiuUtils.e.clicked.look_at_point)

	_flip_left_right(
		global_lap.x < global_position.x,
		global_lap.x > global_position.x
	)

	await face_direction(global_lap)


## Calls [method _play_talk] and emits [signal character_spoke] sending itself as parameter, and the
## [param dialog] line to show on screen. You can specify the emotion to use with [param emo]. If an
## [AudioCue] is defined for the emotion, it is played. Once the talk animation finishes, the
## characters return to its idle state.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_say(dialog: String, emo := EMPTY_STRING) -> Callable:
	return func(): await say(dialog, emo)


## Calls [method _play_talk] and emits [signal character_spoke] sending itself as parameter, and the
## [param dialog] line to show on screen. You can specify the emotion to use with [param emo]. If an
## [AudioCue] is defined for the emotion, it is played. Once the talk animation finishes, the
## characters return to its idle state.
func say(dialog: String, emo := EMPTY_STRING) -> void:
	if PopochiuUtils.e.cutscene_skipped:
		await get_tree().process_frame
		return

	if not emo.is_empty():
		emotion = emo

	# Call the virtual that plays the talk animation
	_play_talk()

	var vo_name := _get_vo_cue(emotion)
	if not vo_name.is_empty() and PopochiuUtils.a.get(vo_name):
		PopochiuUtils.a[vo_name].play(false, global_position)

	PopochiuUtils.c.character_spoke.emit(self, dialog)

	await PopochiuUtils.g.dialog_line_finished

	# Stop the voice if it is still playing (feature #202)
	# Fix: Check if the vo_name is valid in order to stop it
	if not vo_name.is_empty() and PopochiuUtils.a[vo_name].is_playing():
		PopochiuUtils.a[vo_name].stop(0.3)

	emotion = EMPTY_STRING
	idle()


## Calls [method _play_grab] and waits until the [signal grab_done] is emitted, then goes back to
## [method idle].[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_grab() -> Callable:
	return func(): await grab()


## Calls [method _play_grab] and waits until the [signal grab_done] is emitted, then goes back to
## [method idle].
func grab() -> void:
	if PopochiuUtils.e.cutscene_skipped:
		await get_tree().process_frame
		return

	# Call the virtual that plays the grab animation
	_play_grab()

	await grab_done

	idle()


## Calls [method PopochiuClickable.hide_helpers].
func hide_helpers() -> void:
	super()
	# TODO: add visibility logic for dialog_pos gizmo


## Calls [method PopochiuClickable.show_helpers].
func show_helpers() -> void:
	super()
	# TODO: add visibility logic for dialog_pos gizmo


## Makes the character walk to [param pos].[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to(pos: Vector2) -> Callable:
	return func(): await walk_to(pos)


## Makes the character walk to [param pos].
func walk_to(pos: Vector2) -> void:
	await walk(PopochiuUtils.r.current.to_global(pos))


## Makes the character walk to the last clicked [PopochiuClickable], which is stored in
## [member Popochiu.clicked]. You can set an [param offset] relative to the target position.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to_clicked(offset := Vector2.ZERO) -> Callable:
	return func(): await walk_to_clicked(offset)


## Makes the character walk (NON-BLOCKING) to the last clicked [PopochiuClickable], which is stored
## in [member Popochiu.clicked]. You can set an [param offset] relative to the target position.
func walk_to_clicked(offset := Vector2.ZERO) -> void:
	var clicked_id: String = PopochiuUtils.e.clicked.script_name

	if PopochiuUtils.e.clicked == _last_reached_clickable:
		await get_tree().process_frame
		return

	await _walk_to_node(PopochiuUtils.e.clicked, offset)
	_last_reached_clickable = PopochiuUtils.e.clicked

	# Check if the action was cancelled
	if not PopochiuUtils.e.clicked or clicked_id != PopochiuUtils.e.clicked.script_name:
		await PopochiuUtils.e.await_stopped


## Makes the character walk (BLOCKING the GUI) to the last clicked [PopochiuClickable], which is
## stored in [member Popochiu.clicked]. You can set an [param offset] relative to the target position.
func walk_to_clicked_blocking(offset := Vector2.ZERO) -> void:
	PopochiuUtils.g.block()

	await _walk_to_node(PopochiuUtils.e.clicked, offset)

	PopochiuUtils.g.unblock()


## Makes the character walk (BLOCKING the GUI) to the last clicked [PopochiuClickable], which is
## stored in [member Popochiu.clicked]. You can set an [param offset] relative to the target position.
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to_clicked_blocking(offset := Vector2.ZERO) -> Callable:
	return func(): await walk_to_clicked_blocking(offset)


## Makes the character walk to the [PopochiuProp] (in the current room) which
## [member PopochiuClickable.script_name] is equal to [param id]. You can set an [param offset]
## relative to the target position.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to_prop(id: String, offset := Vector2.ZERO) -> Callable:
	return func(): await walk_to_prop(id, offset)


## Makes the character walk to the [PopochiuProp] (in the current room) which
## [member PopochiuClickable.script_name] is equal to [param id]. You can set an [param offset]
## relative to the target position.
func walk_to_prop(id: String, offset := Vector2.ZERO) -> void:
	await _walk_to_node(PopochiuUtils.r.current.get_prop(id), offset)


## Makes the character teleport (disappear at one location and instantly appear at another) to the
## [PopochiuProp] (in the current room) which [member PopochiuClickable.script_name] is equal to
## [param id]. You can set an [param offset] relative to the target position.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_teleport_to_prop(id: String, offset := Vector2.ZERO) -> Callable:
	return func(): await teleport_to_prop(id, offset)


## Makes the character teleport (disappear at one location and instantly appear at another) to the
## [PopochiuProp] (in the current room) which [member PopochiuClickable.script_name] is equal to
## [param id]. You can set an [param offset] relative to the target position.
func teleport_to_prop(id: String, offset := Vector2.ZERO) -> void:
	await _teleport_to_node(PopochiuUtils.r.current.get_prop(id), offset)


## Makes the character walk to the [PopochiuHotspot] (in the current room) which
## [member PopochiuClickable.script_name] is equal to [param id]. You can set an [param offset]
## relative to the target position.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to_hotspot(id: String, offset := Vector2.ZERO) -> Callable:
	return func(): await walk_to_hotspot(id, offset)


## Makes the character walk to the [PopochiuHotspot] (in the current room) which
## [member PopochiuClickable.script_name] is equal to [param id]. You can set an [param offset]
## relative to the target position.
func walk_to_hotspot(id: String, offset := Vector2.ZERO) -> void:
	await _walk_to_node(PopochiuUtils.r.current.get_hotspot(id), offset)


## Makes the character teleport (disappear at one location and instantly appear at another) to the
## [PopochiuHotspot] (in the current room) which [member PopochiuClickable.script_name] is equal to
## [param id]. You can set an [param offset] relative to the target position.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_teleport_to_hotspot(id: String, offset := Vector2.ZERO) -> Callable:
	return func(): await teleport_to_hotspot(id, offset)


## Makes the character teleport (disappear at one location and instantly appear at another) to the
## [PopochiuHotspot] (in the current room) which [member PopochiuClickable.script_name] is equal to
## [param id]. You can set an [param offset] relative to the target position.
func teleport_to_hotspot(id: String, offset := Vector2.ZERO) -> void:
	await _teleport_to_node(PopochiuUtils.r.current.get_hotspot(id), offset)


## Makes the character walk to the [Marker2D] (in the current room) which [member Node.name] is
## equal to [param id]. You can set an [param offset] relative to the target position.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to_marker(id: String, offset := Vector2.ZERO) -> Callable:
	return func(): await walk_to_marker(id, offset)


## Makes the character walk to the [Marker2D] (in the current room) which [member Node.name] is
## equal to [param id]. You can set an [param offset] relative to the target position.
func walk_to_marker(id: String, offset := Vector2.ZERO) -> void:
	await _walk_to_node(PopochiuUtils.r.current.get_marker(id), offset)


## Makes the character teleport (disappear at one location and instantly appear at another) to the
## [Marker2D] (in the current room) which [member Node.name] is equal to [param id]. You can set an
## [param offset] relative to the target position.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_teleport_to_marker(id: String, offset := Vector2.ZERO) -> Callable:
	return func(): await teleport_to_marker(id, offset)


## Makes the character teleport (disappear at one location and instantly appear at another) to the
## [Marker2D] (in the current room) which [member Node.name] is equal to [param id]. You can set an
## [param offset] relative to the target position.
func teleport_to_marker(id: String, offset := Vector2.ZERO) -> void:
	await _teleport_to_node(PopochiuUtils.r.current.get_marker(id), offset)


## Sets [member emotion] to [param new_emotion] when in a [method Popochiu.queue].
func queue_set_emotion(new_emotion: String) -> Callable:
	return func(): emotion = new_emotion


## Sets [member ignore_walkable_areas] to [param new_value] when in a [method Popochiu.queue].
func queue_ignore_walkable_areas(new_value: bool) -> Callable:
	return func(): ignore_walkable_areas = new_value


## Plays the [param animation_label] animation. You can specify a fallback animation to play with
## [param animation_fallback] in case the former one doesn't exists.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_play_animation(
	animation_label: String, animation_fallback := 'idle', blocking := false
) -> Callable:
	return func(): await play_animation(animation_label, animation_fallback)


## Plays the [param animation_label] animation. You can specify a fallback animation to play with
## [param animation_fallback] in case the former one doesn't exists.
func play_animation(animation_label: String, animation_fallback := 'idle'):
	if (animation_label != _last_requested_animation_label) or (_looking_dir != _last_requested_animation_dir):
		if not has_node("AnimationPlayer"):
			PopochiuUtils.print_error(
				"Can't play character animation. Required AnimationPlayer not found in character %s" %
				[script_name]
			)
			return

		if animation_player.get_animation_list().is_empty():
			return

		# Search for a valid animation corresponding to animation_label
		_current_animation = _get_valid_oriented_animation(animation_label)
		# If is not present, do the same for the the fallback animation.
		if _current_animation.is_empty():
			_current_animation = _get_valid_oriented_animation(animation_fallback)
		# In neither are available, exit and throw an error to check for the presence of the animations.
		if _current_animation.is_empty(): # Again!
			PopochiuUtils.print_error(
				"Neither the requested nor the fallback animation could be found for character %s.\
				Requested:%s - Fallback: %s" % [script_name, animation_label, animation_fallback]
			)
			return
		# Cache the the _current_animation context to avoid re-searching for it.
		_last_requested_animation_label = animation_label
		_last_requested_animation_dir = _looking_dir
	# Play the animation in the best available orientation
	animation_player.play(_current_animation)
	# If the playing is blocking, wait for the animation to finish
	await animation_player.animation_finished

	# Go back to idle state
	_play_idle()


## Makes the animation that is currently playing to stop. Works only if it is looping and is not an
## idle animation. The animation stops when the current loop finishes.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_stop_animation():
	return func(): await stop_animation()


## Makes the animation that is currently playing to stop. Works only if it is looping and is not an
## idle animation. The animation stops when the current loop finishes.
func stop_animation():
	# If the animation is not looping or is an idle one, do nothing
	if (
		animation_player.get_animation(
			animation_player.current_animation
		).loop_mode == Animation.LOOP_NONE
		or animation_player.current_animation == 'idle'
		or animation_player.current_animation.begins_with('idle_')
	):
		return

	# Save the loop mode, wait for the anim to be over as designed, then restore the mode
	var animation: Animation = animation_player.get_animation(animation_player.current_animation)
	var animation_loop_mode := animation.loop_mode
	animation.loop_mode = Animation.LOOP_NONE
	await animation_player.animation_finished

	_play_idle()
	animation.loop_mode = animation_loop_mode


## Immediately stops the animation that is currently playing by changing to the idle animation.
## [br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_halt_animation():
	return func(): halt_animation()


## Immediately stops the animation that is currently playing by changing to the idle animation.
func halt_animation():
	_play_idle()


## Pauses the animation that is currently playing.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_pause_animation():
	return func(): pause_animation()


## Pauses the animation that is currently playing.
func pause_animation():
	animation_player.pause()


## Resumes the current animation (that was previously paused).[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_resume_animation():
	return func(): resume_animation()


## Resumes the current animation (that was previously paused).
func resume_animation():
	animation_player.play()


## Makes the character look in the direction of [param destination]. The result is one of the values
## defined by [enum Looking].
func face_direction(destination: Vector2):
	# Determine the direction the character is facing.
	# Remember: Y coordinates have opposite sign in Godot.
	# This means that negative angles are up movements.
	# Set the direction using the _looking property.
	# We cannot use the face_* functions because they
	# set the state as IDLE.

	# Based on the character facing direction, define a set of
	# animation suffixes in reference order.
	# Notice how we seek for opposite directions for left and
	# right. Flipping is done in other functions. We just define
	# a preference order for animations when available.

	# Get the vector from the origin to the destination.
	var angle = wrapf(rad_to_deg((destination - position).angle()) , 0, 360)
	# The angle calculation uses 16 angles rather than 8 for greater accuracy
	# in choosing the facing direction fallback animations.
	var _looking_angle := int(angle / 22.5) % 16
	# Selecting the animation suffixes for the current facing direction.
	# Note that we add a fallback empty string to the list, in case the only
	# available animation is the base one ('walk', 'talk', etc).
	_animation_suffixes = _valid_animation_suffixes[_looking_angle] + [EMPTY_STRING]
	# The 16 directions used for animation suffixes are simplified to 8 general directions
	_looking_dir = int(angle / 45) % 8


## Returns the [Texture] of the avatar defined for the [param emo] emotion.
## Returns [code]null[/code] if no avatar is found. If there is an avatar defined for the
## [code]""[/code] emotion, that one is returned by default.
func get_avatar_for_emotion(emo := EMPTY_STRING) -> Texture:
	var texture: Texture = null

	while not texture and not avatars.is_empty():
		for dic in avatars:
			if dic.emotion.is_empty():
				texture = dic.avatar
			elif dic.emotion == emo:
				texture = dic.avatar
				break

	return texture


## Returns the [code]y[/code] value of the dialog_pos [Vector2] that defines the
## position of the dialog lines said by the character when it talks.
func get_dialog_pos() -> float:
	return dialog_pos.y


func update_position() -> void:
	position = (
		position_stored
		if position_stored
		else position
	)


## Updates the scale depending on the properties of the scaling region where it is located.
func update_scale():
	if on_scaling_region:
		var polygon_range = (
			on_scaling_region["polygon_bottom_y"] - on_scaling_region["polygon_top_y"]
			)
		var scale_range = (
			on_scaling_region["scale_bottom"] - on_scaling_region["scale_top"]
			)

		var position_from_the_top_of_region = (
			position.y - on_scaling_region["polygon_top_y"]
			)

		var scale_for_position = (
			on_scaling_region["scale_top"] + (
				scale_range / polygon_range * position_from_the_top_of_region
		)
		)
		scale.x = [
			[scale_for_position, on_scaling_region["scale_min"]].max(),
			on_scaling_region["scale_max"]
		].min()
		scale.y = [
			[scale_for_position, on_scaling_region["scale_min"]].max(),
			on_scaling_region["scale_max"]
		].min()
		walk_speed = default_walk_speed / default_scale.x * scale_for_position
	else:
		scale = default_scale
		walk_speed = default_walk_speed


#endregion

#region SetGet #####################################################################################
func set_voices(value: Array) -> void:
	voices = value

	for idx in value.size():
		if not value[idx]:
			var arr: Array[AudioCueSound] = []

			voices[idx] = {
				emotion = EMPTY_STRING,
				variations = arr
			}
		elif not value[idx].variations.is_empty():
			if value[idx].variations[-1] == null:
				value[idx].variations[-1] = AudioCueSound.new()


func set_follow_player(value: bool) -> void:
	follow_player = value

	if not Engine.is_editor_hint():
		set_process(follow_player)


func set_avatars(value: Array) -> void:
	avatars = value

	for idx in value.size():
		if not value[idx]:
			avatars[idx] = {
				emotion = EMPTY_STRING,
				avatar = Texture.new(),
			}


#endregion

#region Private ####################################################################################
func _translate() -> void:
	if Engine.is_editor_hint() or not is_inside_tree(): return
	description = PopochiuUtils.e.get_text(_description_code)


func _get_vo_cue(emotion := EMPTY_STRING) -> String:
	for v in voices:
		if v.emotion.to_lower() == emotion.to_lower():
			var cue_name := EMPTY_STRING

			if not v.variations.is_empty():
				if not v.has('not_played') or v.not_played.is_empty():
					v['not_played'] = range(v.variations.size())

				var idx: int = (v['not_played'] as Array).pop_at(
					PopochiuUtils.get_random_array_idx(v['not_played'])
				)

				cue_name = v.variations[idx].resource_name

			return cue_name
	return EMPTY_STRING


func _get_valid_oriented_animation(animation_label):
	# The list of prefixes is in order of preference
	# Eg. walk_dl, walk_l, walk
	# Scan the AnimationPlayer and return the first that matches.
	for suffix in _animation_suffixes:
		var animation = "%s%s" % [animation_label, suffix]
		if animation_player.has_animation(animation):
			return animation

	return EMPTY_STRING


func _walk_to_node(node: Node2D, offset: Vector2) -> void:
	if not is_instance_valid(node):
		await get_tree().process_frame
		return

	await walk(
		node.to_global(node.walk_to_point if node is PopochiuClickable else Vector2.ZERO) + offset
	)


# Instantly move to the node position
func _teleport_to_node(node: Node2D, offset: Vector2) -> void:
	if not is_instance_valid(node):
		await get_tree().process_frame
		return

	position = node.to_global(
		node.walk_to_point if node is PopochiuClickable else Vector2.ZERO
	) + offset


func _update_position():
	PopochiuUtils.r.current.update_characters_position(self)

# Flips sprites depending on user preferences: requires two boolean conditions
# as arguments for flipping left [param left_cond] or right [param right_cond]
func _flip_left_right(left_cond: bool, right_cond: bool) -> void:
	if has_node('Sprite2D'):
		$Sprite2D.flip_h = false
		match flips_when:
			FlipsWhen.LOOKING_LEFT:
				$Sprite2D.flip_h = left_cond
			FlipsWhen.LOOKING_RIGHT:
				$Sprite2D.flip_h = right_cond


#endregion
