extends GridContainer

const MIN_VOLUME := -30
const MUTE_VOLUME := -70

var dflt_volumes := {}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	# Connect to AudioManager ready signal
	E.am.ready.connect(_on_audio_manager_ready)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func update_sliders() -> void:
	for slider in $SlidersContainer.get_children():
		if not slider.has_meta("bus_name"): continue
		
		var bus_name: String = slider.get_meta("bus_name")
		
		slider.value = E.am.volume_settings[bus_name]
		dflt_volumes[bus_name] = slider.value


func restore_last_volumes() -> void:
	for slider in $SlidersContainer.get_children():
		if not slider.has_meta("bus_name"): continue
		
		var bus_name: String = slider.get_meta("bus_name")
		
		E.am.set_bus_volume_db(
			bus_name,
			dflt_volumes[bus_name]
		)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _on_audio_manager_ready() -> void:
	# TODO: Check if this is necessary. Loading volumes from a file should happen
	# 		only when loading a saved game
	E.am.load_sound_settings()
	
	# Build sound settings UI
	for bus_idx in range(AudioServer.get_bus_count()):
		var volume_row := VBoxContainer.new()
		
		var bus_name = AudioServer.get_bus_name(bus_idx)
		
		# Create the label for the slider
		var label = Label.new()
		label.text = bus_name
		
		$ChannelsContainer.add_child(label)
		
		# Create the node that will allow players to modify buses volumes
		var slider = HSlider.new()
		slider.min_value = MIN_VOLUME
		slider.max_value = 0
		slider.value = E.am.volume_settings[bus_name]
		slider.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.x = 120.0
		slider.set_meta("bus_name", bus_name)
		
		$SlidersContainer.add_child(slider)
		
		slider.value_changed.connect((
			func (value: float, bus_name: String):
				E.am.set_bus_volume_db(
					bus_name,
					value if value > MIN_VOLUME else MUTE_VOLUME
				)
		).bind(bus_name))
