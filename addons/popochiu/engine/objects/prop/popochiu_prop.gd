@tool
@icon("res://addons/popochiu/icons/prop.png")
class_name PopochiuProp
extends PopochiuClickable
## Visual elements in the Room that can have interaction (i.e. the background, the foreground, a
## table, a cup).
##
## When selecting a Prop in the scene tree (Scene dock), Popochiu will enable three buttons in
## the Canvas Editor Menu: Baseline, Walk to, and Interaction. This can be used to select the child
## nodes that allow to modify the position of the [member PopochiuClickable.baseline],
## the position of the [member PopochiuClickable.walk_to_point], and the position and the polygon
## points of the [b]$InteractionPolygon[/b] child.

## Emitted when the [param item] linked to this object (by [member link_to_item]) is removed from
## the inventory. This may happen when the inventory item disappears forever from the game.
signal linked_item_removed(item: PopochiuInventoryItem)
## Emitted when the [param item] linked to this object (by [member link_to_item]) is discarded from
## the inventory. This may happen when the inventory item disappears forever from the game.
signal linked_item_discarded(item: PopochiuInventoryItem)
## Emitted when the obstacle flag state is changed.
signal obstacle_state_changed(prop: PopochiuProp)

## The image to use as the [member Sprite2D.texture] of the [b]$Sprite2D[/b] child.
@export var texture: Texture2D: set = set_texture
## The number of horizontal frames this node's texture image has. Modifying this will change the
## value of the [member Sprite2D.hframes] property in the [b]$Sprite2D[/b] child.
@export var frames := 1: set = set_frames
## The number of vertical frames this node's texture image has. Modifying this will change the
## value of the [member Sprite2D.vframes] property in the [b]$Sprite2D[/b] child.
@export var v_frames := 1: set = set_v_frames
## The current frame to use as the texture of this node. Modifying this will change the value of the
## [member Sprite2D.frame] property in the [b]$Sprite2D[/b] child. Trying to assign a value lesser
## than 0 will roll over the value to the maximum frame ([code]frames * v_frames - 1[/code]) or
## setting the value greater than the number of frames will roll over the value to 0.
@export var current_frame := 0: set = set_current_frame
## Links the prop to a [PopochiuInventoryItem] by its [member PopochiuInventoryItem.script_name].
## This will make the prop disappear from the room, depending on whether or not said inventory item
## is inside the inventory.
@export var link_to_item := ""
## When true, this prop will be considered an obstacle and its obstacle polygon (if available)
## will be carved from all [PopochiuWalkableAreas] it intersects in the room.
## Set this to false to ignore its encoumbrance during pathfinding.
@export var obstacle: bool = false: set = set_obstacle
## Stores the outlines to assign to the [b]ObstaclePolygon/Vertices[/b] child during
## runtime. This is used by [PopochiuRoom] to store the info in its [code].tscn[/code].
@export var obstacle_polygon := []
## Stores the position to assign to the [b]ObstaclePolygon/Vertices[/b] child during
## runtime. This is used by [PopochiuRoom] to store the info in its [code].tscn[/code].
@export var obstacle_polygon_position := Vector2.ZERO
## Opacity of the prop. Range: [code]0.0[/code] (fully transparent) to [code]1.0[/code] (fully opaque).
## Setting this value will modulate the alpha channel of the [b]$Sprite2D[/b] child.
@export_range(0.0, 1.0) var alpha: float = 1.0: set = set_alpha
## Total frames available the texture image has. [code](frames * vframes)[/code]
var total_frames: get = get_total_frames

# Tween used for alpha fade operations.
var _alpha_tween: Tween = null

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _navigation_obstacle: NavigationObstacle2D = get_node_or_null("ObstaclePolygon")


#region Godot ######################################################################################
func _ready() -> void:
	super()
	add_to_group("props")

	if Engine.is_editor_hint():
		# Ignore assigning the vertices when:
		if (
			_navigation_obstacle == null # there is no ObstaclePolygon node
			or not get_parent() is Node2D # editing it in the .tscn file of the object directly
		):
			return

		if obstacle_polygon.is_empty():
			obstacle_polygon = _navigation_obstacle.vertices
			obstacle_polygon_position = _navigation_obstacle.position
		else:
			_navigation_obstacle.vertices = obstacle_polygon
			_navigation_obstacle.position = obstacle_polygon_position

		# If we are in the editor, we're done
		return

	# When the game is running...
	# Update the node's obstacle polygon when there is one:
	if _navigation_obstacle != null:
		_navigation_obstacle.vertices = obstacle_polygon
		_navigation_obstacle.position = obstacle_polygon_position

	# Adjust the position and scaling of the prop
	# since we use the Y position as a sort of Z index.
	for child: Node in get_children():
		if child.get("position") is Vector2:
			child.position.y -= baseline * child.scale.y

	walk_to_point.y -= baseline * scale.y
	look_at_point.y -= baseline * scale.y
	position.y += baseline * scale.y

	# If an object is always on top, then
	# use the proper z-index.
	if always_on_top:
		z_index += 1

	# Connect movement signals
	movement_started.connect(_on_movement_started)
	movement_ended.connect(_on_movement_ended)

	# Connect signals of the linked item, if any
	if link_to_item:
		PopochiuUtils.i.item_added.connect(_on_item_added)
		PopochiuUtils.i.item_removed.connect(_on_item_removed)
		PopochiuUtils.i.item_discarded.connect(_on_item_discarded)

		if (
			PopochiuUtils.i.is_item_in_inventory(link_to_item) or
			PopochiuUtils.i.has_item_been_collected(link_to_item)
		):
			disable()


