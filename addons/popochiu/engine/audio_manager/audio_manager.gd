class_name PopochiuAudioManager
extends Node
## Handles playing audio using [PopochiuAudioCue]s.
##
## It plays sound effects and music using [AudioStreamPlayer] or [AudioStreamPlayer2D], creating
## these nodes at runtime if needed. By default, it has 6 nodes for positional streams and 5 for
## playing non-positional streams.[br][br]
## The [b]PopochiuAudioManager[/b] is loaded as a child of [Popochiu] when the game starts.

## Used to mark stream players created at runtime that should be [method Node.free] when they are
## no longer needed.
const TEMP_PLAYER := "temporal"
## Specifies the path where the volume configuration for the audio buses used in the game is stored.
const SETTINGS_PATH = "user://audio_settings.save"

## Used to convert the value of the pitch set on [member PopochiuAudioCue.pitch] to the
## corresponding value needed for the [code]pitch_scale[/code] property of the audio stream players.
var twelfth_root_of_two := pow(2, (1.0 / 12))
## Stores the volume values for each of the audio buses used by the game.
var volume_settings := {}

var _mx_cues := {}
var _sfx_cues := {}
var _vo_cues := {}
var _ui_cues := {}
var _active := {}
var _all_in_one := {}
# Serves as a map that stores an AudioStreamPlayer/AudioStreamPlayer2D and the tween used to fade
# its volume
var _fading_sounds := {}
var _dflt_volumes := {}


#region Godot ######################################################################################
func _ready() -> void:
	if Engine.is_editor_hint(): return

	for bus_idx in range(AudioServer.get_bus_count()):
		var bus_name = AudioServer.get_bus_name(bus_idx)
		volume_settings[bus_name] = AudioServer.get_bus_volume_db(bus_idx)
	
	for arr in ["mx_cues", "sfx_cues", "vo_cues", "ui_cues"]:
		for rp in PopochiuResources.get_data_value("audio", arr, []):
			var ac: PopochiuAudioCue = load(rp)
			
			self["_%s" % arr][ac.resource_name] = ac
			_all_in_one[ac.resource_name] = ac
			_dflt_volumes[ac.resource_name] = ac.volume


#endregion

#region Public #####################################################################################
## Searches for the [PopochiuAudioCue] identified by [param cue_name] among the cues that are NOT
## part of the music group and plays it. You can set a [param position_2d] to play it positionally.
## If [param wait_to_end] is set to [code]true[/code], the function will pause until the audio
## finishes.
func play_sound_cue(cue_name := "", position_2d := Vector2.ZERO, wait_to_end = null) -> Node:
	var stream_player: Node = null
	
	if _all_in_one.has(cue_name.to_lower()):
		var cue: PopochiuAudioCue = _all_in_one[cue_name.to_lower()]
		stream_player = _play(cue, position_2d)
	else:
		PopochiuUtils.print_error("Sound not found: " + cue_name)
		
		if wait_to_end != null:
			await get_tree().process_frame
		
		return null
	
	if wait_to_end == true and stream_player:
		await stream_player.finished
	elif wait_to_end == false:
		await get_tree().process_frame
	
	return stream_player


## Searches for the [PopochiuAudioCue] identified by [param cue_name] among the cues that are part
## of the music group and plays it. It can fade for [param fade_duration] seconds, and you can start
## playing it from a given [param music_position] in seconds.
func play_music_cue(cue_name: String, fade_duration := 0.0, music_position := 0.0) -> Node:
	var stream_player: Node = null
	
	if _active.has(cue_name):
		return _active[cue_name].players[0]
	
	if _mx_cues.has(cue_name.to_lower()):
		var cue: PopochiuAudioCue = _mx_cues[cue_name.to_lower()]
		# NOTE: fixes #27 AudioCues were losing the volume set in editor when
		# played with a fade
		cue.volume = _dflt_volumes[cue_name.to_lower()]
		if fade_duration > 0.0:
			stream_player = _fade_in(
				cue,
				Vector2.ZERO,
				fade_duration,
				-80.0,
				cue.volume,
				music_position
			)
		else:
			stream_player = _play(cue, Vector2.ZERO, music_position)
	else:
		PopochiuUtils.print_error("Music not found: " + cue_name)
	
	return stream_player


