tool
extends HBoxContainer

signal target_clicked(type)
signal deleted(file_path)

var file_name: String
var file_path: String
var audio_cue: AudioCue
var cue_group: String
var main_dock: Panel setget _set_main_dock
var stream_player: AudioStreamPlayer
var stream_player_2d: AudioStreamPlayer2D

var _current := 0.0
var _confirmation_dialog: ConfirmationDialog
var _delete_all_checkbox: CheckBox

onready var _label: Label = find_node('Label')
onready var _dflt_font_color: Color = _label.get_color('font_color')
onready var _add_to_music: Button = find_node('AddToMusic')
onready var _add_to_sfx: Button = find_node('AddToSFX')
onready var _add_to_voice: Button = find_node('AddToVoice')
onready var _add_to_ui: Button = find_node('AddToUI')
onready var _play: Button = find_node('Play')
onready var _stop: Button = find_node('Stop')
onready var _delete: Button = find_node('Delete')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_label.text = file_name if file_name else name
	_play.icon = _play.get_icon('MainPlay', 'EditorIcons')
	_stop.icon = _stop.get_icon('Stop', 'EditorIcons')
	
	connect('gui_input', self, '_open_in_inspector')
	_play.connect('pressed', self, '_play')
	_stop.connect('pressed', self, '_stop')
	_delete.connect('pressed', self, '_ask_basic_delete')
	
	if is_instance_valid(audio_cue):
		_label.text = audio_cue.resource_name
		
		_add_to_music.hide()
		_add_to_sfx.hide()
		_add_to_voice.hide()
		_add_to_ui.hide()
		find_node('PlayerSeparator').hide()
	else:
		_add_to_music.connect(
			'pressed', self, 'emit_signal', ['target_clicked', 'music']
		)
		_add_to_sfx.connect(
			'pressed', self, 'emit_signal', ['target_clicked', 'sfx']
		)
		_add_to_voice.connect(
			'pressed', self, 'emit_signal', ['target_clicked', 'voice']
		)
		_add_to_ui.connect(
			'pressed', self, 'emit_signal', ['target_clicked', 'ui']
		)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _open_in_inspector(event: InputEvent) -> void:
	var mouse_event: = event as InputEventMouseButton
	if is_instance_valid(audio_cue) and mouse_event\
	and mouse_event.button_index == BUTTON_LEFT and mouse_event.pressed:
		main_dock.ei.select_file(audio_cue.resource_path)
		main_dock.ei.edit_resource(audio_cue)
		_label.add_color_override('font_color', Color('706deb'))


func _play() -> void:
	if not is_instance_valid(audio_cue):
		var stream: AudioStream = load(file_path)
		stream.loop = false
		stream_player.stream = stream
	elif not stream_player.stream or\
	stream_player.stream.resource_path != audio_cue.audio.resource_path:
		stream_player.stream = audio_cue.audio
		stream_player.pitch_scale = audio_cue.get_pitch()
		stream_player.volume_db = audio_cue.volume
	
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
	
	if stream_player.is_connected('finished', self, '_stop'):
		stream_player.disconnect('finished', self, '_stop')


# Abre un popup de confirmación para saber si la desarrolladora quiere eliminar
# el objeto del núcleo del plugin y del sistema.
func _ask_basic_delete() -> void:
	_confirmation_dialog.get_cancel().connect('pressed', self, '_disconnect_popup')
	
	if is_instance_valid(audio_cue):
		main_dock.show_confirmation(
			'Se eliminará a %s del Audio manager' % audio_cue.resource_name,
			'Esto eliminará la referencia de [b]%s[/b] en el Audio manager.'\
			% audio_cue.resource_name +\
			' Los usos de este objeto dentro de los scripts dejarán de' +\
			'  funcionar. Esta acción no se puede revertir. ¿Quiere continuar?',
			'Eliminar también el archivo [b]%s[/b]' % audio_cue.resource_path +\
			' (no se puede revertir)'
		)
		
		_confirmation_dialog.connect('confirmed', self, '_remove_in_audio_manager')
	else:
		main_dock.show_confirmation(
			'Se eliminará [b]%s[/b] del sistema' % file_name,
			'Esto eliminará el archivo en %s.' % file_path +\
			' Esta acción no se puede revertir. ¿Quiere continuar?'
		)
		
		_confirmation_dialog.connect(
			'confirmed',
			self,
			'_delete_from_file_system',
			[file_path]
		)


func _remove_in_audio_manager() -> void:
	_confirmation_dialog.disconnect('confirmed', self, '_remove_in_audio_manager')
	
	# Eliminar el AudioCue del AudioManager ------------------------------------
	var am: Node = main_dock.get_audio_manager()
	am[cue_group].erase(audio_cue)
	
	if main_dock.save_audio_manager() != OK:
		push_error('[Popochiu] No se pudo eliminar el AudioCue del'\
		+ ' AudioManager: %s' % audio_cue.resource_name)
		# TODO: Mostrar retroalimentación en el mismo popup
	
	# Crear una fila en el grupo de archivos sin asignar.
	emit_signal('deleted', audio_cue.audio.resource_path)
	
	if _delete_all_checkbox.pressed:
		_delete_from_file_system(audio_cue.resource_path)
	else:
		queue_free()


# Elimina el directorio del objeto del sistema.
func _delete_from_file_system(path: String) -> void:
	# Eliminar el .tres del AudioCue del disco
	var err: int = main_dock.dir.remove(path)
	main_dock.fs.update_file(path)
	
	if err != OK:
		push_error('[Popochiu:%d] No se pudo eliminar el archivo %s' %\
		[err, path])
		return
	
	# Eliminar el objeto de su lista -------------------------------------------
	_disconnect_popup()
	queue_free()


# Se desconecta de las señales del popup utilizado para configurar la eliminación.
func _disconnect_popup() -> void:
	if _confirmation_dialog.is_connected('confirmed', self, '_remove_in_audio_manager'):
		_confirmation_dialog.disconnect('confirmed', self, '_remove_in_audio_manager')
	
	if _confirmation_dialog.is_connected('confirmed', self, '_delete_from_file_system'):
		# Se canceló la eliminación de los archivos en disco
		_confirmation_dialog.disconnect('confirmed', self, '_delete_from_file_system')


func _set_main_dock(value: Panel) -> void:
	main_dock = value
	_confirmation_dialog = value.delete_confirmation
	_delete_all_checkbox = _confirmation_dialog.find_node('CheckBox')
