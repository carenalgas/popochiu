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


## Emitted when a [param character] starts moving from [param start] to [param end]. 
## The character connects to this signal internally to handle its own movement.
signal started_walk_to(character: PopochiuCharacter, start: Vector2, end: Vector2)
## Emitted when the character is forced to stop while walking.
signal stopped_walk
## Emitted when the animation to grab things has finished.
signal grab_done
## Emitted when the obstacle flag state is changed.
signal obstacle_state_changed(character: PopochiuCharacter)
## Emitted during movement when the character's position changes.
## Only emitted while the character is moving and the position has actually changed from the last emission.
signal position_updated(character: PopochiuCharacter, current_position: Vector2)


## Empty string constant to perform type checks (String is not nullable in GDScript. See #381, #382).
const EMPTY_STRING = ""
## Standard idle animation name.
const STANDARD_IDLE_ANIMATION = "idle"
## Standard walk animation name.
const STANDARD_WALK_ANIMATION = "walk"
## Standard talk animation name.
const STANDARD_TALK_ANIMATION = "talk"


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
## The [member PopochiuCharacter.script_name] of the character that this character should
## continuously face. Set this in the inspector to have the character automatically face another
## character at runtime.
@export var face_character := ""
## The [member PopochiuCharacter.script_name] of the character that this character should follow
## when it moves through the room. Set this in the inspector to have the character automatically
## follow another character at runtime.
@export var follow_character := ""
## The positional offset from the followed character where this character will walk to when following.
## [member follow_character_offset.x] defines the lateral (side-to-side) distance. The follower will
## stay to the left or right of the leader based on their relative positions.
## [member follow_character_offset.y] defines the vertical offset. Positive values place the follower
## lower/in front, negative values place them higher/behind.
## Example: [code]Vector2(20, -5)[/code] = "Stay 20px to the side, 5px higher (slightly behind in perspective)"
@export var follow_character_offset := Vector2(20, -5)
## The minimum distance the followed character must be from this character before following starts.
## This creates a "rubber band" effect where the follower doesn't move on every step of the leader.
## [member follow_character_threshold.x] defines the horizontal trigger distance.
## [member follow_character_threshold.y] defines the vertical trigger distance.
## The follower will start moving when the leader exceeds the threshold on [b]either[/b] axis.
## Example: [code]Vector2(35, 10)[/code] = "Start following if leader is >35px away horizontally OR >10px away vertically"
## Set to [code]Vector2.ZERO[/code] to make the follower move on every step (no threshold).
@export var follow_character_threshold := Vector2(35, 10)
## When [code]true[/code], this character will be automatically transferred to the target room when
## the followed character changes rooms. The follower will appear at the followed character's
## position plus [member follow_character_offset]. Chain-following is supported: if A follows B
## and B follows C, and C changes room, both A and B will transfer.
@export var follow_character_outside_room := false
## Array of [Dictionary] where each element has [code]{ emotion: String, avatar: Texture }[/code].
## You can use this to define which [Texture] to use as avatar for the character when it speaks
## using a specific emotion.
@export var avatars := []: set = set_avatars
## The speed at which the character will move in pixels per frame.
@export var walk_speed := 200.0
## Whether the character can or not move.
@export var can_move := true
## Whether the character ignores or not walkable areas. If [code]true[/code], the character will move
## to any point in the room clicked by players without taking into account the walkable areas in it.
@export var ignore_walkable_areas := false
## Whether the character ignores or not obstacles in walkable areas. If [code]true[/code], the character will
## move within a walkable area, ignoring obstacle polygons that might block the path.
@export var ignore_obstacles := false
## Whether the character will move only when the frame changes on its animation.
@export var anti_glide_animation: bool = false
## When true, this character will be considered an obstacle and its obstacle polygon (if available)
## will be carved from all [PopochiuWalkableAreas] it intersects in the room.
## Set this to false to ignore its encumbrance during pathfinding.
@export var obstacle: bool = false: set = set_obstacle
## Used by the GUI to calculate where to render the dialogue lines said by the character when it
## speaks.
@export var dialog_pos: Vector2
## Offset from the character's dialog_pos. Added to the normal dialog position.
var dialog_pos_offset: Vector2 = Vector2.ZERO
## Absolute world coordinates for dialog position. Overrides dialog_pos entirely when not set.
## By convention `Vector2.INF` means "unset" (instead of using Vector2.ZERO which is a valid position).
var dialog_pos_override: Vector2 = Vector2.INF
## The root name for idle animations. Directional suffixes will be added automatically.
@export var idle_animation: String = STANDARD_IDLE_ANIMATION: set = set_idle_animation
## The root name for walk animations. Directional suffixes will be added automatically.
@export var walk_animation: String = STANDARD_WALK_ANIMATION: set = set_walk_animation
## The root name for talk animations. Directional suffixes will be added automatically.
@export var talk_animation: String = STANDARD_TALK_ANIMATION: set = set_talk_animation
## Animation prefix for outfit changes (e.g., "pajama", "armor"). When set, the engine will search
## for prefixed animations like "pajama_walk_r" before falling back to basic "walk_r" animations.
@export var animation_prefix: String = "": set = set_animation_prefix


