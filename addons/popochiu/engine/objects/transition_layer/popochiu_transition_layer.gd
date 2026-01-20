@tool
class_name PopochiuTransitionLayer
extends Control
## Used to play different transition animations when moving between rooms, skipping a cutscene,
## and so on.

signal transition_finished(transition_name: String)

enum PLAY_MODE {
	IN,
	OUT,
	IN_OUT
}


#region Godot ######################################################################################
func _ready() -> void:
	# Connect to childrens' signals
	$AnimationPlayer.animation_finished.connect(_transition_finished)
	$AnimationPlayer.animation_libraries_updated.connect(
		_on_animation_player_animation_libraries_updated
	)
	$AnimationPlayer.animation_list_changed.connect(_on_animation_player_animation_list_changed)

	# Connect to animation_removed signal from all animation libraries
	# This is done for both predefined and custom libraries
	_connect_animation_libraries_signals()

	$Curtain.modulate = PopochiuUtils.e.settings.tl_fade_color

	# Pass the curtain size to the shader
	$Curtain.material.set_shader_parameter("curtain_size", $Curtain.size)

	# Make sure the transition layer is ready
	# if it has to be visible in the first room
	if PopochiuUtils.e.settings.show_tl_in_first_room and Engine.get_process_frames() == 0:
		show_curtain()
	else:
		$AnimationPlayer.play("RESET")
		await get_tree().process_frame
		_hide()


#endregion

#region Public #####################################################################################
## Plays a transition with the animation identified by [param anim_name], that lasts [param duration]
## (in seconds), with the specified [param mode] showing the Curtain with the specified
## [param color].
## The Curtain color follows this precedence rule (from highest to lowest):
##	 - color specified from code;
##	 - color specified in the modulate track of the animation (if enabled);
##	 - color specified in project settings.
## [br][br]
## [b]Note:[/b] Custom transitions must use [code]snake_case[/code] naming convention for proper
## display in project settings. The [param name] parameter accepts any format (Title Case,
## CamelCase, or snake_case) and normalizes it internally.
func play_transition(
	anim_name: String = "fade",
	duration: float = 1.0,
	mode: int = PLAY_MODE.IN_OUT,
	color: Color = PopochiuUtils.e.settings.tl_fade_color
) -> void:
	# Normalize transition name to snake_case for animation lookup
	# If name contains "/", it's a custom animation with library prefix - use get_custom_name to
	# preserve the correct prefix
	var anim_lib_name = get_custom_name(anim_name) if "/" in anim_name else get_simple_name(anim_name)
	var anim = get_transition(anim_lib_name)

	if anim != null:
		# Use snake_case version if found
		anim_name = anim_lib_name
	else:
		# Fallback: if snake_case version not found, try original name as-is
		anim = get_transition(anim_name)

	# Check if the animation exists
	if anim == null:
		return
	
	var reenable_color_track = false

	# ---- Play RESET in order to fix #168 ---------------------------------------------------------
	$AnimationPlayer.play("RESET")
	await get_tree().process_frame
	# --------------------------------------------------------- Play RESET in order to fix #168 ----

	$AnimationPlayer.speed_scale = 1.0 / duration if duration != 0.0 else 0.0;

	# Override Curtain color
	# Watch out: the RESET animation will set the Curtain:modulate property if a such a track is
	# present
	if color != PopochiuUtils.e.settings.tl_fade_color:
		if has_color_override_track(anim_name):
			reenable_color_track = true
			toggle_track(anim_name, "Curtain:modulate", false)

	show_curtain(color)

	match mode:
		PLAY_MODE.IN_OUT:
			$AnimationPlayer.play(anim_name)
			await $AnimationPlayer.animation_finished
			$AnimationPlayer.play_backwards(anim_name)
			await $AnimationPlayer.animation_finished
			_hide()
		PLAY_MODE.IN:
			$AnimationPlayer.play(anim_name)
			await $AnimationPlayer.animation_finished
			# Revealing the scene: hide TL so GUI and input work.
			_hide()
		PLAY_MODE.OUT:
			$AnimationPlayer.play_backwards(anim_name)
			await $AnimationPlayer.animation_finished
			# Covering the scene: keep TL visible to avoid gritches at room change.
		_:
			var result_code = ResultCodes.ERR_ANIMATION_PLAY_MODE_UNKNOWN
			PopochiuUtils.print_error(ResultCodes.get_error_message(result_code) + " (%s)" % mode)

	# Restore overridden values
	$AnimationPlayer.speed_scale = 1.0
	if reenable_color_track:
		toggle_track(anim_name, "Curtain:modulate", true)
	$Curtain.modulate = PopochiuUtils.e.settings.tl_fade_color


