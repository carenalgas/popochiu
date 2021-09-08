tool
extends HBoxContainer

signal target_clicked(type)

var audio_cue: AudioCue
var main_dock: Panel setget _set_main_dock
var stream_player: AudioStreamPlayer
var stream_player_2d: AudioStreamPlayer2D

var _current := 0.0

onready var _label: Label = find_node('Label')
onready var _add_to_music: Button = find_node('AddToMusic')
onready var _add_to_sfx: Button = find_node('AddToSFX')
onready var _add_to_voice: Button = find_node('AddToVoice')
onready var _add_to_ui: Button = find_node('AddToUI')
onready var _play: Button = find_node('Play')
onready var _stop: Button = find_node('Stop')
onready var _dflt_font_color: Color = _label.get_color('font_color')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_label.text = name
	_play.icon = _play.get_icon('MainPlay', 'EditorIcons')
	_stop.icon = _stop.get_icon('Stop', 'EditorIcons')
	
	if is_instance_valid(audio_cue):
		_label.text = audio_cue.resource_name
		
		_add_to_music.hide()
		_add_to_sfx.hide()
		_add_to_voice.hide()
		_add_to_ui.hide()
		find_node('PlayerSeparator').hide()
		
		_play.connect('pressed', self, '_play')
		_stop.connect('pressed', self, '_stop')
	else:	
		_add_to_music.connect('pressed', self, 'emit_signal', ['target_clicked', 'music'])
		_add_to_sfx.connect('pressed', self, 'emit_signal', ['target_clicked', 'sfx'])
		_add_to_voice.connect('pressed', self, 'emit_signal', ['target_clicked', 'voice'])
		_add_to_ui.connect('pressed', self, 'emit_signal', ['target_clicked', 'ui'])


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _play() -> void:
	if not is_instance_valid(audio_cue):
		# TODO: Crear un AudioStreamPlayer, cargarle el archivo de audio y
		# 		reproducirlo.
		return
	
	if not stream_player.stream or\
	stream_player.stream.resource_path != audio_cue.audio.resource_path:
		stream_player.stream = audio_cue.audio
	
	stream_player.pitch_scale = audio_cue.get_pitch()
	stream_player.volume_db = audio_cue.volume
	
	_label.add_color_override('font_color', Color('706deb'))
	
	if stream_player.is_playing():
		_current = stream_player.get_playback_position()
		stream_player.disconnect('finished', self, '_stop')
		stream_player.stop()
		_play.icon = _play.get_icon('MainPlay', 'EditorIcons')
	else:
		stream_player.connect('finished', self, '_stop')
		stream_player.play(_current)
		_play.icon = _play.get_icon('Pause', 'EditorIcons')


func _stop() -> void:
	_current = 0.0
	stream_player.stop()
	stream_player.stream = null
	_label.add_color_override('font_color', _dflt_font_color)
	_play.icon = _play.get_icon('MainPlay', 'EditorIcons')
	stream_player.disconnect('finished', self, '_stop')


func _set_main_dock(value: Panel) -> void:
	main_dock = value