## Stores the [member PopochiuRoom.script_name] of the previously visited [PopochiuRoom].
var last_room := EMPTY_STRING
## The suffix text to add to animation names.
var anim_suffix := EMPTY_STRING
## The current emotion used by the character.
var emotion := EMPTY_STRING
##
var scaling_region: Dictionary = {}
## Stores the default walk speed defined in [member walk_speed]. Used by [PopochiuRoom] when scaling
## the character if it is inside a [PopochiuRegion] that modifies the scale.
var default_walk_speed := 0
## Stores the default scale. Used by [PopochiuRoom] when scaling the character if it is inside a
## [PopochiuRegion] that modifies the scale.
var default_scale := Vector2.ONE
## The position the character is walking towards. Returns [code]Vector2.ZERO[/code] if not moving.
## This represents the final destination of the current navigation path.
var target_position: Vector2: get = get_target_position
## Whether the character is currently talking (during [method say] execution).
## Returns [code]true[/code] from the moment [method say] is called until the dialog line finishes.
var is_talking: bool: get = get_is_talking
## Whether the character is currently playing an animation (other than walk, talk, or idle).
## Returns [code]true[/code] if the character is playing any animation that is not a walk, talk,
## or idle animation variant.
var is_animating: bool: get = get_is_animating
## Whether the character is visible in the current room.
## Returns [code]true[/code] only if the character is visible and belongs to the current active room.
var is_visible_in_room: bool: get = get_is_visible_in_room
## Returns the current animation being played. Read-only access to [member _current_animation].
## This property cannot be set from outside the character implementation.
var current_animation: String: get = get_current_animation
## Opacity of the character. Range: [code]0.0[/code] (fully transparent) to [code]1.0[/code] (fully opaque).
## Setting this value will modulate the alpha channel of the [b]$Sprite2D[/b] child.
@export_range(0.0, 1.0) var alpha: float = 1.0: set = set_alpha

# Holds the direction the character is looking at.
# Initialized to DOWN.
var _looking_dir: int = Looking.DOWN
# Tracks whether the character is currently talking (during say() method execution)
var _is_talking := false
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
# Array of the animation suffixes to search for based on the 8 directions the character can face.
# NOTE: Based on the character facing direction, we look for a set of animation suffixes
# in reference order. Notice the lookup table always contains opposite directions for
# left and right. That's because of flipping: the left animation can be flipped for right movement
# and viceversa. We just define a preference order for animations when available.
# Remember: Y coordinates have opposite sign in Godot, so negative angles are up movements.
var _valid_animation_suffixes = [
['_r', '_l', '_dr', '_dl', '_d'], # RIGHT (-22.5 - 22.5 degrees)
['_dr', '_dl', '_r', '_l', '_d'], # DOWN_RIGHT (22.5 - 67.5 degrees)
['_d', '_dr', '_dl', '_r', '_l'], # DOWN (67.5 - 112.5 degrees)
['_dl', '_dr', '_l', '_r', '_d'], # DOWN_LEFT (112.5 - 157.5 degrees)
['_l', '_r', '_dl', '_dr', '_d'], # LEFT (157.5 - 202.5 degrees)
['_ul', '_ur', '_l', '_r', '_u'], # UP_LEFT (202.5 - 247.5 degrees)
['_u', '_ul', '_ur', '_l', '_r'], # UP (247.5 - 292.5 degrees)
['_ur', '_ul', '_r', '_l', '_u']] # UP_RIGHT (292.5 - 337.5 degrees)
# Navigation path for this character's current movement
var _navigation_path := PackedVector2Array()
# The stored position of the character. Used when anti_glide_animation is true.
var _buffered_position = null
# Whether the dialog position is locked to a specific screen position.
var _is_dialog_pos_locked: bool = false
# The locked dialog position in global coordinates.
var _locked_dialog_pos: Vector2
# Tween used for alpha fade operations.
var _alpha_tween: Tween = null
# The character currently being followed at runtime (independent from exported follow_character).
var _current_followed_character: PopochiuCharacter = null
# The character currently being faced at runtime (independent from exported face_character).
var _current_faced_character: PopochiuCharacter = null
# Tracks the last position where position_updated signal was emitted.
# Used to throttle signal emissions and only emit when position actually changes.
var _last_emitted_position: Vector2 = Vector2.INF

@onready var interaction_polygon_node: CollisionPolygon2D = $InteractionPolygon
@onready var scaling_polygon: CollisionPolygon2D = $ScalingPolygon
@onready var animation_player: AnimationPlayer = $AnimationPlayer


#region Godot ######################################################################################
func _ready():
	super()

	default_walk_speed = walk_speed
	default_scale = Vector2(scale)

	if Engine.is_editor_hint():
		hide_helpers()
		set_process(true)
		return

	# Runtime execution code starts here

	# Connect the logic for anti-glide animations.
	# The handler function will know what to do, based on configuration.
	for child in get_children():
		# Use the presence of the "frame_changed" signal instead of checking for a
		# specific node type (would be Sprite2D). Improves resilience if the
		# node structure gets altered, as long as the new node still emits the same signal.
		if not child.has_signal("frame_changed"):
			continue
		child.frame_changed.connect(_update_position)

	# Connect movement signals to virtual methods
	movement_started.connect(_on_movement_started)
	movement_ended.connect(_on_movement_ended)

	# Connect to own movement signals to handle navigation internally
	if not started_walk_to.is_connected(_update_navigation_path):
		started_walk_to.connect(_update_navigation_path)
	if not stopped_walk.is_connected(_clear_navigation_path):
		stopped_walk.connect(_clear_navigation_path)

	# Prevent frame-by-frame processing for this character.
	# This flag is set when activating the walking function, or by characters
	# following or facing other characters.
	set_process(false)

	# Validate follow_character configuration
	if not follow_character.is_empty():
		# Warn if threshold is smaller than offset (can cause jitter)
		if (abs(follow_character_threshold.x) > 0 and abs(follow_character_threshold.x) < abs(follow_character_offset.x)) or \
		   (abs(follow_character_threshold.y) > 0 and abs(follow_character_threshold.y) < abs(follow_character_offset.y)):
			PopochiuUtils.print_warning(
				"Character '%s': follow_character_threshold (%s) should be >= follow_character_offset (%s) to avoid jitter" %
				[script_name, follow_character_threshold, follow_character_offset]
			)

	# Setup following behavior if enabled in inspector
	if not follow_character.is_empty() and self != PopochiuUtils.c.player:
		start_following_character()

	# Setup facing behavior if enabled in inspector
	if not face_character.is_empty() and self != PopochiuUtils.c.player:
		start_facing_character()

	# We need to initialize the interaction for the player character.
	# Changes will be handled by the player_changed signal handler.
	input_pickable = (
		not PopochiuCharactersHelper.is_player_character(self)
		and clickable
		and visible
	)

	# Connect to player changed signal to update clickability
	if not PopochiuUtils.c.player_changed.is_connected(_on_player_changed):
		PopochiuUtils.c.player_changed.connect(_on_player_changed)


