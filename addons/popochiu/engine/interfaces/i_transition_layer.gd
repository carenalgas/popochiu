# @popochiu-docs-category game-scripts-interfaces
class_name PopochiuITransitionLayer
extends Node
## Provides access to the [PopochiuTransitionLayer] via the singleton [b]T[/b]
## (for example: [code]T.play_transition("fade", 1.0)[/code]).
##
## Use this interface to control screen transitions.
##
## Capabilities include:
##
## - Play transition animations when changing rooms or during cutscenes.[br]
## - Show or hide the curtain manually.[br]
## - Query available transition animations.
##
## [b]Use examples:[/b]
## [codeblock]
## # Play a fade transition lasting 1 second
## T.play_transition("fade", 1.0)
##
## # Play a wipe left transition lasting 0.5 seconds, both when entering and exiting the screen
## T.play_transition("wipe_left", 0.5, T.PLAY_MODE.IN_OUT)
##
## # Show the curtain (without animation)
## T.show_curtain()
##
## # Hide the curtain (without animation)
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
## Plays the transition animation identified by [param anim_name] for [param duration] seconds using
## the specified [param mode]. If parameters are omitted, project defaults are used.
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


## Plays the transition animation identified by [param anim_name] for [param duration] seconds using
## the specified [param mode]. If parameters are omitted, project defaults are used.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_play_transition(
	anim_name: String = "",
	duration: float = -1.0,
	mode: int = -1,
	color: Color = Color(-1, -1, -1, -1)
) -> Callable:
	return func(): await play_transition(anim_name, duration, mode, color)


## Shows the curtain using [param color] without playing a transition animation.
func show_curtain(color: Color = Color(-1, -1, -1, -1)) -> void:
	if not _is_tl_ready():
		return

	if color.r < 0:
		color = PopochiuConfig._get_project_setting(PopochiuConfig.TL_FADE_COLOR)

	tl.show_curtain(color)


## Hides the transition layer (curtain).
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


## Returns [code]true[/code] if the transition [param anim_name] has a track that overrides the
## default curtain color.
func has_color_override_track(anim_name: String) -> bool:
	if not _is_tl_ready():
		return false

	return tl.has_color_override_track(anim_name)


## Returns [code]true[/code] if the custom animation library exists.
func has_custom_library() -> bool:
	if not _is_tl_ready():
		return false

	return tl.has_custom_library()


## Returns [code]true[/code] if a custom transition named [param anim_name] exists.
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
