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

## The image to use as the [member Sprite2D.texture] of the [b]$Sprite2D[/b] child.
@export var texture: Texture2D : set = set_texture
## The number of horizontal frames this node's texture image has. Modifying this will change the
## value of the [member Sprite2D.hframes] property in the [b]$Sprite2D[/b] child.
@export var frames := 1 : set = set_frames
## The number of vertical frames this node's texture image has. Modifying this will change the
## value of the [member Sprite2D.vframes] property in the [b]$Sprite2D[/b] child.
@export var v_frames := 1 : set = set_v_frames
## The current frame to use as the texture of this node. Modifying this will change the value of the
## [member Sprite2D.frame] property in the [b]$Sprite2D[/b] child. Trying to assign a value lesser
## than 0 will roll over the value to the maximum frame ([code]frames * v_frames - 1[/code]) or
## setting the value greater than the number of frames will roll over the value to 0.
@export var current_frame := 0: set = set_current_frame
## Links the prop to a [PopochiuInventoryItem] by its [member PopochiuInventoryItem.script_name].
## This will make the prop disappear from the room, depending on whether or not said inventory item
## is inside the inventory.
@export var link_to_item := ""

## Total frames available the texture image has. [code](frames * vframes)[/code]
var total_frames: get = get_total_frames

@onready var _sprite: Sprite2D = $Sprite2D


#region Godot ######################################################################################
func _ready() -> void:
	super()
	add_to_group("props")
	
	if Engine.is_editor_hint(): return
	
	for c in get_children():
		if c.get("position") is Vector2:
			c.position.y -= baseline * c.scale.y

	walk_to_point.y -= baseline * scale.y
	look_at_point.y -= baseline * scale.y
	position.y += baseline * scale.y

	if always_on_top:
		z_index += 1
	
	if link_to_item:
		PopochiuUtils.i.item_added.connect(_on_item_added)
		PopochiuUtils.i.item_removed.connect(_on_item_removed)
		PopochiuUtils.i.item_discarded.connect(_on_item_discarded)
		
		if PopochiuUtils.i.is_item_in_inventory(link_to_item):
			disable()


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


#endregion

#region Public #####################################################################################
## Changes the value of the [member Sprite2D.frame] property to [param new_frame] in the
## [b]$Sprite2D[/b] child.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_change_frame(new_frame: int) -> Callable:
	return func (): await change_frame(new_frame)

## Changes the value of the [member Sprite2D.frame] property to [param new_frame] in the
## [b]$Sprite2D[/b] child.
func change_frame(new_frame: int) -> void:
	self.current_frame = new_frame
	await get_tree().process_frame


#endregion

#region SetGet #####################################################################################
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
	return func (): await play_animation(name, custom_blend, custom_speed, from_end)


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
	return func (): await play_animation_backwards(name, custom_blend)


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
	return func (): await stop_animation(keep_state)


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
	return func (): await pause_animation()


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
