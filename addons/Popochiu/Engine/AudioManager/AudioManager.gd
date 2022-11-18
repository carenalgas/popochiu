tool
extends Node
# (A) To work with audio (music and sound effects).
# TODO: Create AudioHandle so each AudioCue has its own AudioStreamPlayer...
# http://www.powerhoof.com/public/powerquestdocs/class_power_tools_1_1_quest_1_1_audio_handle.html
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# warning-ignore-all:return_value_discarded

const AudioCue := preload('AudioCue.gd')

var twelfth_root_of_two := pow(2, (1.0 / 12))

var _mx_cues := {}
var _sfx_cues := {}
var _vo_cues := {}
var _ui_cues := {}
var _active := {}
var _all_in_one := {}

var _fading_sounds := {}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	if Engine.editor_hint: return
	
	for arr in ['mx_cues', 'sfx_cues', 'vo_cues', 'ui_cues']:
		for rp in PopochiuResources.get_data_value('audio', arr, []):
			var ac: AudioCue = load(rp)
			self['_%s' % arr][ac.resource_name] = ac
			_all_in_one[ac.resource_name] = ac


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func play(
	cue_name := '', wait_to_end := false, position_2d := Vector2.ZERO
) -> Node:
	yield()
	
	return yield(_play_sound_cue(cue_name, position_2d, wait_to_end), 'completed')


func play_no_block(
	cue_name := '', wait_to_end := false, position_2d := Vector2.ZERO
) -> Node:
	if wait_to_end:
		return yield(_play_sound_cue(cue_name, position_2d, true), 'completed')
	else:
		return _play_sound_cue(cue_name, position_2d)


func play_music(\
cue_name: String, fade_duration := 0.0, music_position := 0.0) -> Node:
	# TODO: Add a position: Vector2 parameter in case one want to play music coming
	# out from a specific source (e.g. a radio in the room).
	yield()
	
	var stream_player: Node = _play_music_cue(
		cue_name, fade_duration, music_position
	)
	
	yield(get_tree(), 'idle_frame')
	
	return stream_player


func play_music_no_block(\
cue_name: String, fade_duration := 0.0, music_position := 0.0) -> Node:
	# TODO: Add a position: Vector2 parameter in case one want to play music coming
	# out from a specific source (e.g. a radio in the room).
	
	return _play_music_cue(cue_name, fade_duration, music_position)


func play_fade(
	cue_name := '',
	duration := 1.0,
	wait_to_end := false,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO
) -> Node:
	yield()
	
	return yield(
		_play_fade_cue(cue_name, duration, from, to, position_2d, wait_to_end),
		'completed'
	)


func play_fade_no_block(
	cue_name := '',
	duration := 1.0,
	wait_to_end := false,
	from := -80.0,
	to := INF,
	position_2d := Vector2.ZERO
) -> Node:
	if wait_to_end:
		return yield(_play_fade_cue(
			cue_name, 
			duration,
			from,
			to,
			position_2d,
			true
		), 'completed')
	else:
		return _play_fade_cue(cue_name, duration, from, to, position_2d)


func stop(cue_name: String, fade_duration := 0.0) -> void:
	yield()
	
	_stop(cue_name, fade_duration)
	
	yield(get_tree(), 'idle_frame')


func stop_no_block(cue_name: String, fade_duration := 0.0) -> void:
	_stop(cue_name, fade_duration)


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
# Looks for an AudioCue and plays it if found. It also can wait until it
# finishes playing.
# If wait_to_end is not null, that means the call is comming from a play
# inside a E.run([])
# In this method the calls to play and play_no_block converge.
func _play_sound_cue(\
cue_name := '', position_2d := Vector2.ZERO, wait_to_end = null) -> Node:
	var stream_player: Node = null
	
	if _all_in_one.has(cue_name.to_lower()):
		var cue: AudioCue = _all_in_one[cue_name.to_lower()]
		stream_player = _play(cue, position_2d)
	else:
		prints('[Popochiu] Sound not found:', cue_name)
		
		if wait_to_end != null:
			yield(get_tree(), 'idle_frame')
		
		return null
	
	if wait_to_end == true and stream_player:
		yield(stream_player, 'finished')
	elif wait_to_end == false:
		yield(get_tree(), 'idle_frame')
	
	return stream_player


# Looks for an AudioCue in the list of music cues and plays it.
# In this method the calls to play_music and play_music_no_block converge.
func _play_music_cue(\
cue_name: String, fade_duration := 0.0, music_position := 0.0) -> Node:
	var stream_player: Node = null
	
	if _active.has(cue_name):
		return _active[cue_name].players[0]
	
	if _mx_cues.has(cue_name.to_lower()):
		var cue: AudioCue = _mx_cues[cue_name.to_lower()]
		
		if fade_duration > 0.0:
			stream_player = _fade_in(
				cue, Vector2.ZERO, fade_duration, -80.0, cue.volume, music_position
			)
		else:
			stream_player = _play(cue, Vector2.ZERO, music_position)
	else:
		prints('[Popochiu] Music not found:', cue_name)
	
	return stream_player


