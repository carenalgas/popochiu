extends EditorInspectorPlugin


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func can_handle(object: Object) -> bool:
	return object is PopochiuAudioCue


func parse_property(
	object: Object,
	type: int,
	path: String,
	hint: int,
	hint_text: String,
	usage: int
) -> bool:
	if not object is PopochiuAudioCue or path != 'bus':
		return false
	
	var ep := EditorProperty.new()
	var ob := OptionButton.new()
	
	_update_buses_list(ob, object)
	
	ob.connect('item_selected', self, '_update_audio_cue_bus', [object])
	ob.connect('pressed', self, '_update_buses_list', [ob, object])
	
	ep.add_child(ob)
	add_property_editor(path, ep)
	
	return true

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_audio_cue_bus(idx: int, audio_cue: PopochiuAudioCue) -> void:
	audio_cue.bus = AudioServer.get_bus_name(idx)
	ResourceSaver.save(audio_cue.resource_path, audio_cue)


func _update_buses_list(ob: OptionButton, pac: PopochiuAudioCue) -> void:
	ob.clear()
	
	for idx in AudioServer.bus_count:
		ob.add_item(AudioServer.get_bus_name(idx), idx)
	
	ob.selected = AudioServer.get_bus_index(pac.bus)
