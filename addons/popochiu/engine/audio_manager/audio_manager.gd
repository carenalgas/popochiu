# Handles playing audio with AudioCues.
# 
# TODO: Create AudioHandle so each AudioCue has its own AudioStreamPlayer...
# http://www.powerhoof.com/public/powerquestdocs/class_power_tools_1_1_quest_1_1_audio_handle.html
extends Node
class_name PopochiuAudioManager
@warning_ignore("return_value_discarded")

const AudioCue := preload('audio_cue.gd')

var twelfth_root_of_two := pow(2, (1.0 / 12))

var _mx_cues := {}
var _sfx_cues := {}
var _vo_cues := {}
var _ui_cues := {}
var _active := {}
var _all_in_one := {}
# Serves as a map that stores an AudioStreamPlayer/AudioStreamPlayer2D and the
# tween used to fade its volume
var _fading_sounds := {}
var _dflt_volumes := {}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	for arr in ['mx_cues', 'sfx_cues', 'vo_cues', 'ui_cues']:
		for rp in PopochiuResources.get_data_value('audio', arr, []):
			var ac: AudioCue = load(rp)
			self['_%s' % arr][ac.resource_name] = ac
			_all_in_one[ac.resource_name] = ac
			_dflt_volumes[ac.resource_name] = ac.volume


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Looks for an AudioCue and plays it if found. It also can wait until it
# finishes playing.
# If wait_to_end is not null, that means the call is comming from a play
# inside a E.queue([])
# In this method the calls to play and play_no_block converge.
func play_sound_cue(
	cue_name := '', position_2d := Vector2.ZERO, wait_to_end = null
) -> Node:
	var stream_player: Node = null
	
	if _all_in_one.has(cue_name.to_lower()):
		var cue: AudioCue = _all_in_one[cue_name.to_lower()]
		stream_player = _play(cue, position_2d)
	else:
		printerr('[Popochiu] Sound not found:', cue_name)
		
		if wait_to_end != null:
			await get_tree().process_frame
		
		return null
	
	if wait_to_end == true and stream_player:
		await stream_player.finished
	elif wait_to_end == false:
		await get_tree().process_frame
	
	return stream_player


# Looks for an AudioCue in the list of music cues and plays it.
# In this method the calls to play_music and play_music_no_block converge.
func play_music_cue(
	cue_name: String, fade_duration := 0.0, music_position := 0.0
) -> Node:
	var stream_player: Node = null
	
	if _active.has(cue_name):
		return _active[cue_name].players[0]
	
	if _mx_cues.has(cue_name.to_lower()):
		var cue: AudioCue = _mx_cues[cue_name.to_lower()]
		# FIX: #27 AudioCues were losing the volume set in editor when played
		# with a fade
		cue.volume = _dflt_volumes[cue_name.to_lower()]
		
		if fade_duration > 0.0:
			stream_player = _fade_in(
				cue, Vector2.ZERO, fade_duration,
				-80.0, cue.volume, music_position
			)
		else:
			stream_player = _play(cue, Vector2.ZERO, music_position)
	else:
		printerr('[Popochiu] Music not found:', cue_name)
	
	return stream_player


# Looks for an AudioCue and plays it with a fade if found. It also can wait until
# it finishes playing.
# If wait_to_end is not null, that means the call is comming from a play
# inside a E.queue([])
# In this method the calls to play and play_no_block converge.
func play_fade_cue(
	cue_name := '',
	duration := 1.0,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO,
	wait_to_end = null
) -> Node:
	var stream_player: Node = null
	
	if _all_in_one.has(cue_name.to_lower()):
		var cue: AudioCue = _all_in_one[cue_name.to_lower()]
		stream_player = _fade_in(
			cue,
			position_2d,
			duration,
			from,
			to if to != INF else cue.volume
		)
	else:
		printerr('[Popochiu] Sound for fade not found:', cue_name)
		
		if wait_to_end != null:
			await get_tree().process_frame
		
		return null
	
	if wait_to_end == true and stream_player:
		await stream_player.finished
	elif wait_to_end == false:
		await get_tree().process_frame
	
	return stream_player


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
			
			if stream_player is AudioStreamPlayer2D and _active[cue_name].loop:
				# When stopped (.stop()) an audio in loop, for some reason
				# 'finished' is not emitted.
				stream_player.finished.emit()
		else:
			_active.erase(cue_name)