## Shows the curtain with the specified [param color] without playing any transition.
## if [param name] is not specified, the curtain will be shown with the default color from project
## settings. Beware that this color can be subsequently overridden by animation tracks or by code.
func show_curtain(color: Color = PopochiuUtils.e.settings.tl_fade_color) -> void:
	$Curtain.modulate = color
	$Curtain.show()
	_show()


## Hides the transition layer.
func hide_curtain() -> void:
	_hide()


## Return the animation specified by [param anim_name].
func get_transition(anim_name: String) -> Animation:
	var anim = $AnimationPlayer.get_animation(anim_name)

	if anim == null:
		var result_code := ResultCodes.ERR_ANIMATION_NOT_FOUND
		PopochiuUtils.print_error(ResultCodes.get_error_message(result_code) + " (%s)" % anim_name)

	return anim


## Return the custom animation library or null.
func get_custom_library() -> AnimationLibrary:
	var tl_anim_lib: AnimationLibrary = $AnimationPlayer.get_animation_library(
		PopochiuResources.TRANSITION_LAYER_CUSTOM_ANIMLIB
	)

	if not tl_anim_lib:
		var result := ResultCodes.ERR_ANIMATION_LIBRARY_NOT_FOUND
		PopochiuUtils.print_error(
			ResultCodes.get_error_message(result)
			+ " (%s)" % PopochiuResources.TRANSITION_LAYER_CUSTOM_ANIMLIB
		)

	return tl_anim_lib


## Return true if an animation library with custom transition is present.
func has_custom_library() -> bool:
	return true if get_custom_library() else false


## Return the custom transition specified by [param anim_name].
## Return null if not found.
func get_custom_transition(anim_name: String) -> Animation:
	var tl_anim_lib := get_custom_library()

	if not tl_anim_lib:
		return null

	var tl_anim := tl_anim_lib.get_animation(anim_name)

	if not tl_anim:
		var result_code := ResultCodes.ERR_ANIMATION_NOT_FOUND
		PopochiuUtils.print_error(ResultCodes.get_error_message(result_code) + " (%s)" % anim_name)

	return tl_anim


## Return true if the custom transition specified by [param anim_name] exists.
func has_custom_transition(anim_name: String) -> bool:
	return true if get_custom_transition(anim_name) else false


## Return a list of all custom transition names.
func get_custom_transitions_list() -> PackedStringArray:
	var anim_list := PackedStringArray(get_custom_library().get_animation_list())
	return _hide_animations(anim_list)


## Return a list of predefined transition names.
func get_predefined_transitions_list() -> PackedStringArray:
	var anim_list := PackedStringArray($AnimationPlayer.get_animation_library("").get_animation_list())
	return _hide_animations(anim_list)


## Return a list of all transition names.
func get_all_transitions_list() -> PackedStringArray:
	var anim_list: PackedStringArray = $AnimationPlayer.get_animation_list()
	return _hide_animations(anim_list)


## Check if the transition specified by [param anim_name] has an enabled track that overrides the
## default Curtain color.
func has_color_override_track(anim_name: String) -> bool:
	var anim := get_transition(anim_name)
	var idx := anim.find_track("Curtain:modulate", Animation.TrackType.TYPE_VALUE)

	return idx != -1 and anim.track_is_enabled(idx)


## Toggle a track specified by [param track_name] of an animation specified by [param anim_name]
## on or off based on [param value].
func toggle_track(anim_name: String, track_name: String, value: bool) -> void:
	var anim := get_transition(anim_name)
	var idx := anim.find_track(track_name, Animation.TrackType.TYPE_VALUE)

	if idx != -1:
		anim.track_set_enabled(idx, value)


## Copy an image to the transition layer masks directory.
## Returns ResultCodes.SUCCESS or ResultCodes.FAILURE.
func copy_image(texture_path: String) -> int:
	var result_code: int
	# Ensure the source file exists
	if not FileAccess.file_exists(texture_path):
		return ResultCodes.FAILURE

	var file_name := texture_path.get_file()

	# Ensure the destination directory exists
	var game_tl_image_dir := DirAccess.open(PopochiuResources.TRANSITION_LAYER_PATH)

	#if not game_tl_image_dir:
	await game_tl_image_dir.make_dir(PopochiuResources.TRANSITION_LAYER_MASKS)

	# Copy the image file: overwrite by default
	result_code = game_tl_image_dir.copy(
		texture_path, PopochiuResources.TRANSITION_LAYER_MASKS + file_name
	)
	await PopochiuEditorHelper.filesystem_scanned()

	return ResultCodes.SUCCESS if result_code == OK else ResultCodes.FAILURE


