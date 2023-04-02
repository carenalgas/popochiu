@tool
extends HBoxContainer

signal target_clicked(type)
signal deleted(file_path)

enum MenuOptions { ADD_TO_MUSIC, ADD_TO_SFX, ADD_TO_VOICE, ADD_TO_UI, DELETE }

const SELECTED_FONT_COLOR := Color('706deb')
const AudioCue := preload('res://addons/popochiu/engine/audio_manager/audio_cue.gd')

var file_name: String
var file_path: String
var audio_cue: AudioCue
var cue_group: String
var main_dock: Panel : set = _set_main_dock
var stream_player: AudioStreamPlayer
var audio_tab: VBoxContainer = null

var _current := 0.0
var _confirmation_dialog: ConfirmationDialog
var _delete_all_checkbox: CheckBox

@onready var _label: Label = find_child('Label')
@onready var _dflt_font_color: Color = _label.get_theme_color('font_color')
@onready var _menu_btn: MenuButton = find_child('MenuButton')
@onready var _menu_popup: PopupMenu = _menu_btn.get_popup()
@onready var _btn_play: Button = find_child('Play')
@onready var _btn_stop: Button = find_child('Stop')
@onready var _menu_cfg: Array = [
	{
		id = MenuOptions.ADD_TO_MUSIC,
		icon = preload('res://addons/popochiu/icons/music.png'),
		label = 'Add to Music'
	},
	{
		id = MenuOptions.ADD_TO_SFX,
		icon = preload('res://addons/popochiu/icons/sfx.png'),
		label = 'Add to Sound effects'
	},
	{
		id = MenuOptions.ADD_TO_VOICE,
		icon = preload('res://addons/popochiu/icons/voice.png'),
		label = 'Add to Voices'
	},
	{
		id = MenuOptions.ADD_TO_UI,
		icon = preload('res://addons/popochiu/icons/ui.png'),
		label = 'Add to Graphic interface'
	},
	null,
	{
		id = MenuOptions.DELETE,
		icon = get_theme_icon('Remove', 'EditorIcons'),
		label = 'Remove'
	}
]


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	_label.text = file_name if file_name else name
	tooltip_text = file_path if file_name else audio_cue.resource_path
	_menu_btn.icon = get_theme_icon('GuiTabMenu', 'EditorIcons')
	_btn_play.icon = get_theme_icon('MainPlay', 'EditorIcons')
	_btn_stop.icon = get_theme_icon('Stop', 'EditorIcons')
	
	# Crear menú contextual
	_create_menu()
	
	gui_input.connect(_open_in_inspector)
	_menu_popup.id_pressed.connect(_menu_item_pressed)
	_btn_play.pressed.connect(_play)
	_btn_stop.pressed.connect(_stop)
	
	if is_instance_valid(audio_cue):
		_label.text = audio_cue.resource_name
		name = audio_cue.resource_name
		
		_menu_popup.remove_item(
			_menu_popup.get_item_index(MenuOptions.ADD_TO_MUSIC)
		)
		_menu_popup.remove_item(
			_menu_popup.get_item_index(MenuOptions.ADD_TO_SFX)
		)
		_menu_popup.remove_item(
			_menu_popup.get_item_index(MenuOptions.ADD_TO_VOICE)
		)
		_menu_popup.remove_item(
			_menu_popup.get_item_index(MenuOptions.ADD_TO_UI)
		)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func select() -> void:
	if is_instance_valid(audio_tab.last_selected):
		audio_tab.last_selected.deselect()
	
	main_dock.ei.select_file(audio_cue.resource_path)
	main_dock.ei.edit_resource(audio_cue)
	_label.add_theme_color_override('font_color', SELECTED_FONT_COLOR)
	audio_tab.last_selected = self


func deselect() -> void:
	_label.add_theme_color_override('font_color', _dflt_font_color)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
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
	and mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		select()