## Plays the [PopochiuAudioCue] identified by [param cue_name] using a fade that will last
## [param duration] seconds. Specify the starting volume with [param from] and the target volume
## with [param to]. You can play the audio positionally with [param position_2d] and wait for it
## to finish if [param wait_to_end] is set to [code]true[/code].
func play_fade_cue(
	cue_name := "",
	duration := 1.0,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO,
	wait_to_end = null
) -> Node:
	var stream_player: Node = null
	
	if _all_in_one.has(cue_name.to_lower()):
		var cue: PopochiuAudioCue = _all_in_one[cue_name.to_lower()]
		stream_player = _fade_in(cue, position_2d, duration, from, to if to != INF else cue.volume)
	else:
		PopochiuUtils.print_error("Sound to fade not found " + cue_name)
		
		if wait_to_end != null:
			await get_tree().process_frame
		
		return null
	
	if wait_to_end == true and stream_player:
		await stream_player.finished
	elif wait_to_end == false:
		await get_tree().process_frame
	
	return stream_player


## Stops the [PopochiuAudioCue] identified by [param cue_name]. It can use a fade effect that will
## last [param fade_duration] seconds.
func stop(cue_name: String, fade_duration := 0.0) -> void:
	if _active.has(cue_name):
		var stream_player: Node = (_active[cue_name].players as Array).front()
		
		if is_instance_valid(stream_player):
			if fade_duration > 0.0:
				_fade_sound(
					cue_name, fade_duration, stream_player.volume_db, -80.0
				)
			else:
				stream_player.stop()
				# Always emit the signal since it won't be emited if the audio
				# file haven't reach the end yet
				stream_player.finished.emit()
		else:
			_active.erase(cue_name)


## Returns the playback position of the [PopochiuAudioCue] identified by [param cue_name].
func get_cue_playback_position(cue_name: String) -> float:
	if not _active.has(cue_name): return -1.0
	
	var stream_player: Node = (_active[cue_name].players as Array).front()
	
	if is_instance_valid(stream_player):
		return stream_player.get_playback_position()
	
	return -1.0


## Changes the [code]pitch_scale[/code] of the [PopochiuAudioCue] identified by [param cue_name] to
## the value set (in semitones) in [param pitch].
func change_cue_pitch(cue_name: String, pitch := 0.0) -> void:
	if not _active.has(cue_name): return
	
	var stream_player: Node = (_active[cue_name].players as Array).front()
	stream_player.set_pitch_scale(_semitone_to_pitch(pitch))


## Changes the [code]volume_db[/code] of the [PopochiuAudioCue] identified by [param cue_name] to
## the value set in [param volume].
func change_cue_volume(cue_name: String, volume := 0.0) -> void:
	if not _active.has(cue_name): return
	
	var stream_player: Node = (_active[cue_name].players as Array).front()
	stream_player.volume_db = volume


## Sets [param value] as the volume of the audio bus identified with [param bus_name].
func set_bus_volume_db(bus_name: String, value: float) -> void:
	if volume_settings.has(bus_name):
		volume_settings[bus_name] = value
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(bus_name), volume_settings[bus_name]
		)
		
		save_sound_settings()


## Saves in the file at [constant SETTINGS_PATH] the volume values of all the audio buses.
func save_sound_settings():
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)

	if file == null:
		PopochiuUtils.print_error("Error opening file: " + SETTINGS_PATH)
	else:
		file.store_var(volume_settings)
		file.close()


## Loads the volume values stored at [constant SETTINGS_PATH] for all the audio buses.
func load_sound_settings():
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)

	if file:
		volume_settings = file.get_var(true)
		file.close()
		for bus_idx in range(AudioServer.get_bus_count()):
			var bus_name = AudioServer.get_bus_name(bus_idx)
			if volume_settings.has(bus_name):
				AudioServer.set_bus_volume_db(
					AudioServer.get_bus_index(bus_name),
					volume_settings[bus_name]
				)
			else:
				volume_settings[bus_name] = AudioServer.get_bus_volume_db(bus_idx)


## Returns [code]true[/code] if the [PopochiuAudioCue] identified by [param cue_name] is playing.
func is_playing_cue(cue_name: String) -> bool:
	return get_cue_playback_position(cue_name) > -1


#endregion

#region Private ####################################################################################
# Calculates the [code]pitch_scale[/code] value of [param pitch], which is in semitones.
func _semitone_to_pitch(pitch: float) -> float:
	return pow(twelfth_root_of_two, pitch)