func _physics_process(delta: float) -> void:
	if _navigation_path.is_empty(): return

	var walk_distance: float = walk_speed * delta
	_move_along_path(walk_distance)


func _process(delta: float) -> void:
	# Following takes precedence over facing
	if _current_followed_character:
		return

	# Continuously face the target character
	if _current_faced_character:
		_face_character(_current_faced_character)


func _exit_tree() -> void:
	# Safety cleanup: disconnect all follow/face signals to prevent memory leaks.
	if _current_followed_character:
		stop_following_character()
	if _current_faced_character:
		stop_facing_character()


#endregion

#region Virtual ####################################################################################
## Use it to play the idle animation of the character.
## [i]Virtual[/i].
func _play_idle() -> void:
	play_animation(idle_animation)


## Use it to play the walk animation of the character.
## [i]Virtual[/i].
func _play_walk(target_pos: Vector2) -> void:
	# Set the default parameters for play_animation()
	var animation_label = walk_animation
	var animation_fallback = idle_animation

	play_animation(animation_label, animation_fallback)


## Use it to play the talk animation of the character.
## [i]Virtual[/i].
func _play_talk() -> void:
	play_animation(talk_animation)


## Use it to play the grab animation of the character.
## [i]Virtual[/i].
func _play_grab() -> void:
	play_animation('grab')


## Use this method to add custom behavior when movement begins,
## such as playing sound effects or updating UI elements.
## [i]Virtual[/i].
func _on_movement_started() -> void:
	pass


## Use this method to add custom behavior when movement ends,
## such as triggering events or updating game state.
## [i]Virtual[/i].
func _on_movement_ended() -> void:
	pass


## Called after movement to sync the character's buffered position state.
func _on_position_changed() -> void:
	sync_buffered_position()


#endregion

#region Public #####################################################################################
## Returns the NavigationObstacle2D if it has a defined polygon and the character is set as obstacle, null otherwise.
## This method checks if the obstacle has at least 3 vertices to form a valid polygon.
func get_navigation_obstacle() -> NavigationObstacle2D:
	if not obstacle:
		return null

	if is_moving:
		return null

	var navigation_obstacle: NavigationObstacle2D = get_node_or_null("ObstaclePolygon")
	if not navigation_obstacle or not navigation_obstacle is NavigationObstacle2D:
		return null

	# Check if obstacle has vertices defined (minimum 3 for a valid polygon)
	if navigation_obstacle.vertices.size() < 3:
		return null

	return navigation_obstacle


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
	movement_started.emit()
	_last_reached_clickable = null

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

	# Trigger the signal to start moving the character
	started_walk_to.emit(self, position, target_pos)
	await movement_ended

	is_moving = false
	stopped_walk.emit()


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


## Makes the character face the opposite direction from where they are currently facing.[br][br]
## This is useful when you want to turn the character around without knowing their current
## direction. Calling this function twice will make the character face the original direction
## again.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_away() -> Callable:
	return func(): await face_away()


## Makes the character face the opposite direction from where they are currently facing.[br][br]
## This is useful when you want to turn the character around without knowing their current
## direction. Calling this function twice will make the character face the original direction
## again.[br][br]
## The function uses simple math on the [enum Looking] enum values: since the enum goes from 0 to 7
## in a circular pattern, adding 4 (modulo 8) gives the opposite direction:
## [code]RIGHT (0) ↔ LEFT (4), DOWN_RIGHT (1) ↔ UP_LEFT (5), etc.[/code]
func face_away() -> void:
	# Calculate opposite direction: add 4 and wrap around using modulo 8
	_looking_dir = (_looking_dir + 4) % 8
	# Update animation suffixes for the new direction
	_animation_suffixes = _valid_animation_suffixes[_looking_dir] + [EMPTY_STRING]
	# Wait for the idle animation to play with the new direction
	await idle()


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

	_is_talking = true

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
	_is_talking = false
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


## Makes the character walk to the [Marker2D] (in the current room) which [member Node.name] is
## equal to [param id]. You can set an [param offset] relative to the target position.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to_marker(id: String, offset := Vector2.ZERO) -> Callable:
	return func(): await walk_to_marker(id, offset)


## Makes the character walk to the [Marker2D] (in the current room) which [member Node.name] is
## equal to [param id]. You can set an [param offset] relative to the target position.
func walk_to_marker(id: String, offset := Vector2.ZERO) -> void:
	await _walk_to_node(PopochiuUtils.r.current.get_marker(id), offset)


## Sets [member emotion] to [param new_emotion] when in a [method Popochiu.queue].
func queue_set_emotion(new_emotion: String) -> Callable:
	return func(): emotion = new_emotion


## Sets [member ignore_walkable_areas] to [param new_value] when in a [method Popochiu.queue].
func queue_ignore_walkable_areas(new_value: bool) -> Callable:
	return func(): ignore_walkable_areas = new_value


## Sets [member idle_animation] to [param new_name] when in a [method Popochiu.queue].
func queue_set_idle_animation(new_name: String) -> Callable:
	return func(): idle_animation = new_name


## Sets [member walk_animation] to [param new_name] when in a [method Popochiu.queue].
func queue_set_walk_animation(new_name: String) -> Callable:
	return func(): walk_animation = new_name


## Sets [member talk_animation] to [param new_name] when in a [method Popochiu.queue].
func queue_set_talk_animation(new_name: String) -> Callable:
	return func(): talk_animation = new_name


## Sets [member animation_prefix] to [param new_prefix] when in a [method Popochiu.queue].
func queue_set_animation_prefix(new_prefix: String) -> Callable:
	return func(): animation_prefix = new_prefix


## Plays the [param animation_label] animation. You can specify a fallback animation to play with
## [param animation_fallback] in case the former one doesn't exists.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_play_animation(
	animation_label: String, animation_fallback := "", blocking := false
) -> Callable:
	return func(): await play_animation(animation_label, animation_fallback)