## Create a basic custom transition and return it as an Animation resource.
## The transition uses the texture specified by [param texture_path] (path to the image file),
## with the specified [param cutoff] and [param smoothing] values, lasting [param duration] seconds.
## If [param visibility_track] is true, a visibility track will be added to the animation.
## If [param modulate_track] is true, a modulate track will be added to the animation, using the
## specified [param color].
## Returns the created Animation resource or null on failure.
func create_basic_custom_transition(
	texture_path: String,
	cutoff: float,
	smoothing: float,
	duration: float,
	visibility_track = false,
	modulate_track = false,
	color: Color = PopochiuUtils.e.settings.tl_fade_color
) -> Animation:
	# Create basic transition
	var new_anim: Animation = Animation.new()
	var track_index
	# Visibility (might not be necessary)
	if visibility_track:
		track_index = new_anim.add_track(Animation.TYPE_VALUE)
		new_anim.track_set_path(track_index, "Curtain:visible")
		new_anim.track_insert_key(track_index, 0.0, true)
		new_anim.track_insert_key(track_index, duration, true)
	# Modulate (might not be necessary)
	if modulate_track:
		track_index = new_anim.add_track(Animation.TYPE_VALUE)
		new_anim.track_set_path(track_index, "Curtain:modulate")
		new_anim.track_insert_key(track_index, 0.0, color)
		new_anim.track_insert_key(track_index, duration, color)
	# Texture
	# Copy image
	if await copy_image(texture_path) != ResultCodes.SUCCESS:
		return null
	# Load resource
	var game_tl_texture := PopochiuResources.TRANSITION_LAYER_MASKS.path_join(texture_path.get_file())
	var mask: Resource = ResourceLoader.load(game_tl_texture)
	track_index = new_anim.add_track(Animation.TYPE_VALUE)
	new_anim.track_set_path(track_index, "Curtain:material:shader_parameter/mask")
	new_anim.track_insert_key(track_index, 0.0, mask)
	new_anim.track_insert_key(track_index, duration, mask) # load texture
	# Cutoff
	track_index = new_anim.add_track(Animation.TYPE_VALUE)
	new_anim.track_set_path(track_index, "Curtain:material:shader_parameter/cutoff")
	new_anim.track_set_interpolation_type(
		track_index, Animation.InterpolationType.INTERPOLATION_LINEAR
	)
	new_anim.value_track_set_update_mode(track_index, Animation.UpdateMode.UPDATE_CONTINUOUS)
	new_anim.track_insert_key(track_index, 0.0, 0.0)
	new_anim.track_insert_key(track_index, duration, cutoff)
	# Smoothing window
	track_index = new_anim.add_track(Animation.TYPE_VALUE)
	new_anim.track_set_path(track_index, "Curtain:material:shader_parameter/smoothing_window")
	new_anim.track_set_interpolation_type(
		track_index, Animation.InterpolationType.INTERPOLATION_LINEAR
	)
	new_anim.value_track_set_update_mode(track_index, Animation.UpdateMode.UPDATE_CONTINUOUS)
	new_anim.track_insert_key(track_index, 0.0, 0.0)
	new_anim.track_insert_key(track_index, duration, smoothing)
	# Duration
	new_anim.length = duration

	return new_anim


## Create an animation resource and add that as a custom transition to the User animation library.
## If [param overwrite] is true, any existing animation with the same name will be overwritten.
## Returns ResultCodes.SUCCESS or ResultCodes.ERR_ANIMATION_ALREADY_EXISTS.
func add_custom_transition(anim: Animation, anim_name: String, overwrite: bool = false) -> int:
	var result_code := ResultCodes.SUCCESS
	var tl_anim_lib := get_custom_library()

	# Check if the animation player has the User animation library and, if not, create it
	if not tl_anim_lib:
		tl_anim_lib = AnimationLibrary.new()
		$AnimationPlayer.add_animation_library(
			PopochiuResources.TRANSITION_LAYER_CUSTOM_ANIMLIB,
			tl_anim_lib
		)

	# Check for animation name collisions
	if tl_anim_lib.has_animation(anim_name) and not overwrite:
		result_code = ResultCodes.ERR_ANIMATION_ALREADY_EXISTS
		PopochiuUtils.print_error(ResultCodes.get_error_message(result_code) + " (%s)" % anim_name)
	else:
		tl_anim_lib.add_animation(anim_name, anim)

	return result_code