func get_cue_playback_position(cue_name: String) -> float:
	if not _active.has(cue_name): return -1.0
	
	var stream_player: Node = (_active[cue_name].players as Array).front()
	
	if is_instance_valid(stream_player):
		return stream_player.get_playback_position()
	
	return -1.0


func change_cue_pitch(cue_name: String, pitch := 0.0) -> void:
	if not _active.has(cue_name): return
	
	var stream_player: Node = (_active[cue_name].players as Array).front()
	stream_player.set_pitch_scale(semitone_to_pitch(pitch))


func change_cue_volume(cue_name: String, volume := 0.0) -> void:
	if not _active.has(cue_name): return
	
	var stream_player: Node = (_active[cue_name].players as Array).front()
	stream_player.volume_db = volume


func semitone_to_pitch(pitch: float) -> float:
	return pow(twelfth_root_of_two, pitch)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
# Plays the sound and assigns it to a free AudioStreamPlayer, or creates one if
# there are no more
func _play(
	cue: AudioCue, position := Vector2.ZERO, from_position := 0.0
) -> Node:
	var player: Node = null
	
	if cue.is_2d:
		player = _get_free_stream($Positional)
		
		if not is_instance_valid(player):
			printerr('[Popochiu] Run out of AudioStreamPlayer2D')
			return null

		(player as AudioStreamPlayer2D).stream = cue.audio
		(player as AudioStreamPlayer2D).pitch_scale = cue.pitch
		(player as AudioStreamPlayer2D).volume_db = cue.volume
		(player as AudioStreamPlayer2D).max_distance = cue.max_distance
		(player as AudioStreamPlayer2D).position = position
	else:
		player = _get_free_stream($Generic)
		
		if not is_instance_valid(player):
			printerr('[Popochiu] Run out of AudioStreamPlayer')
			return null
	
		(player as AudioStreamPlayer).stream = cue.audio
		(player as AudioStreamPlayer).pitch_scale = cue.pitch
		(player as AudioStreamPlayer).volume_db = cue.volume
	
	var cue_name: String = cue.resource_name
	
	player.bus = cue.bus
	player.play(from_position)
	player.finished.connect(_make_available.bind(player, cue_name, 0))
	
	if _active.has(cue_name):
		_active[cue_name].players.append(player)
	else:
		_active[cue_name] = {
			players = [player],
			loop = cue.loop
		}
	
	return player


func _get_free_stream(group: Node):
	return _reparent(group, $Active, 0)


# Reassigns the AudioStreamPlayer to its original group when it finishes so it
# can be available for being used
func _make_available(
	stream_player: Node, cue_name: String, _debug_idx: int
) -> void:
	if stream_player is AudioStreamPlayer:
		_reparent($Active, $Generic, stream_player.get_index())
	else:
		_reparent($Active, $Positional, stream_player.get_index())
	
	var players: Array = _active[cue_name].players
	for idx in players.size():
		if players[idx].get_instance_id() == stream_player.get_instance_id():
			players.remove_at(idx)
			break
	
	if players.is_empty():
		_active.erase(cue_name)
	
	if not stream_player.finished.is_connected(_make_available):
		stream_player.finished.connect(_make_available)


func _reparent(source: Node, target: Node, child_idx: int) -> Node:
	if not is_instance_valid(source) or source.get_children().is_empty():
		return null
	
	var node_to_reparent: Node = source.get_child(child_idx)
	
	source.remove_child(node_to_reparent)
	target.add_child(node_to_reparent)
	
	return node_to_reparent


func _fade_in(
	cue: AudioCue,
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
	
	var t := create_tween()
	t.finished.connect(_fadeout_finished.bind(stream_player, t))
	t.tween_property(stream_player, 'volume_db', to, duration)\
	.from(from).set_ease(Tween.EASE_IN_OUT)
	
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