# Looks for an AudioCue and plays it with a fade if found. It also can wait until
# it finishes playing.
# If wait_to_end is not null, that means the call is comming from a play
# inside a E.run([])
# In this method the calls to play and play_no_block converge.
func _play_fade_cue(
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
		prints('[Popochiu] Sound for fade not found:', cue_name)
		
		if wait_to_end != null:
			yield(get_tree(), 'idle_frame')
		
		return null
	
	if wait_to_end == true and stream_player:
		yield(stream_player, 'finished')
	elif wait_to_end == false:
		yield(get_tree(), 'idle_frame')
	
	return stream_player


# Plays the sound and assigns it to a free AudioStreamPlayer, or creates one if
# there are no more
func _play(cue: AudioCue, position := Vector2.ZERO, from_position := 0.0) -> Node:
	var player: Node = null
	
	if cue.is_2d:
		player = _get_free_stream($Positional)
		
		if not is_instance_valid(player):
			prints('[Popochiu] Run out of AudioStreamPlayer2D')
			return null

		(player as AudioStreamPlayer2D).stream = cue.audio
		(player as AudioStreamPlayer2D).pitch_scale = cue.get_pitch()
		(player as AudioStreamPlayer2D).volume_db = cue.volume
		(player as AudioStreamPlayer2D).max_distance = cue.max_distance
		(player as AudioStreamPlayer2D).position = position
	else:
		player = _get_free_stream($Generic)
		
		if not is_instance_valid(player):
			prints('[Popochiu] Run out of AudioStreamPlayer')
			return null
	
		(player as AudioStreamPlayer).stream = cue.audio
		(player as AudioStreamPlayer).pitch_scale = cue.get_pitch()
		(player as AudioStreamPlayer).volume_db = cue.volume
	
	var cue_name := cue.resource_name
	
	player.bus = cue.bus
	player.play(from_position)
	player.connect('finished', self, '_make_available', [player, cue_name, 0])
	
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
func _make_available(stream_player: Node, cue_name: String, _debug_idx: int) -> void:
	if stream_player is AudioStreamPlayer:
		_reparent($Active, $Generic, stream_player.get_index())
	else:
		_reparent($Active, $Positional, stream_player.get_index())
	
	var players: Array = _active[cue_name].players
	for idx in players.size():
		if players[idx].get_instance_id() == stream_player.get_instance_id():
			players.remove(idx)
			break
	
	if players.empty():
		_active.erase(cue_name)
	
	stream_player.disconnect('finished', self, '_make_available')


func _reparent(source: Node, target: Node, child_idx: int) -> Node:
	if source.get_children().empty(): return null
	
	var node_to_reparent: Node = source.get_child(child_idx)
	
	source.remove_child(node_to_reparent)
	target.add_child(node_to_reparent)
	
	return node_to_reparent


func _fade_in(\
cue: AudioCue,
position: Vector2,
duration := 1.0,
from := -80.0,
to := 0.0,
from_position := 0.0
) -> Node:
	if cue.audio.get_instance_id() in _fading_sounds:
		from = _fading_sounds[cue.audio.get_instance_id()].volume_db
		
		$Tween.stop(_fading_sounds[cue.audio.get_instance_id()])
		_fading_sounds[cue.audio.get_instance_id()].emit_signal('finished')
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
	
	$Tween.interpolate_property(
		stream_player, 'volume_db',
		from, to,
		duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	$Tween.start()
	
	if from > to :
		_fading_sounds[stream_player.stream.get_instance_id()] = stream_player
		
		if not $Tween.is_connected('tween_completed', self, '_fadeout_finished'):
			$Tween.connect('tween_completed', self, '_fadeout_finished')


func _fadeout_finished(obj: Node, _key: NodePath) -> void:
	if obj.stream.get_instance_id() in _fading_sounds :
		_fading_sounds.erase(obj.stream.get_instance_id())
		obj.stop()
		
		if _fading_sounds.empty():
			$Tween.disconnect('tween_completed', self, '_fadeout_finished')


func _stop(cue_name: String, fade_duration := 0.0) -> void:
	if _active.has(cue_name):
		var stream_player: Node = (_active[cue_name].players as Array).front()
		
		if is_instance_valid(stream_player):
			if fade_duration > 0.0:
				_fade_sound(cue_name, fade_duration, stream_player.volume_db, -80.0)
			else:
				stream_player.stop()
			
			if stream_player is AudioStreamPlayer2D and _active[cue_name].loop:
				# When stopped (.stop()) an audio in loop, for some reason
				# 'finished' is not emitted.
				stream_player.emit_signal('finished')
		else:
			_active.erase(cue_name)



func _sort_cues(a: AudioCue, b: AudioCue) -> bool:
	if a.resource_name < b.resource_name:
		return true
	return false


func _sort_resource_paths(a: String, b: String) -> bool:
	if a.get_file() < b.get_file():
		return true
	return false