func _menu_item_pressed(id: int) -> void:
	match id:
		MenuOptions.ADD_TO_MUSIC:
			target_clicked.emit('music')
		MenuOptions.ADD_TO_SFX:
			target_clicked.emit('sfx')
		MenuOptions.ADD_TO_VOICE:
			target_clicked.emit('voice')
		MenuOptions.ADD_TO_UI:
			target_clicked.emit('ui')
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
		stream_player.pitch_scale = audio_cue.pitch
		stream_player.volume_db = audio_cue.volume
	
	if stream_player.is_playing():
		_current = stream_player.get_playback_position()
		stream_player.finished.disconnect(_stop)
		stream_player.stop()
		_btn_play.icon = _btn_play.get_theme_icon('MainPlay', 'EditorIcons')
	else:
		stream_player.finished.connect(_stop)
		stream_player.play(_current)
		_btn_play.icon = _btn_play.get_theme_icon('Pause', 'EditorIcons')
		audio_tab.last_played = self


func _stop() -> void:
	_current = 0.0
	stream_player.stop()
	stream_player.stream = null
	_label.add_theme_color_override('font_color', _dflt_font_color)
	_btn_play.icon = _btn_play.get_theme_icon('MainPlay', 'EditorIcons')
	
	if stream_player.finished.is_connected(_stop):
		stream_player.finished.disconnect(_stop)
	
	audio_tab.last_played = null


# Abre un popup de confirmación para saber si la desarrolladora quiere eliminar
# el objeto del núcleo del plugin y del sistema.
func _ask_basic_delete() -> void:
	_confirmation_dialog.get_cancel_button().pressed.connect(_disconnect_popup)
	
	if is_instance_valid(audio_cue):
		main_dock.show_confirmation(
			'Remove %s' % audio_cue.resource_name,
			'This will remove the [b]%s[/b] resource.'\
			% audio_cue.resource_name +\
			' Calls to this audio in scripts will not work anymore.' +\
			' This action cannot be reversed. Continue?',
			'Delete [b]%s[/b] file too?' % audio_cue.resource_path +\
			' (cannot be reversed)'
		)
		
		_confirmation_dialog.confirmed.connect(_remove_in_audio_manager)
	else:
		main_dock.show_confirmation(
			'[b]%s[/b] file deletion' % file_name,
			'%s will be deleted in filesystem.' % file_path +\
			' This action cannot be reversed. Continue?'
		)
		
		_confirmation_dialog.confirmed.connect(
			_delete_from_file_system.bind(file_path)
		)


func _remove_in_audio_manager() -> void:
	_confirmation_dialog.confirmed.disconnect(_remove_in_audio_manager)
	
	# Remove the AudioCue from PopochiuData.cfg --------------------------------
	var group_data: Array = PopochiuResources.get_data_value(
		'audio', cue_group, []
	)
	if group_data:
		group_data.erase(audio_cue.resource_path)
		
		if group_data.is_empty():
			PopochiuResources.erase_data_value('audio', cue_group)
		else:
			group_data.sort_custom(
				func (a: String, b: String) -> bool:
					return PopochiuUtils.sort_by_file_name(a, b)
			)
			PopochiuResources.set_data_value('audio', cue_group, group_data)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Remove the AudioCue from the A singleton
	PopochiuResources.remove_audio_autoload(
		cue_group, name, audio_cue.resource_path
	)
	
	# Add the audio file to the "Not assigned" group
	deleted.emit(audio_cue.audio.resource_path)
	
	if _delete_all_checkbox.pressed:
		_delete_from_file_system(audio_cue.resource_path)
	else:
		queue_free()


func _delete_from_file_system(path: String) -> void:
	# Delete the AudioCue .tres file from the file system
	var err: int = main_dock.dir.remove_at(path)
	main_dock.fs.update_file(path)
	
	if err != OK:
		push_error('[Popochiu(err_code:%d)] Could not delete file %s' %\
		[err, path])
		return
	
	_disconnect_popup()
	queue_free()


# Disconnect from delete popup
func _disconnect_popup() -> void:
	if _confirmation_dialog.confirmed.is_connected(_remove_in_audio_manager):
		_confirmation_dialog.confirmed.disconnect(_remove_in_audio_manager)
	
	if _confirmation_dialog.confirmed.is_connected(_delete_from_file_system):
		# File deletion cancelled
		_confirmation_dialog.confirmed.disconnect(_delete_from_file_system)


func _set_main_dock(value: Panel) -> void:
	main_dock = value
	_confirmation_dialog = main_dock.delete_dialog
	_delete_all_checkbox = _confirmation_dialog.find_child('CheckBox')