## Plays the [param animation_label] animation. You can specify a fallback animation to play with
## [param animation_fallback] in case the former one doesn't exists.
func play_animation(animation_label: String, animation_fallback := ""):
	# Use idle_animation as default fallback if none provided
	if animation_fallback.is_empty():
		animation_fallback = idle_animation
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
		or animation_player.current_animation == idle_animation
		or animation_player.current_animation.begins_with(idle_animation + '_')
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


## Gradually increases the alpha value from its current value to [code]1.0[/code] over the
## specified [param duration] in seconds. If [param set_enablement] is [code]true[/code], the character
## will be enabled when the fade completes (since alpha > 0).
## The [param trans] parameter specifies the transition type (see [enum Tween.TransitionType]),
## and [param ease] specifies the easing type (see [enum Tween.EaseType]).[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_fade_in(
	duration: float,
	set_enablement: bool = false,
	trans := Tween.TransitionType.TRANS_LINEAR,
	ease := Tween.EaseType.EASE_IN_OUT
) -> Callable:
	return func(): await fade_in(duration, set_enablement, trans, ease)


## Gradually increases the alpha value from its current value to [code]1.0[/code] over the
## specified [param duration] in seconds. If [param set_enablement] is [code]true[/code], the character
## will be enabled when the fade completes (since alpha > 0).
## The [param trans] parameter specifies the transition type (see [enum Tween.TransitionType]),
## and [param ease] specifies the easing type (see [enum Tween.EaseType]).
func fade_in(
	duration: float,
	set_enablement: bool = false,
	trans := Tween.TransitionType.TRANS_LINEAR,
	ease := Tween.EaseType.EASE_IN_OUT
) -> void:
	await fade_to(1.0, duration, set_enablement, trans, ease)


## Gradually decreases the alpha value from its current value to [code]0.0[/code] over the
## specified [param duration] in seconds. If [param set_enablement] is [code]true[/code], the character
## will be disabled when the fade completes (since alpha = 0).
## The [param trans] parameter specifies the transition type (see [enum Tween.TransitionType]),
## and [param ease] specifies the easing type (see [enum Tween.EaseType]).[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_fade_out(
	duration: float,
	set_enablement: bool = false,
	trans := Tween.TransitionType.TRANS_LINEAR,
	ease := Tween.EaseType.EASE_IN_OUT
) -> Callable:
	return func(): await fade_out(duration, set_enablement, trans, ease)


## Gradually decreases the alpha value from its current value to [code]0.0[/code] over the
## specified [param duration] in seconds. If [param set_enablement] is [code]true[/code], the character
## will be disabled when the fade completes (since alpha = 0).
## The [param trans] parameter specifies the transition type (see [enum Tween.TransitionType]),
## and [param ease] specifies the easing type (see [enum Tween.EaseType]).
func fade_out(
	duration: float,
	set_enablement: bool = false,
	trans := Tween.TransitionType.TRANS_LINEAR,
	ease := Tween.EaseType.EASE_IN_OUT
) -> void:
	await fade_to(0.0, duration, set_enablement, trans, ease)


## Gradually transitions the alpha value from its current value to the specified [param target_alpha]
## over the specified [param duration] in seconds. The [param target_alpha] value is clamped between
## [code]0.0[/code] and [code]1.0[/code]. If [param set_enablement] is [code]true[/code], the character
## will be disabled if the final alpha is 0, or enabled if the final alpha is greater than 0.
## The [param trans] parameter specifies the transition type (see [enum Tween.TransitionType]),
## and [param ease] specifies the easing type (see [enum Tween.EaseType]).[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_fade_to(target_alpha: float, duration: float, set_enablement: bool = false) -> Callable:
	return func(): await fade_to(target_alpha, duration, set_enablement)


## Gradually transitions the alpha value from its current value to the specified [param target_alpha]
## over the specified [param duration] in seconds. The [param target_alpha] value is clamped between
## [code]0.0[/code] and [code]1.0[/code]. If [param set_enablement] is [code]true[/code], the character
## will be disabled if the final alpha is 0, or enabled if the final alpha is greater than 0.
## The [param trans] parameter specifies the transition type (see [enum Tween.TransitionType]),
## and [param ease] specifies the easing type (see [enum Tween.EaseType]).
func fade_to(
	target_alpha: float,
	duration: float,
	set_enablement: bool = false,
	trans := Tween.TransitionType.TRANS_LINEAR,
	ease := Tween.EaseType.EASE_IN_OUT
) -> void:
	# Clamp target_alpha to valid range
	target_alpha = clampf(target_alpha, 0.0, 1.0)

	# Cancel any existing tween to avoid conflicts
	if _alpha_tween and _alpha_tween.is_valid():
		_alpha_tween.kill()

	# Create new tween for the fade operation
	_alpha_tween = create_tween()
	_alpha_tween.set_trans(trans)
	_alpha_tween.set_ease(ease)
	_alpha_tween.tween_property(self, "alpha", target_alpha, duration)

	# If the object has to fade in, make it visible
	# or the transition will not happen
	if target_alpha > 0:
		show()

	# Wait for the tween to complete
	await _alpha_tween.finished

	# Manage the enablement if necessary
	if not set_enablement:
		return

	if target_alpha == 0.0:
		disable()
	else:
		enable()


## Makes the character look in the direction of [param destination]. The result is one of the values
## defined by [enum Looking].
func face_direction(destination: Vector2):
	# Determine the direction the character is facing.
	# We cannot use the face_* functions because they reset the state to IDLE.
	# Get the angle of the vector from the origin to the destination as a number between
	# 0 and 360 degrees (Vector2.angle() returns the angle in radians between -PI and PI).
	var angle = wrapf(rad_to_deg((destination - global_position).angle()), 0, 360)
	# Calculate the looking direction using 8 directions centered on cardinal/diagonal directions
	# We add 22.5° offset so sectors are centered (e.g., -22.5° to +22.5° = RIGHT)
	_looking_dir = int((angle + 22.5) / 45) % 8
	# Set the animation suffixes for the current facing direction.
	# Note that we add a fallback empty string to the list, in case the only
	# available animation is the base one ('walk', 'talk', etc).
	_animation_suffixes = _valid_animation_suffixes[_looking_dir] + [EMPTY_STRING]


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


