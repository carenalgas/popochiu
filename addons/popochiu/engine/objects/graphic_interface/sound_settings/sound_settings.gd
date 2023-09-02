extends PanelContainer
@warning_ignore("return_value_discarded")

const SELECTION_COLOR := Color('edf171')
const OVERWRITE_COLOR := Color('c46c71')
const MASTER_BUS_INDEX = 0

var _current_slot: Button = null
var _date := ''
var _prev_text := ''
var _slot := 0

@onready var _cancel: Button = %Close
@onready var _channels_container: VBoxContainer = %ChannelsContainer
@onready var _sliders_container: VBoxContainer = %SlidersContainer

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	G.sound_settings_requested.connect(_show_sound_settings)
	_cancel.pressed.connect(_close)
	await E.am.ready
	E.am.load_sound_settings()

	# Build sound settings UI
	for bus_idx in range(AudioServer.get_bus_count()):
		var bus_name = AudioServer.get_bus_name(bus_idx)
		var label = Label.new()
		label.text = bus_name
		_channels_container.add_child(label)
		
		var slider = HSlider.new()
		slider.min_value = -70
		slider.max_value = 0
		slider.set_value(E.am.volume_settings[bus_name])
		slider.value_changed.connect(_update_volume.bind(bus_name))

		_sliders_container.add_child(slider)

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

func _update_volume(value: float, name: String) -> void:
	E.am.set_bus_volume_db(name, value)
	
func _close() -> void:
	E.am.save_sound_settings()
	G.done()
	Cursor.unlock()
	hide()