## Remove a custom transition from the User animation library.
func remove_custom_transition(anim_name: String) -> void:
	var tl_anim_lib: AnimationLibrary = get_custom_library()

	if not tl_anim_lib:
		return

	tl_anim_lib.remove_animation(anim_name)


## Check if an animation name is valid according to is_valid_animation_name() in
## godot/scene/resources/animation_library.cpp
static func is_valid_name(anim_name: String) -> bool:
	var r = RegEx.create_from_string(r'[/:,[]')
	return not (anim_name == "" or r.search(anim_name))


static func get_simple_name(anim_name: String) -> String:
	var prefix = PopochiuResources.TRANSITION_LAYER_CUSTOM_ANIMLIB.path_join("/")

	if anim_name.begins_with(prefix):
		return anim_name.split("/")[1].to_snake_case()

	return anim_name.to_snake_case()


static func get_custom_name(anim_name: String) -> String:
	var prefix = PopochiuResources.TRANSITION_LAYER_CUSTOM_ANIMLIB.path_join("/")

	if anim_name.begins_with(prefix):
		return prefix + anim_name.split("/")[1].to_snake_case()

	return prefix + anim_name.to_snake_case()


#endregion

#region Private ####################################################################################
# Called when an animation finishes playing
func _transition_finished(anim_name := "") -> void:
	if anim_name == "RESET":
		return

	transition_finished.emit(anim_name)

# Show interface elements when showing/hiding the transition layer
func _show() -> void:
	show()
	PopochiuUtils.g.hide_interface()


# Hide interface elements when hiding the transition layer
func _hide() -> void:
	hide()
	PopochiuUtils.g.show_interface()


# Hide RESET and other unwanted animations
func _hide_animations(anim_list: PackedStringArray) -> PackedStringArray:
	var i = anim_list.find("RESET")

	if i >= 0:
		anim_list.remove_at(i)

	return anim_list


# Reload transitions when the animation list changes
func _on_animation_player_animation_list_changed() -> void:
	PopochiuConfig.reload_transitions()


# Reload transitions when the animation libraries are updated
func _on_animation_player_animation_libraries_updated() -> void:
	PopochiuConfig.reload_transitions()
	# Reconnect to animation libraries signals when libraries are updated
	_connect_animation_libraries_signals()


# Connect to animation_removed signal from all animation libraries to handle removal of default transitions
func _connect_animation_libraries_signals() -> void:
	for lib_name in $AnimationPlayer.get_animation_library_list():
		var anim_lib = $AnimationPlayer.get_animation_library(lib_name)
		if anim_lib and not anim_lib.animation_removed.is_connected(_on_animation_removed):
			anim_lib.animation_removed.connect(_on_animation_removed.bind(lib_name))


# Called when an animation is removed from any animation library
# Checks if the removed animation is a configured default transition and resets to defaults
func _on_animation_removed(anim_name: String, lib_name: String) -> void:
	# Only care about predefined and custom libraries
	if lib_name != PopochiuResources.TRANSITION_LAYER_CUSTOM_ANIMLIB and not lib_name.is_empty():
		return

	# Build the full animation name (with library prefix if not the default library)
	var full_anim_name = get_simple_name(anim_name) if lib_name.is_empty() else get_custom_name(anim_name)

	# Check if the removed animation was a configured default for room changes...
	if full_anim_name.to_snake_case() == PopochiuConfig.get_tl_default_room_transition().to_snake_case():
		var fallback = PopochiuConfig.defaults[PopochiuConfig.TL_DEFAULT_ROOM_TRANSITION]
		PopochiuUtils.print_warning(
			"Removed animation '%s' was set as the default room transition. Falling back to '%s'." % [full_anim_name, fallback]
		)
		ProjectSettings.set_setting(PopochiuConfig.TL_DEFAULT_ROOM_TRANSITION, fallback.capitalize())
		ProjectSettings.save()
	# ... or for cutscene skips
	elif full_anim_name.to_snake_case() == PopochiuConfig.get_tl_default_cutscene_transition().to_snake_case():
		var fallback = PopochiuConfig.defaults[PopochiuConfig.TL_DEFAULT_CUTSCENE_TRANSITION]
		PopochiuUtils.print_warning(
			"Removed animation '%s' was set as the default cutscene transition. Falling back to '%s'." % [full_anim_name, fallback]
		)
		ProjectSettings.set_setting(PopochiuConfig.TL_DEFAULT_CUTSCENE_TRANSITION, fallback.capitalize())
		ProjectSettings.save()


#endregion