## Checks if the character is currently facing a specific direction.[br][br]
## Returns [code]true[/code] if the character's current facing direction ([member _looking_dir])
## matches the provided direction.[br][br]
## Example:[br]
## [codeblock]
## # Check if character is looking left
## if character.is_facing(PopochiuCharacter.Looking.LEFT):
##     print("Looking left!")
## [/codeblock]
func is_facing(dir: Looking) -> bool:
	return _looking_dir == dir


## Checks if the character is currently facing in any of the specified directions.[br][br]
## Returns [code]true[/code] if the character's current facing direction ([member _looking_dir])
## matches any of the directions in the provided array.[br][br]
## Example:[br]
## [codeblock]
## # Check if character is looking in any left direction
## if character.is_looking_any([
##     PopochiuCharacter.Looking.LEFT,
##     PopochiuCharacter.Looking.UP_LEFT,
##     PopochiuCharacter.Looking.DOWN_LEFT
## ]):
##     print("Looking in a leftish direction!")
## [/codeblock]
func is_facing_any(dirs: Array[Looking]) -> bool:
	return _looking_dir in dirs


## Returns the [code]y[/code] value of the dialog_pos [Vector2] that defines the
## position of the dialog lines said by the character when it talks.
func get_dialog_pos() -> float:
	return dialog_pos.y


## Returns the actual dialog position considering offset, override, and locked state.
## Always returns position relative to the character.
func get_actual_dialog_pos() -> Vector2:
	if _is_dialog_pos_locked:
		# Convert locked global position back to local coordinates
		return to_local(_locked_dialog_pos)

	if dialog_pos_override != Vector2.INF:
		return dialog_pos_override

	# If override is unset (Vector2.INF), return base pos + offset
	return dialog_pos + dialog_pos_offset


## Resets the dialog position offset to Vector2.ZERO.
func reset_dialog_pos_offset() -> void:
	dialog_pos_offset = Vector2.ZERO


## Resets the dialog position override to Vector2.ZERO (disabled).
func reset_dialog_pos_override() -> void:
	dialog_pos_override = Vector2.INF


## Locks the dialog position at the current calculated global position.
func lock_dialog_pos() -> void:
	# Calculate current position without using locked state. Respect INF as "unset".
	var current_pos: Vector2
	if dialog_pos_override != Vector2.INF:
		current_pos = dialog_pos_override
	else:
		current_pos = dialog_pos + dialog_pos_offset

	# Store as global coordinates
	_locked_dialog_pos = to_global(current_pos)
	_is_dialog_pos_locked = true


## Unlocks the dialog position, returning to normal positioning behavior.
func unlock_dialog_pos() -> void:
	_is_dialog_pos_locked = false


## Queue version: Resets the dialog position offset to Vector2.ZERO.
func queue_reset_dialog_pos_offset() -> Callable:
	return func(): reset_dialog_pos_offset()


## Queue version: Resets the dialog position override to Vector2.ZERO.
func queue_reset_dialog_pos_override() -> Callable:
	return func(): reset_dialog_pos_override()

## Queue version: Locks the dialog position at the current calculated screen position.
func queue_lock_dialog_pos() -> Callable:
	return func(): lock_dialog_pos()


## Queue version: Unlocks the dialog position.
func queue_unlock_dialog_pos() -> Callable:
	return func(): unlock_dialog_pos()


## Returns either the _buffered_position of the character,
## or its current transformer position, if that's not available
func get_buffered_position() -> Vector2:
	return _buffered_position if _buffered_position else position


## Forces the transformer position to match the buffered one, if available.
func update_position() -> void:
	position = get_buffered_position()


## Resets the buffered position. Called when exiting rooms to clean character state.
func reset_buffered_position() -> void:
	_buffered_position = null


## Syncs the buffered position with the current position to avoid conflicts with walking.
func sync_buffered_position() -> void:
	_buffered_position = position


## Updates the scale depending on the properties of the scaling region where it is located.
func update_scale():
	if scaling_region:
		var polygon_range: float = (
			scaling_region.polygon_bottom_y - scaling_region.polygon_top_y
		)
		var scale_range: float = scaling_region.scale_bottom - scaling_region.scale_top
		var position_from_the_top_of_region: float = position.y - scaling_region.polygon_top_y
		var scale_for_position: float = scaling_region.scale_top + (
			scale_range / polygon_range * position_from_the_top_of_region
		)
		scale.x = [
			[scale_for_position, scaling_region.scale_min].max(), scaling_region.scale_max
		].min()
		scale.y = [
			[scale_for_position, scaling_region.scale_min].max(), scaling_region.scale_max
		].min()
		walk_speed = default_walk_speed / default_scale.x * scale_for_position
	else:
		scale = default_scale
		walk_speed = default_walk_speed


## Resets the animation prefix.
## Same as assigning an empty string to the prefix.
func reset_animation_prefix() -> void:
	animation_prefix = PopochiuEditorHelper.EMPTY_STRING


#endregion

#region SetGet #####################################################################################
func set_alpha(value: float) -> void:
	alpha = clampf(value, 0.0, 1.0)
	# Modulate the Sprite2D's alpha to control visibility
	if has_node("Sprite2D"):
		$Sprite2D.modulate.a = alpha


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


func set_avatars(value: Array) -> void:
	avatars = value

	for idx in value.size():
		if not value[idx]:
			avatars[idx] = {
				emotion = EMPTY_STRING,
				avatar = Texture.new(),
			}


func set_obstacle(value: bool) -> void:
	obstacle = value
	obstacle_state_changed.emit()


func set_idle_animation(value: String) -> void:
	idle_animation = _get_valid_animation_name(value, STANDARD_IDLE_ANIMATION)


func set_walk_animation(value: String) -> void:
	walk_animation = _get_valid_animation_name(value, STANDARD_WALK_ANIMATION)


