tool
extends Node

const AudioCue := preload('res://addons/Popochiu/Engine/AudioManager/AudioCue.gd')

#export(Array, Resource) var cues = [] setget _set_cues
export var mx_cues := []
export var sfx_cues := []
export var vo_cues := []
export var ui_cues := []

var twelfth_root_of_two := pow(2, (1.0 / 12))

var _mx_cues := {}
var _sfx_cues := {}
var _vo_cues := {}
var _ui_cues := {}
var _active := {}
var _all_in_one := {}

var _fading_sounds := {}

onready var _tween = $Tween


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
# warning-ignore-all:return_value_discarded
func _ready() -> void:
	for arr in ['mx_cues', 'sfx_cues', 'vo_cues', 'ui_cues']:
		for ac in self[arr]:
			self['_%s' % arr][ac.resource_name] = ac
			_all_in_one[ac.resource_name] = ac


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func semitone_to_pitch(pitch: float) -> float:
	return pow(twelfth_root_of_two, pitch)


func play(props = {
		cue_name = '', 
		pos = Vector2.ZERO, 
		is_in_queue = true, 
		wait_audio_complete = false, 
		fade = false,
		duration = 1, 
		from = -80, 
		to = 0
	}) -> void:
	if props.get('is_in_queue', true): yield()
	
	var dic: Dictionary = _all_in_one
	var stream_player: Node = null
	
#	if props.cue_name.find('vo_') > -1: dic = _vo_cues
#	else: dic = _sfx_cues
	
	if dic.has(props.cue_name.to_lower()):
		var cue: AudioCue = dic[props.cue_name.to_lower()]
		if not props.get('fade', false):
			stream_player = _play(cue, props.get('pos', Vector2.ZERO))
		else:
			stream_player = _fade_in(
				cue,
				props.get('pos', Vector2.ZERO),
				props.get('duration', 1),
				props.get('from', -80),
				props.get('to', cue.volume)
			)
	else:
		printerr('[Popochiu(A.play)] No se encontró el sonido', props.cue_name)
	
	if stream_player and props.get('wait_audio_complete', false):
		yield(stream_player, 'finished')
	else:
		yield(get_tree(), 'idle_frame')


func play_music(
		cue_name: String,
		is_in_queue := true,
		music_position = 0.0,
		fade = false,
		duration = 1
	) -> void:
	# TODO: Puede que sí necesite recibir la posición por si se quiere que la música
	# salga de un lugar específico (p.e. una radio en el escenario).
	if _mx_cues.has(cue_name.to_lower()):
		if is_in_queue: yield()
		
		var cue: AudioCue = _mx_cues[cue_name.to_lower()]
		if fade:
			_fade_in(cue, Vector2.ZERO, duration, -80, 0, music_position)
		else:
			_play(cue, Vector2.ZERO, music_position)
	else:
		printerr('[Popochiu(A.play_music)] No se encontró la música', cue_name)
	
	yield(get_tree(), 'idle_frame')


func stop(
		cue_name: String,
		_instance_i := 0,
		is_in_queue := true,
		fade = false,
		duration = 1
	) -> void:
	if is_in_queue: yield()
	
	if _active.has(cue_name):
		var stream_player: Node = (_active[cue_name].players as Array).front()
		
		if is_instance_valid(stream_player):
			if fade:
				_fade_sound(cue_name, duration, stream_player.volume_db, -80)
			else:
				stream_player.stop()
			
			if stream_player is AudioStreamPlayer2D and _active[cue_name].loop:
				# Cuando se detiene (.stop()) un audio en loop, por alguna razón
				# no se llama la señal de 'finished'.
				stream_player.emit_signal('finished')
		else:
			_active.erase(cue_name)
	
	yield(get_tree(), 'idle_frame')


func get_cue_position(cue_name: String, is_in_queue := true) -> void:
	var stream_player: Node = (_active[cue_name].players as Array).front()
	yield(get_tree(), 'idle_frame')


func change_cue_pitch(
		cue_name: String, new_pitch = 0, is_in_queue := true
	) -> void:
	if is_in_queue: yield()
	var stream_player: Node = (_active[cue_name].players as Array).front()
	stream_player.set_pitch_scale(semitone_to_pitch(new_pitch)) 
	yield(get_tree(), 'idle_frame')


func _fade_in(
		cue: AudioCue, pos, duration = 1, from = -80, to = 0, position = 0.0
	) -> Node:
	if cue.audio.get_instance_id() in _fading_sounds:
		from = _fading_sounds[cue.audio.get_instance_id()].volume_db
		$Tween.stop(_fading_sounds[cue.audio.get_instance_id()])
		_fading_sounds[cue.audio.get_instance_id()].emit_signal('finished')
		_fading_sounds.erase(cue.audio.get_instance_id())
	cue.volume = from
	
	var stream_player: Node = _play(cue, pos, position)
	if stream_player:
		_fade_sound(cue.resource_name, duration, from, to)
	
	cue.volume = to
	return stream_player


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
# Reproduce el sonido y se encarga de la lógica que lo asigna a un AudioStreamPlayer
# o crea uno nuevo si no hay disponibles
func _play(cue: AudioCue, pos := Vector2.ZERO, position = 0.0) -> Node:
	var player: Node = null
	
	if cue.is_2d:
		player = _get_free_stream($Positional)
		
		if not is_instance_valid(player):
			print_debug(
				'[Popochiu(A._play)] Nos quedamos sin AudioStreamPlayer2D'
			)
			return null

		(player as AudioStreamPlayer2D).stream = cue.audio
		(player as AudioStreamPlayer2D).pitch_scale = cue.get_pitch()
		(player as AudioStreamPlayer2D).volume_db = cue.volume
		(player as AudioStreamPlayer2D).max_distance = cue.max_distance
		(player as AudioStreamPlayer2D).position = pos
	else:
		player = _get_free_stream($Generic)
		
		if not is_instance_valid(player):
			print_debug(
				'[Popochiu(A._play)] Nos quedamos sin AudioStreamPlayer'
			)
			return null
	
		(player as AudioStreamPlayer).stream = cue.audio
		(player as AudioStreamPlayer).pitch_scale = cue.get_pitch()
		(player as AudioStreamPlayer).volume_db = cue.volume
	
	var cue_name := cue.resource_name
	
	player.bus = cue.bus
	player.play(position)
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
	var active_stream: Node = _reparent(group, $Active, 0)
	# TODO: Que cree un AudioStreamPlayer cuando haga falta uno
	
	return active_stream


# Reasigna el AudioStreamPlayer a su grupo original cuando ha terminado de sonar
# pa' que vuelva a estar disponible para ser usado
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


func _fadeout_finished(obj, key) -> void:
	if obj.stream.get_instance_id() in _fading_sounds :
		_fading_sounds.erase(obj.stream.get_instance_id())
		obj.stop()
		
		if _fading_sounds.empty():
			$Tween.disconnect('tween_completed', self, '_fadeout_finished')


func _sort_cues(a: AudioCue, b: AudioCue) -> bool:
	if a.resource_name < b.resource_name:
		return true
	return false
