class_name PopochiuITransitionLayer
extends Node
## Provides access to the [PopochiuTransitionLayer] in the game. Access with [b]T[/b] (e.g.
## [code]T.play_transition("fade", 1.0)[/code]).[br][br]
##
## Use it to manage screen transitions. Its script is [b]i_transition_layer.gd[/b].[br][br]
##
## Some things you can do with it:[br][br]
##
## [b]•[/b] Play transition animations when changing rooms or during cutscenes.[br]
## [b]•[/b] Show or hide the curtain manually.[br]
## [b]•[/b] Get available transition animations.[br][br]
##
## Examples:
## [codeblock]
## T.play_transition("fade", 1.0)
## T.play_transition("wipe_left", 0.5, T.PLAY_MODE.IN_OUT)
## T.show_curtain()
## T.hide_curtain()
## [/codeblock]

## Emitted when a transition animation finishes.
signal transition_finished(transition_name: String)

## Re-export PLAY_MODE enum for convenience from [PopochiuTransitionLayer].
const PLAY_MODE = PopochiuTransitionLayer.PLAY_MODE

## Provides access to the [PopochiuTransitionLayer] instance managed by the engine.
var tl: PopochiuTransitionLayer


#region Godot ######################################################################################
func _init() -> void:
	Engine.register_singleton(&"T", self)


#endregion

#region Public #####################################################################################
## Plays a transition with the animation identified by [param anim_name], that lasts [param duration]
## (in seconds), with the specified [param mode].
## If no parameters are provided, uses defaults from Project Settings.
func play_transition(
	anim_name: String = "",
	duration: float = -1.0,
	mode: int = -1,
	color: Color = Color(-1, -1, -1, -1)
) -> void:
	if not _is_tl_ready():
		await get_tree().process_frame
		return

	# Use defaults from config if not specified
	if anim_name.is_empty():
		anim_name = PopochiuConfig._get_project_setting(PopochiuConfig.TL_DEFAULT_ROOM_TRANSITION)
	if duration < 0:
		duration = PopochiuConfig._get_project_setting(PopochiuConfig.TL_ROOM_TRANSITION_DURATION)
	if mode < 0:
		mode = PopochiuConfig._get_project_setting(PopochiuConfig.TL_ROOM_TRANSITION_MODE_ENTER)
	if color.r < 0:
		color = PopochiuConfig._get_project_setting(PopochiuConfig.TL_FADE_COLOR)

	tl.play_transition(anim_name, duration, mode, color)
	await tl.transition_finished
	transition_finished.emit(anim_name)


## Plays a transition animation. Intended to be used inside a [method Popochiu.queue] of
## instructions.
func queue_play_transition(
	anim_name: String = "",
	duration: float = -1.0,
	mode: int = -1,
	color: Color = Color(-1, -1, -1, -1)
) -> Callable:
	return func(): await play_transition(anim_name, duration, mode, color)


## Shows the curtain with the specified [param color] without playing any transition.
func show_curtain(color: Color = Color(-1, -1, -1, -1)) -> void:
	if not _is_tl_ready():
		return

	if color.r < 0:
		color = PopochiuConfig._get_project_setting(PopochiuConfig.TL_FADE_COLOR)

	tl.show_curtain(color)


## Hides the transition layer.
func hide_curtain() -> void:
	if not _is_tl_ready():
		return

	tl.hide_curtain()


## Returns a list of all available transition animation names.
func get_all_transitions_list() -> PackedStringArray:
	if not _is_tl_ready():
		return PackedStringArray()

	return tl.get_all_transitions_list()


## Returns a list of predefined transition animation names.
func get_predefined_transitions_list() -> PackedStringArray:
	if not _is_tl_ready():
		return PackedStringArray()

	return tl.get_predefined_transitions_list()


## Returns a list of custom transition animation names.
func get_custom_transitions_list() -> PackedStringArray:
	if not _is_tl_ready():
		return PackedStringArray()

	return tl.get_custom_transitions_list()


## Returns the transition animation specified by [param anim_name].
func get_transition(anim_name: String) -> Animation:
	if not _is_tl_ready():
		return null

	return tl.get_transition(anim_name)


## Check if the transition specified by [param anim_name] has an enabled track that overrides the
## default Curtain color.
func has_color_override_track(anim_name: String) -> bool:
	if not _is_tl_ready():
		return false

	return tl.has_color_override_track(anim_name)


## Returns [code]true[/code] if the custom animation library exists.
func has_custom_library() -> bool:
	if not _is_tl_ready():
		return false

	return tl.has_custom_library()


## Returns [code]true[/code] if a custom transition with [param anim_name] exists.
func has_custom_transition(anim_name: String) -> bool:
	if not _is_tl_ready():
		return false

	return tl.has_custom_transition(anim_name)


## Returns the custom transition animation specified by [param anim_name], or [code]null[/code]
## if not found.
func get_custom_transition(anim_name: String) -> Animation:
	if not _is_tl_ready():
		return null

	return tl.get_custom_transition(anim_name)


#endregion

#region Private ####################################################################################
## Checks if the transition layer instance is ready to use.
func _is_tl_ready() -> bool:
	if not is_instance_valid(tl):
		PopochiuUtils.print_warning("Transition Layer not ready yet.")
		return false
	return true


#endregion