func set_talk_animation(value: String) -> void:
	talk_animation = _get_valid_animation_name(value, STANDARD_TALK_ANIMATION)


func set_animation_prefix(value: String) -> void:
	animation_prefix = value.strip_edges()
	# Clear animation cache to force re-evaluation with new prefix
	_last_requested_animation_label = "null"


## Getter function. Returns the final destination position from the navigation path, or Vector2.INF if not moving
func get_target_position() -> Vector2:
	if _navigation_path.is_empty() or not is_moving:
		return Vector2.INF
	return _navigation_path[-1] # Last point in the path


## Getter function. Returns whether the character is currently in the middle of saying a dialog line
func get_is_talking() -> bool:
	return _is_talking


## Getter function. Returns whether the character is playing a custom animation (excludes walk, talk, and idle variants)
func get_is_animating() -> bool:
	if not animation_player or _current_animation == "null":
		return false
	# Check if current animation is NOT walk, talk, or idle variants
	var anim_name = _current_animation.to_lower()
	return not (
		anim_name.begins_with(walk_animation) or
		anim_name.begins_with(talk_animation) or
		anim_name.begins_with(idle_animation)
	)


## Getter function. Returns whether the character is both visible and belongs to the currently active room
func get_is_visible_in_room() -> bool:
	return visible and room != null and room == PopochiuUtils.r.current


# Getter function. Returns the name of the currently playing animation
func get_current_animation() -> String:
	return _current_animation


## Makes this character start facing the specified character. If [param character] is not provided,
## the character defined in [member face_character] will be used. If that is also empty, the player
## character will be used. [param character] can be a [PopochiuCharacter] instance or a [String]
## with the character's [member script_name].
func start_facing_character(character: Variant = null) -> void:
	var target_character := _resolve_character(character, face_character)

	# Prevent self-facing or invalid target
	if target_character == self or target_character == null:
		return

	# Ensure both characters are in the scene tree
	if not is_inside_tree() or not target_character.is_inside_tree():
		return

	# Save the script_name in the property for serialization
	face_character = target_character.script_name

	_current_faced_character = target_character

	# Immediately face the target character
	_face_character(_current_faced_character)

	# Enable continuous facing in _process()
	if not Engine.is_editor_hint():
		set_process(true)


## Makes this character stop facing another character.
func stop_facing_character() -> void:
	_current_faced_character = null

	# Clear the property for serialization
	face_character = ""

	# Disable _process() only if not following or facing anyone
	if not _current_followed_character and not Engine.is_editor_hint():
		set_process(false)


## Makes this character start following the specified character. The follower will continuously
## monitor the leader's position and start moving when the leader exceeds the threshold distance
## (see [member follow_character_threshold]). The follower will walk to a position offset from
## the leader as defined by [member follow_character_offset].
##
## If [param character] is not provided, the character defined in [member follow_character] will
## be used. If that is also empty, the player character will be used.
## [param character] can be a [PopochiuCharacter] instance or a [String] with the character's
## [member script_name].
##
## The follower will only start a new walk when not already moving, preventing jitter from
## constant re-targeting.

func start_following_character(character: Variant = null) -> void:
	var target_character := _resolve_character(character, follow_character)

	# Prevent self-following or invalid target
	if target_character == self or target_character == null:
		return

	# Ensure both characters are in the scene tree
	if not is_inside_tree() or not target_character.is_inside_tree():
		return

	# Save the script_name in the property for serialization
	follow_character = target_character.script_name

	_current_followed_character = target_character

	# Connect to position updates for real-time following.
	if not _current_followed_character.position_updated.is_connected(_on_followed_character_position_updated):
		_current_followed_character.position_updated.connect(_on_followed_character_position_updated)

	# Connect to movement end to snap to final position.
	if not _current_followed_character.movement_ended.is_connected(_on_followed_character_stopped):
		_current_followed_character.movement_ended.connect(_on_followed_character_stopped)

	# Connect to walk start to handle mid-movement destination changes (e.g., followed character changes direction).
	if not _current_followed_character.started_walk_to.is_connected(_on_followed_character_started_walk):
		_current_followed_character.started_walk_to.connect(_on_followed_character_started_walk)

	# NOTE: We intentionally do NOT call _check_and_follow_character() here.
	# The follower should only react to the followed character's MOVEMENT, not their static position.
	# This prevents the follower from moving when the scene loads and the followed character is stationary.


## Makes this character stop following another character.
func stop_following_character() -> void:
	if _current_followed_character:
		# Safely disconnect signals.
		if _current_followed_character.position_updated.is_connected(_on_followed_character_position_updated):
			_current_followed_character.position_updated.disconnect(_on_followed_character_position_updated)
		if _current_followed_character.movement_ended.is_connected(_on_followed_character_stopped):
			_current_followed_character.movement_ended.disconnect(_on_followed_character_stopped)
		if _current_followed_character.started_walk_to.is_connected(_on_followed_character_started_walk):
			_current_followed_character.started_walk_to.disconnect(_on_followed_character_started_walk)

	_current_followed_character = null
	# Clear the property for serialization
	follow_character = ""

	# Disable _process() only if not following or facing anyone
	if not _current_faced_character and not Engine.is_editor_hint():
		set_process(false)


#endregion

#region Private ####################################################################################
# Resolves a character parameter to a PopochiuCharacter instance.
# [param character] can be a PopochiuCharacter, a String (script_name), or null.
# [param fallback_script_name] is used when [param character] is null or empty.
# Returns the player character if both are empty/null.
func _resolve_character(character: Variant, fallback_script_name: String) -> PopochiuCharacter:
	if character is PopochiuCharacter:
		return character
	if character is String and not (character as String).is_empty():
		return PopochiuUtils.c.get_character(character)
	if not fallback_script_name.is_empty():
		return PopochiuUtils.c.get_character(fallback_script_name)
	return PopochiuUtils.c.player


func _translate() -> void:
	if Engine.is_editor_hint() or not is_inside_tree(): return
	description = PopochiuUtils.e.get_text(_description_code)