func _notification(event: int) -> void:
	if _navigation_obstacle == null:
		return

	if event == NOTIFICATION_EDITOR_PRE_SAVE:
		obstacle_polygon = _navigation_obstacle.vertices
		obstacle_polygon_position = _navigation_obstacle.position

#endregion

#region Virtual ####################################################################################
## Called when the [PopochiuInventoryItem] linked to this prop is removed from the inventory.
## [i]Virtual[/i].
func _on_linked_item_removed() -> void:
	pass


## Called when the [PopochiuInventoryItem] linked to this prop is discarded from the inventory.
## [i]Virtual[/i].
func _on_linked_item_discarded() -> void:
	pass


## Called when the prop starts moving.
## [i]Virtual[/i].
func _on_movement_started() -> void:
	pass


## Called when the prop stops moving.
## [i]Virtual[/i].
func _on_movement_ended() -> void:
	pass


#endregion

#region Public #####################################################################################
## Changes the value of the [member Sprite2D.frame] property to [param new_frame] in the
## [b]$Sprite2D[/b] child.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_change_frame(new_frame: int) -> Callable:
	return func(): await change_frame(new_frame)

## Changes the value of the [member Sprite2D.frame] property to [param new_frame] in the
## [b]$Sprite2D[/b] child.
func change_frame(new_frame: int) -> void:
	self.current_frame = new_frame
	await get_tree().process_frame


## Returns the NavigationObstacle2D if it has a defined polygon, null otherwise.
## This method checks if the obstacle has at least 3 vertices to form a valid polygon.
func get_navigation_obstacle() -> NavigationObstacle2D:
	if not _navigation_obstacle or not _navigation_obstacle is NavigationObstacle2D:
		return null

	# Check if obstacle has vertices defined (minimum 3 for a valid polygon)
	if _navigation_obstacle.vertices.size() < 3:
		return null

	return _navigation_obstacle


## Gradually increases the alpha value from its current value to [code]1.0[/code] over the
## specified [param duration] in seconds. If [param set_enablement] is [code]true[/code], the prop
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
## specified [param duration] in seconds. If [param set_enablement] is [code]true[/code], the prop
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
## specified [param duration] in seconds. If [param set_enablement] is [code]true[/code], the prop
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
## specified [param duration] in seconds. If [param set_enablement] is [code]true[/code], the prop
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
## [code]0.0[/code] and [code]1.0[/code]. If [param set_enablement] is [code]true[/code], the prop
## will be disabled if the final alpha is 0, or enabled if the final alpha is greater than 0.
## The [param trans] parameter specifies the transition type (see [enum Tween.TransitionType]),
## and [param ease] specifies the easing type (see [enum Tween.EaseType]).[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_fade_to(target_alpha: float, duration: float, set_enablement: bool = false) -> Callable:
	return func(): await fade_to(target_alpha, duration, set_enablement)


## Gradually transitions the alpha value from its current value to the specified [param target_alpha]
## over the specified [param duration] in seconds. The [param target_alpha] value is clamped between
## [code]0.0[/code] and [code]1.0[/code]. If [param set_enablement] is [code]true[/code], the prop
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


#endregion

#region SetGet #####################################################################################
func set_alpha(value: float) -> void:
	alpha = clampf(value, 0.0, 1.0)
	# Modulate the Sprite2D's alpha to control visibility
	if _sprite:
		_sprite.modulate.a = alpha


func set_texture(value: Texture2D) -> void:
	texture = value
	if not has_node("Sprite2D"): return

	$Sprite2D.texture = value


func set_frames(value: int) -> void:
	frames = value
	if not has_node("Sprite2D"): return

	$Sprite2D.hframes = value


func set_v_frames(value: int) -> void:
	v_frames = value
	if not has_node("Sprite2D"): return

	$Sprite2D.vframes = value


