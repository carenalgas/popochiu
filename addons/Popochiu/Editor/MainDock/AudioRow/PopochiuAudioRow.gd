tool
extends HBoxContainer

signal target_clicked(type)
signal deleted(file_path)

enum MenuOptions { ADD_TO_MUSIC, ADD_TO_SFX, ADD_TO_VOICE, ADD_TO_UI, DELETE }

const SELECTED_FONT_COLOR := Color('706deb')
const AudioCue := preload('res://addons/Popochiu/Engine/AudioManager/AudioCue.gd')

var file_name: String
var file_path: String
var audio_cue: AudioCue
var cue_group: String
var main_dock: Panel setget _set_main_dock
var stream_player: AudioStreamPlayer
var audio_tab: VBoxContainer = null

var _current := 0.0
var _confirmation_dialog: ConfirmationDialog
var _delete_all_checkbox: CheckBox

onready var _label: Label = find_node('Label')
onready var _dflt_font_color: Color = _label.get_color('font_color')
onready var _menu_btn: MenuButton = find_node('MenuButton')
onready var _menu_popup: PopupMenu = _menu_btn.get_popup()
onready var _play: Button = find_node('Play')
onready var _stop: Button = find_node('Stop')
onready var _menu_cfg := [
	{
		id = MenuOptions.ADD_TO_MUSIC,
		icon = preload('res://addons/Popochiu/icons/music.png'),
		label = 'Add to Music'
	},
	{
		id = MenuOptions.ADD_TO_SFX,
		icon = preload('res://addons/Popochiu/icons/sfx.png'),
		label = 'Add to Sound effects'
	},
	{
		id = MenuOptions.ADD_TO_VOICE,
		icon = preload('res://addons/Popochiu/icons/voice.png'),
		label = 'Add to Voices'
	},
	{
		id = MenuOptions.ADD_TO_UI,
		icon = preload('res://addons/Popochiu/icons/ui.png'),
		label = 'Add to Graphic interface'
	},
	null,
	{
		id = MenuOptions.DELETE,
		icon = get_icon('Remove', 'EditorIcons'),
		label = 'Remove'
	}
]


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	_label.text = file_name if file_name else name
	_menu_btn.icon = get_icon('GuiTabMenu', 'EditorIcons')
	_play.icon = get_icon('MainPlay', 'EditorIcons')
	_stop.icon = get_icon('Stop', 'EditorIcons')
	
	# Crear menú contextual
	_create_menu()
	
	connect('gui_input', self, '_open_in_inspector')
	_menu_popup.connect('id_pressed', self, '_menu_item_pressed')
	_play.connect('pressed', self, '_play')
	_stop.connect('pressed', self, '_stop')
	
	if is_instance_valid(audio_cue):
		_label.text = audio_cue.resource_name
		
		for idx in range(4):
			_menu_popup.set_item_disabled(idx, true)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func select() -> void:
	if is_instance_valid(audio_tab.last_selected):
		audio_tab.last_selected.unselect()
	
	main_dock.ei.select_file(audio_cue.resource_path)
	main_dock.ei.edit_resource(audio_cue)
	_label.add_color_override('font_color', SELECTED_FONT_COLOR)
	audio_tab.last_selected = self


func unselect() -> void:
	_label.add_color_override('font_color', _dflt_font_color)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _create_menu() -> void:
	_menu_popup.clear()
	
	for option in _menu_cfg:
		if option:
			_menu_popup.add_icon_item(
				option.icon,
				option.label,
				option.id
			)
		else:
			_menu_popup.add_separator()


func _open_in_inspector(event: InputEvent) -> void:
	var mouse_event: = event as InputEventMouseButton
	if is_instance_valid(audio_cue) and mouse_event\
	and mouse_event.button_index == BUTTON_LEFT and mouse_event.pressed:
		select()


func _menu_item_pressed(id: int) -> void:
	match id:
		MenuOptions.ADD_TO_MUSIC:
			emit_signal('target_clicked', 'music')
		MenuOptions.ADD_TO_SFX:
			emit_signal('target_clicked', 'sfx')
		MenuOptions.ADD_TO_VOICE:
			emit_signal('target_clicked', 'voice')
		MenuOptions.ADD_TO_UI:
			emit_signal('target_clicked', 'ui')
		MenuOptions.DELETE:
			_ask_basic_delete()


func _play() -> void:
	if is_instance_valid(audio_tab.last_played)\
	and audio_tab.last_played.get_instance_id() != get_instance_id():
		audio_tab.last_played._stop()
	
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
		audio_tab.last_played = self


func _stop() -> void:
	_current = 0.0
	stream_player.stop()
	stream_player.stream = null
	_label.add_color_override('font_color', _dflt_font_color)
	_play.icon = _play.get_icon('MainPlay', 'EditorIcons')
	
	if stream_player.is_connected('finished', self, '_stop'):
		stream_player.disconnect('finished', self, '_stop')
	
	audio_tab.last_played = null


# Abre un popup de confirmación para saber si la desarrolladora quiere eliminar
# el objeto del núcleo del plugin y del sistema.
func _ask_basic_delete() -> void:
	_confirmation_dialog.get_cancel().connect('pressed', self, '_disconnect_popup')
	
	if is_instance_valid(audio_cue):
		main_dock.show_confirmation(
			'Remove %s from AudioManager' % audio_cue.resource_name,
			'This will remove the [b]%s[/b] resource in AudioManager.'\
			% audio_cue.resource_name +\
			' Calls to this audio in scripts will not work anymore.' +\
			' This action cannot be reversed. Continue?',
			'Delete [b]%s[/b] file too?' % audio_cue.resource_path +\
			' (cannot be reversed)'
		)
		
		_confirmation_dialog.connect('confirmed', self, '_remove_in_audio_manager')
	else:
		main_dock.show_confirmation(
			'[b]%s[/b] file deletion' % file_name,
			'%s will be deleted in filesystem.' % file_path +\
			' This action cannot be reversed. Continue?'
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
	var am: Node = audio_tab.get_audio_manager()
	am[cue_group].erase(audio_cue)
	
	if audio_tab.save_audio_manager() != OK:
		push_error('[Popochiu] Could not remove %s AudioCue in AudioManager.' \
		% audio_cue.resource_name)
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
		push_error('[Popochiu(err_code:%d)] Could not delete file %s' %\
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
	_confirmation_dialog = main_dock.delete_dialog
	_delete_all_checkbox = _confirmation_dialog.find_node('CheckBox')