# Validates an animation name and returns either the validated name or a fallback
func _get_valid_animation_name(value: String, fallback: String) -> String:
	# Clear animation cache to force re-evaluation
	_last_requested_animation_label = "null"

	# If the value is empty, return the fallback
	if value.is_empty():
		return fallback

	return value


## Called when the player character changes to update clickability
func _on_player_changed(old_player: PopochiuCharacter, new_player: PopochiuCharacter) -> void:
	new_player.input_pickable = false
	old_player.input_pickable = old_player.clickable && old_player.visible


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
	# Generate prioritized list of animation names to try
	var prioritized_names = _get_prioritized_animation_names(animation_label)

	# Try each animation name in priority order
	for animation_name in prioritized_names:
		var animation_result = _try_animation_with_suffixes(animation_name)
		if not animation_result.is_empty():
			return animation_result

	return EMPTY_STRING


# Generate prioritized list of animation names to try (in order of preference)
func _get_prioritized_animation_names(animation_label: String) -> Array[String]:
	var prioritized_names: Array[String] = []

	# 1. First priority: Prefixed animations (if prefix is set)
	if not animation_prefix.is_empty():
		prioritized_names.append_array(_get_prefixed_animation_names(animation_prefix, animation_label))

	# 2. Second priority: Original animation name as provided
	prioritized_names.append(animation_label)

	# 3. Third priority: Snake_case version (if different from original)
	if animation_label.to_snake_case() != animation_label:
		prioritized_names.append(animation_label.to_snake_case())

	return prioritized_names


# Generate prefixed animation names based on prefix format
func _get_prefixed_animation_names(prefix: String, animation_name: String) -> Array[String]:
	var prefixed_names: Array[String] = []

	# 1. Direct concatenation:
	#	- "Pajama" + "walk" = "Pajamawalk"
	#	- "Pajama" + "Walk" = "PajamaWalk"
	#	- "pajama_" + "Walk" = "pajama_Walk"
	#   - etc.
	prefixed_names.append(prefix + animation_name)

	# 2. PascalCase concatenation:
	#	- "Pajama" + "walk" = "PajamaWalk"
	#	- "Pajama" + "Walk" = "PajamaWalk"
	#	- "pajama_" + "Walk" = "PajamaWalk"
	prefixed_names.append(prefix.to_pascal_case() + animation_name.capitalize())

	# 3. snake_case concatenation:
	#	- "Pajama" + "walk" = "pajama_walk"
	#	- "Pajama" + "Walk" = "pajama_walk"
	#	- "pajama_" + "Walk" = "pajama_walk"
	#   - etc.
	prefixed_names.append(prefix.to_snake_case() + "_" + animation_name.to_lower())

	return prefixed_names


# Helper function to try an animation label with all directional suffixes
func _try_animation_with_suffixes(animation_label: String) -> String:
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


func _update_position():
	# This avoids errors when an animation is selected by the Aseprite importer interface
	# because _update_position() is bound to the "frame_changed" signal, which is triggered
	# even in the editor when the animation is assigned in the player.
	# Not guarding this with is_editor_hint() because we may still want to see animations
	# while in the editor, in other contexts.
	# See issue #403.
	if is_instance_valid(PopochiuUtils.r.current):
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


# Character navigation system.
#
# Moves the character along the navigation path, which is a list of Vector2 points.
# The character will walk towards the next point in the path until it reaches it,
# then it will continue to the next point until the path is empty.
func _move_along_path(walk_distance: float):
	var last_character_position: Vector2 = get_buffered_position()

	while _navigation_path.size():
		var next_waypoint: Vector2 = _navigation_path[0]

		var distance_to_next_waypoint = last_character_position.distance_to(
			next_waypoint
		)

		# The character hasn't reached the next navigation point so we update
		# its position along the line between the last and the next navigation point
		if walk_distance <= distance_to_next_waypoint:
			turn_towards(next_waypoint)
			var next_position = last_character_position.lerp(
				next_waypoint, walk_distance / distance_to_next_waypoint
			)
			if anti_glide_animation:
				_buffered_position = next_position
			else:
				position = next_position
			# Scale the character depending on the new position
			update_scale()

			# Emit position update only if position actually changed (>1px threshold)
			# This throttles emissions to avoid per-frame signal overhead when position is stable.
			var current_pos := get_buffered_position()
			if current_pos.distance_squared_to(_last_emitted_position) > 1.0: # 1px threshold
				_last_emitted_position = current_pos
				position_updated.emit(self, current_pos)

			# We are still walking towards the next navigation point
			# so we don't need to update the path information
			return

		# We reached the next navigation point
		# Remove the last navigation point from the path
		# and recalculate the distance to the next one
		walk_distance -= distance_to_next_waypoint
		last_character_position = next_waypoint
		_navigation_path.remove_at(0)

	position = last_character_position
	update_scale()
	_clear_navigation_path()

	# Apply facing behavior after movement completes.
	# This handles the case where a character is both following one character
	# and facing another (e.g., bodyguard following the player but always facing threats).
	# Without this, the character would only face during continuous updates in _process(),
	# missing the final snap-to-target immediately after reaching the destination.
	if _current_faced_character:
		_face_character(_current_faced_character)


# Character navigation system.
#
# Updates the navigation path for the character based on the start and end positions.
# The path is calculated by the room which has control over it's walkable areas and
# obstacles.
func _update_navigation_path(character: PopochiuCharacter, start_position: Vector2, end_position: Vector2):
	# Get the current room
	var current_room = PopochiuUtils.r.current
	if not current_room:
		PopochiuUtils.print_error("No current room found for character navigation")
		return

	# Get navigation path from room, passing both flags
	_navigation_path = current_room.get_navigation_path(
		start_position,
		end_position,
		ignore_walkable_areas,
		ignore_obstacles # Pass the new flag
	)

	if _navigation_path.is_empty():
		return

	# If the path is not empty it has at least two points: the start and the end.
	# Let's remove the first point of the path since it is the character's current position.
	_navigation_path.remove_at(0)

	# Now the _navigation_path will at least have another point at index 0.
	# Starting the physics processing will make _physics_process()
	# move the character along the path.
	set_physics_process(true)


