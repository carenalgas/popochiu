class_name PopochiuMainCamera
extends Camera2D
## Takes in charge of the camera used by Popochiu.

var is_shaking := false

var _camera_shake_amount := 15.0
var _shake_timer := 0.0

@onready var tween: Tween = null
@onready var default_limits := {
	left = limit_left,
	right = get_viewport().get_visible_rect().end.x,
	top = limit_top,
	bottom = get_viewport().get_visible_rect().end.y
}


#region Godot ######################################################################################
func _process(delta: float) -> void:
	if is_shaking:
		_shake_timer -= delta
		offset = Vector2.ZERO + Vector2(
			randf_range(-1.0, 1.0) * _camera_shake_amount,
			randf_range(-1.0, 1.0) * _camera_shake_amount
		)
		
		if _shake_timer <= 0.0:
			stop_shake()
	elif is_instance_valid(C.camera_owner) and C.camera_owner.is_inside_tree():
		position = (
			C.camera_owner.position_stored
			if C.camera_owner.position_stored
			else C.camera_owner.position
		)


#endregion

#region Public #####################################################################################
## Changes the main camera's offset by [param offset] pixels. This method is intended to be used
## inside a [method queue] of instructions.
func queue_change_offset(offset := Vector2.ZERO) -> Callable:
	return func (): await change_offset(offset)


## Changes the main camera's offset by [param offset] pixels. Useful when zooming the camera.
func change_offset(offset := Vector2.ZERO) -> void:
	offset = offset
	await get_tree().process_frame


## Makes the camera shake with [param strength] during [param duration] seconds. This method is
## intended to be used inside a [method queue] of instructions.
func queue_shake(strength := 1.0, duration := 1.0) -> Callable:
	return func (): await shake(strength, duration)


## Makes the camera shake with [param strength] during [param duration] seconds.
func shake(strength := 1.0, duration := 1.0) -> void:
	_camera_shake_amount = strength
	_shake_timer = duration
	is_shaking = true
	
	await get_tree().create_timer(duration).timeout


## Makes the camera shake with [param strength] during [param duration] seconds without blocking
## excecution (that means it runs in the background). This method is intended to be used inside a
## [method queue] of instructions.
func queue_shake_bg(strength := 1.0, duration := 1.0) -> Callable:
	return func (): await shake_bg(strength, duration)


## Makes the camera shake with [param strength] during [param duration] seconds without blocking
## excecution (that means it runs in the background).
func shake_bg(strength := 1.0, duration := 1.0) -> void:
	_camera_shake_amount = strength
	_shake_timer = duration
	is_shaking = true
	
	await get_tree().process_frame


## Changes the camera zoom. If [param target] is greater than [code]Vector2(1, 1)[/code] the camera
## will [b]zoom out[/b], smaller values will make it [b]zoom in[/b]. The effect will last
## [param duration] seconds. This method is intended to be used inside a [method queue] of
## instructions.
func queue_change_zoom(target := Vector2.ONE, duration := 1.0) -> Callable:
	return func (): await change_zoom(target, duration)


## Changes the camera zoom. If [param target] is greater than [code]Vector2(1, 1)[/code] the camera
## will [b]zoom out[/b], smaller values will make it [b]zoom in[/b]. The effect will last
## [param duration] seconds.
func change_zoom(target := Vector2.ONE, duration := 1.0) -> void:
	if is_instance_valid(tween) and tween.is_running():
		tween.kill()
	
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "zoom", target, duration).from_current()
	await tween.finished


## Makes the camera stop shaking.
func stop_shake() -> void:
	is_shaking = false
	offset = Vector2.ZERO
	_shake_timer = 0.0


## Restores the limits of the camera to their default values
func restore_default_limits() -> void:
	limit_left = default_limits.left
	limit_right = default_limits.right
	limit_top = default_limits.top
	limit_bottom = default_limits.bottom


#endregion
