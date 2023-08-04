extends PanelContainer
@warning_ignore("return_value_discarded")

const SELECTION_COLOR := Color('edf171')
const OVERWRITE_COLOR := Color('c46c71')

var am: PopochiuAudioManager = null
var _current_slot: Button = null
var _date := ''
var _prev_text := ''
var _slot := 0

@onready var _cancel: Button = %Close
@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SFXSlider

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	G.sound_settings_requested.connect(_show_sound_settings)
	_cancel.pressed.connect(_close)
	
	_master_slider.value_changed.connect(_update_master_volume)
	_music_slider.value_changed.connect(_update_music_volume)
	_sfx_slider.value_changed.connect(_update_sfx_volume)

	am = load(PopochiuResources.AUDIO_MANAGER).instantiate()
	am.load_sound_settings()
	_master_slider.set_value(am.volume_settings["Master"])
	_music_slider.set_value(am.volume_settings["Music"])
	_sfx_slider.set_value(am.volume_settings["Effects"])
	hide()

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _show_sound_settings() -> void:
	_show()

func _show() -> void:
	if E.settings.scale_gui:
		scale = Vector2.ONE * E.scale

	G.blocked.emit({ blocking = false })
	Cursor.set_cursor(Cursor.Type.USE)
	Cursor.block()
	show()

func _update_master_volume(value: float) -> void:
	am.set_bus_volume_db("Master", value)
	
func _update_music_volume(value: float) -> void:
	am.set_bus_volume_db("Music", value)

func _update_sfx_volume(value: float) -> void:
	am.set_bus_volume_db("Effects", value)
	
func _close() -> void:
	am.save_sound_settings()
	G.done()
	Cursor.unlock()
	hide()