# Character navigation system.
#
# Clears the navigation path and stops the physics process.
# This is called when the character reaches the end of the path or when it is interrupted.
func _clear_navigation_path() -> void:
	_navigation_path.clear()
	set_physics_process(false)
	idle()
	movement_ended.emit()

	# Reset position tracker so next movement starts fresh.
	_last_emitted_position = Vector2.INF


# Called every time the followed character's position updates during movement.
# Only triggers follow movement if threshold is exceeded and follower is not already moving.
func _on_followed_character_position_updated(followed_character: PopochiuCharacter, followed_character_pos: Vector2) -> void:
	# Safety check: if we're not in the tree, we can't process movement
	if not is_inside_tree():
		return
	
	# Early exit: don't interrupt current movement.
	# This prevents jitter from constant re-targeting while follower is already moving.
	if is_moving:
		return

	_check_and_follow_character()


# Called when the followed character starts a new walk (including direction changes).
# This handles mid-movement destination updates so the follower doesn't walk past the followed character.
func _on_followed_character_started_walk(followed_character: PopochiuCharacter, start: Vector2, end: Vector2) -> void:
	# Only react if we're actually following someone.
	if not _current_followed_character:
		return
	
	# Safety check: if we're not in the tree, we can't process movement
	if not is_inside_tree():
		return

	# If follower is NOT moving, use normal threshold-based logic.
	if not is_moving:
		_check_and_follow_character()
		return

	# Follower IS moving - stop and re-evaluate threshold.
	# This handles cases where followed character changes direction and crosses follower's path.
	await stop_walking()
	_check_and_follow_character()


# Called when the followed character stops moving.
# Ensures follower snaps to final offset position.
func _on_followed_character_stopped() -> void:
	# Only react if we're actually following someone.
	if not _current_followed_character:
		return
	
	# Safety check: if we're not in the tree, we can't process movement
	if not is_inside_tree():
		return

	# Wait a frame to ensure followed character's final position is settled.
	await get_tree().process_frame

	# Final position snap.
	_check_and_follow_character()


# Core logic: checks distance threshold and initiates following if needed.
# This is the single source of truth for follow behavior.
func _check_and_follow_character() -> void:
	if not _current_followed_character:
		return

	# Early exit: already moving, avoid re-targeting.
	if is_moving:
		return

	var followed_character_pos := _current_followed_character.position

	# Threshold check: only move if followed character is far enough away.
	# Skip expensive distance calculation if threshold is zero (always follow).
	if follow_character_threshold.length_squared() > 0:
		var distance_to_followed_character := followed_character_pos - position
		# Use OR logic: trigger if threshold exceeded on EITHER axis.
		# This creates rubber-band effect.
		if abs(distance_to_followed_character.x) <= abs(follow_character_threshold.x) and \
		   abs(distance_to_followed_character.y) <= abs(follow_character_threshold.y):
			# Followed character is within threshold, don't move.
			return

	# If followed character is moving, check if following would put us ahead of them.
	# This prevents the follower from overtaking the followed character when they reverse direction.
	var followed_character_destination := _current_followed_character.target_position
	if followed_character_destination != Vector2.INF:
		# Check X axis: if followed character is right of us but heading left of us, wait.
		if (followed_character_pos.x > position.x and followed_character_destination.x < position.x) or \
		   (followed_character_pos.x < position.x and followed_character_destination.x > position.x):
			return
		# Check Y axis: if followed character is below us but heading above us, wait.
		if (followed_character_pos.y > position.y and followed_character_destination.y < position.y) or \
		   (followed_character_pos.y < position.y and followed_character_destination.y > position.y):
			return

	# Followed character is far enough (or threshold is zero) - calculate follow position.
	_update_follow_target(followed_character_pos)


# Calculates the target follow position based on followed character's position and movement direction.
# Initiates walk to that position.
func _update_follow_target(followed_character_pos: Vector2) -> void:
	if not _current_followed_character:
		return

	# Determine followed character's movement direction and the base position to walk towards.
	var followed_character_destination := _current_followed_character.target_position
	var target_base_pos: Vector2
	var movement_direction: Vector2

	# If followed character is moving, use their destination as the base position for offset calculation.
	# This ensures the follower walks to where the followed character is GOING, not where they ARE.
	if followed_character_destination != Vector2.INF:
		target_base_pos = followed_character_destination
		movement_direction = (followed_character_destination - followed_character_pos).normalized()
	else:
		# Followed character is stationary, use their current position.
		target_base_pos = followed_character_pos
		movement_direction = (followed_character_pos - position).normalized()

	# Handle edge case: no meaningful direction (followed character on top of follower).
	if movement_direction.length_squared() < 0.01:
		# Default to followed character facing down.
		movement_direction = Vector2.DOWN

	# Calculate lateral offset based on movement direction.
	# If moving right, follower stays on left (negative X offset).
	# If moving left, follower stays on right (positive X offset).
	var lateral_direction := Vector2.LEFT if movement_direction.x > 0 else Vector2.RIGHT
	var lateral_offset := lateral_direction * follow_character_offset.x

	# Vertical offset (same direction regardless of lateral movement).
	var vertical_offset := Vector2.DOWN * follow_character_offset.y

	# Calculate final target position in global coordinates.
	var target_pos := target_base_pos + lateral_offset + vertical_offset

	# Initiate movement.
	# Using walk() directly since target_pos is already in global coordinates.
	walk(target_pos)


# Makes the character face another character by updating the facing direction.
# Called during continuous facing updates and after movement completion.
func _face_character(character: PopochiuCharacter) -> void:
	# Guard against facing targets that aren't in the same active tree/room
	if not is_inside_tree() or not character or not character.is_inside_tree():
		return
	if character.room != room:
		return

	# face_direction expects global coordinates
	face_direction(character.global_position)
	await idle()


#endregion