# Plays the sound and assigns it to a free AudioStreamPlayer, or creates one if there are no more.
func _play(
	cue: PopochiuAudioCue, position := Vector2.ZERO, from_position := 0.0
) -> Node:
	var player: Node = null
	
	if cue.is_2d:
		player = _get_free_stream($Positional)
		
		if not is_instance_valid(player):
			player = AudioStreamPlayer2D.new()
			player.set_meta(TEMP_PLAYER, true)
			$Active.add_child(player)

		(player as AudioStreamPlayer2D).stream = cue.audio
		(player as AudioStreamPlayer2D).pitch_scale = cue.get_pitch_scale()
		(player as AudioStreamPlayer2D).volume_db = cue.volume
		(player as AudioStreamPlayer2D).max_distance = cue.max_distance
		(player as AudioStreamPlayer2D).position = position
	else:
		player = _get_free_stream($Generic)
		
		if not is_instance_valid(player):
			player = AudioStreamPlayer.new()
			player.set_meta(TEMP_PLAYER, true)
			$Active.add_child(player)
	
		(player as AudioStreamPlayer).stream = cue.audio
		(player as AudioStreamPlayer).pitch_scale = cue.get_pitch_scale()
		(player as AudioStreamPlayer).volume_db = cue.volume
	
	var cue_name: String = cue.resource_name
	
	player.bus = cue.bus
	player.play(from_position)
	
	if not player.finished.is_connected(_on_audio_stream_player_finished):
		player.finished.connect(_on_audio_stream_player_finished.bind(player, cue_name, 0))
	
	if _active.has(cue_name):
		_active[cue_name].players.append(player)
		
		# NOTE: Stop the previous stream player created to play the audio cue
		# 		that is in loop to avoid having more than one sound playing.
		if not _active[cue_name].can_play_simultaneous:
			stop(cue_name)
	else:
		_active[cue_name] = {
			players = [player],
			loop = cue.loop,
			can_play_simultaneous = cue.can_play_simultaneous
		}
	
	return player


func _get_free_stream(group: Node):
	return _reparent(group, $Active, 0)


# Reassigns the [AudioStreamPlayer] to its original group when it finishes so it can be available
# for being used again.
func _on_audio_stream_player_finished(
	stream_player: Node, cue_name: String, _debug_idx: int
) -> void:
	if stream_player.has_meta(TEMP_PLAYER):
		stream_player.queue_free()
	elif stream_player is AudioStreamPlayer:
		_reparent($Active, $Generic, stream_player.get_index())
	else:
		_reparent($Active, $Positional, stream_player.get_index())
	
	if _active.has(cue_name):
		var players: Array = _active[cue_name].players
		for idx in players.size():
			if players[idx].get_instance_id() == stream_player.get_instance_id():
				players.remove_at(idx)
				break
	
		if players.is_empty():
			_active.erase(cue_name)
	
	if not stream_player.finished.is_connected(_on_audio_stream_player_finished):
		stream_player.finished.connect(_on_audio_stream_player_finished)


func _reparent(source: Node, target: Node, child_idx: int) -> Node:
	if not is_instance_valid(source) or source.get_children().is_empty():
		return null
	
	var node_to_reparent: Node = source.get_child(child_idx)
	
	if not is_instance_valid(node_to_reparent):
		return null
	
	node_to_reparent.reparent(target)
	
	return node_to_reparent


func _fade_in(
	cue: PopochiuAudioCue,
	position: Vector2,
	duration := 1.0,
	from := -80.0,
	to := 0.0,
	from_position := 0.0
) -> Node:
	if cue.audio.get_instance_id() in _fading_sounds:
		from = _fading_sounds[cue.audio.get_instance_id()].stream.volume_db
		
		var tween: Tween = _fading_sounds[cue.audio.get_instance_id()].tween
		# Stop the tween only of the sound that is fading
		
		if is_instance_valid(tween) and tween.is_running():
			tween.kill()
		
		_fading_sounds[cue.audio.get_instance_id()].finished.emit()
		_fading_sounds.erase(cue.audio.get_instance_id())
	
	cue.volume = from
	
	var stream_player: Node = _play(cue, position, from_position)
	
	if stream_player:
		_fade_sound(cue.resource_name, duration, from, to)
	else:
		cue.volume = to
	
	return stream_player


func _fade_sound(cue_name: String, duration = 1, from = 0, to = 0) -> void:
	var stream_player: Node = (_active[cue_name].players as Array).front()
	
	if _fading_sounds.has(stream_player.stream.get_instance_id()):
		_fading_sounds[stream_player.stream.get_instance_id()].tween.kill()
	
	var t := create_tween().set_ease(Tween.EASE_IN_OUT)
	t.finished.connect(_fadeout_finished.bind(stream_player, t))
	t.tween_property(stream_player, "volume_db", to, duration).from(from)
	
	if from > to :
		_fading_sounds[stream_player.stream.get_instance_id()] = {
			stream = stream_player,
			tween = t
		}


func _fadeout_finished(stream_player: Node, tween: Tween) -> void:
	if stream_player.stream.get_instance_id() in _fading_sounds :
		_fading_sounds.erase(stream_player.stream.get_instance_id())
		stream_player.stop()
		tween.finished.disconnect(_fadeout_finished)


#endregion
