extends EditorInspectorPlugin


#region Virtual ####################################################################################
func _can_handle(object: Object) -> bool:
	if object is PopochiuCharacter:
		return true
	return false


func _parse_begin(object: Object) -> void:
	if object.get_class() == "EditorDebuggerRemoteObject":
		return
	
	if not object.get_parent() is Node2D: return
	
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	var button := Button.new()
	
	hbox.custom_minimum_size.y = 42.0
	button.text = "* Open Node' scene to edit its properties"
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	panel.add_theme_stylebox_override(
		"panel",
		panel.get_theme_stylebox("sub_inspector_bg11", "Editor")
	)
	button.add_theme_color_override("font_color", Color("c46c71"))
	button.add_theme_color_override("font_color_hover", Color("c46c71"))
	button.add_theme_color_override("font_color_pressed", Color("c46c71"))
	
	button.pressed.connect(
		_open_scene.bind((object as PopochiuCharacter).scene_file_path),
		CONNECT_DEFERRED
	)
	
	hbox.add_child(button)
	panel.add_child(hbox)
	
	add_custom_control(panel)


func _parse_property(
	object: Object,
	type,
	path: String,
	hint,
	hint_text: String,
	usage,
	wide: bool
) -> bool:
	if object.get_class() == "EditorDebuggerRemoteObject":
		return false
	
	# Add custom dropdown for follow_character and face_character properties
	if object is PopochiuCharacter and path in ["follow_character", "face_character"]:
		var ep := EditorProperty.new()
		var ob := OptionButton.new()
		
		_update_characters_list(ob, object, path)
		
		ob.item_selected.connect(_update_character_property.bind(ob, object, path))
		ob.pressed.connect(_update_characters_list.bind(ob, object, path))
		
		ep.add_child(ob)
		add_property_editor(path, ep)
		
		return true
	
	# NOTE: We could add this as an option of the plugin settings. So devs can add extra properties
	# 		if needed.
	if object and object.get_parent() is Node2D and not path in [
		"baseline",
		"walk_to_point",
		"look_at_point",
		"position",
		"visible",
		"modulate",
		"self_modulate",
		"light_mask",
	]:
		return true
	
	return false


#endregion

#region Private ####################################################################################
func _open_scene(path: String) -> void:
	EditorInterface.set_main_screen_editor("2D")
	EditorInterface.open_scene_from_path(path)


func _update_characters_list(ob: OptionButton, character: PopochiuCharacter, path: String) -> void:
	ob.clear()
	var characters := PopochiuResources.get_section_keys("characters")
	var keys_ids_map := {}
	
	characters.sort()
	ob.add_item("")
	for key: String in characters:
		# Exclude the character itself from the list
		if key == character.script_name:
			continue
		keys_ids_map[key] = ob.item_count
		ob.add_item(key)
	
	var current_value: String = character.get(path)
	if keys_ids_map.has(current_value):
		ob.selected = ob.get_item_index(keys_ids_map[current_value])


func _update_character_property(idx: int, ob: OptionButton, character: PopochiuCharacter, path: String) -> void:
	character.set(path, ob.get_item_text(idx))


#endregion
