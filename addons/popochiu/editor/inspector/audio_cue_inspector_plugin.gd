extends EditorInspectorPlugin


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _can_handle(object: Object) -> bool:
	return object is PopochiuAudioCue


func _parse_property(
	object: Object,
	type,
	path: String,
	hint,
	hint_text: String,
	usage,
	wide: bool
) -> bool:
	if not object is PopochiuAudioCue or path != 'bus':
		return false

	var ep := EditorProperty.new()
	var ob := OptionButton.new()

	_update_buses_list(ob, object)

	ob.item_selected.connect(_update_audio_cue_bus.bind(object))
	ob.pressed.connect(_update_buses_list.bind(ob, object))

	ep.add_child(ob)
	add_property_editor(path, ep)

	return true


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_audio_cue_bus(idx: int, audio_cue: PopochiuAudioCue) -> void:
	audio_cue.bus = AudioServer.get_bus_name(idx)
	ResourceSaver.save(audio_cue, audio_cue.resource_path)


func _update_buses_list(ob: OptionButton, pac: PopochiuAudioCue) -> void:
	ob.clear()
	
	for idx in AudioServer.bus_count:
		ob.add_item(AudioServer.get_bus_name(idx), idx)
	
	ob.selected = AudioServer.get_bus_index(pac.bus)