func set_current_frame(value: int) -> void:
	current_frame = value
	if not has_node("Sprite2D"): return

	var sprite := $Sprite2D as Sprite2D
	current_frame = (total_frames + current_frame) % total_frames

	sprite.frame = current_frame


func get_total_frames() -> int:
	return frames * v_frames


func set_obstacle(value: bool) -> void:
	obstacle = value
	obstacle_state_changed.emit()


#endregion

#region AnimationPlayer ############################################################################
## Will play the [param name] animation if it exists in this prop's [AnimationPlayer] node.
## Optionally you can use the other [method AnimationPlayer.play] parameters (see Godot's
## documentation for more details).
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_play_animation(
	name: StringName = &"",
	custom_blend: float = -1,
	custom_speed: float = 1.0,
	from_end: bool = false
) -> Callable:
	return func(): await play_animation(name, custom_blend, custom_speed, from_end)


## Will play the [param name] animation if it exists in this prop's [AnimationPlayer] node.
## Optionally you can use the other [method AnimationPlayer.play] parameters (see Godot's
## documentation for more details).
func play_animation(
	name: StringName = &"",
	custom_blend: float = -1,
	custom_speed: float = 1.0,
	from_end: bool = false
) -> void:
	if not has_node("AnimationPlayer"): return
	$AnimationPlayer.play(name, custom_blend, custom_speed, from_end)


## Will play the [param name] animation in reverse if it exists in this prop's [AnimationPlayer]
## node.
## This method is a shorthand for [method play_animation] with [code]custom_speed = -1.0[/code]
## and [code]from_end = true[/code].
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_play_animation_backwards(name: StringName = &"", custom_blend: float = -1) -> Callable:
	return func(): await play_animation_backwards(name, custom_blend)


## Will play the [param name] animation in reverse if it exists in this prop's [AnimationPlayer]
## node.
## This method is a shorthand for [method play_animation] with [code]custom_speed = -1.0[/code]
## and [code]from_end = true[/code].
func play_animation_backwards(name: StringName = &"", custom_blend: float = -1) -> void:
	if not has_node("AnimationPlayer"): return
	$AnimationPlayer.play_backwards(name, custom_blend)


## Will stop the animation that is currently playing.
## The animation position is reset to [code]0[/code] and the [code]custom_speed[/code] is reset to
## [code]1.0[/code]. Set [param keep_state] to [code]true[/code] to avoid the animation to be
## updated visually.
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_stop_animation(keep_state: bool = false) -> Callable:
	return func(): await stop_animation(keep_state)


## Will stop the animation that is currently playing.
## The animation position is reset to [code]0[/code] and the [code]custom_speed[/code] is reset to
## [code]1.0[/code]. Set [param keep_state] to [code]true[/code] to avoid the animation to be
## updated visually.
func stop_animation(keep_state: bool = false) -> void:
	if not has_node("AnimationPlayer"): return
	$AnimationPlayer.stop(keep_state)

## Will pause the animation that is currently playing.
## Call [method play_animation] without any parameters to resume the animation.
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_pause_animation() -> Callable:
	return func(): await pause_animation()


## Will pause the animation that is currently playing on the Popochiu Prop.
## Will pause the animation that is currently playing.
## Call [method play_animation] without any parameters to resume the animation.
func pause_animation() -> void:
	if not has_node("AnimationPlayer"): return
	$AnimationPlayer.pause()


## Return [code]true[/code] if an animation is playing, otherwise it will return [code]false[/code].
func is_animation_playing() -> bool:
	if not has_node("AnimationPlayer"): return false
	return $AnimationPlayer.is_playing()


## Returns the string name of the currently assigned animation in the [AnimationPlayer] node.
func get_assigned_animation() -> String:
	if not has_node("AnimationPlayer"): return ""
	return $AnimationPlayer.assigned_animation

## Sets the animation key name for the currently assigned animation in the [AnimationPlayer] node.
func set_assigned_animation(name: StringName) -> void:
	if not has_node("AnimationPlayer"): return
	$AnimationPlayer.assigned_animation = name


## Will return the current Popochiu Prop animation position in seconds.
## returns -1.0 if there is an error.
func get_current_animation_position() -> float:
	if not has_node("AnimationPlayer"): return -1.0
	return $AnimationPlayer.current_animation_position


#endregion

#region Private ####################################################################################
func _on_item_added(item: PopochiuInventoryItem, _animate: bool) -> void:
	if item.script_name == link_to_item:
		disable()


func _on_item_removed(item: PopochiuInventoryItem, _animate: bool) -> void:
	if item.script_name == link_to_item:
		_on_linked_item_removed()
		linked_item_removed.emit(self)


func _on_item_discarded(item: PopochiuInventoryItem) -> void:
	if item.script_name == link_to_item:
		enable()

		_on_linked_item_discarded()
		linked_item_discarded.emit(self)

#endregion
