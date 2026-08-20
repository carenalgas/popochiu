@tool
extends PopochiuTreeDock
# Handles the Audio tab in Popochiu's dock. Uses a native [Tree] control to display audio cues and
# unassigned audio files grouped by type.
#
# Ref: #558

const SEARCH_PATH = "res://game/"
const AUDIO_FILE_EXTENSIONS = ["ogg", "mp3", "wav", "opus"]
const AudioCueSound = preload("res://addons/popochiu/engine/audio_manager/audio_cue_sound.gd")
const AudioCueMusic = preload("res://addons/popochiu/engine/audio_manager/audio_cue_music.gd")

const DELETE_AUDIO_CUE_MSG = "This will remove the [b]%s[/b] resource. Calls to this audio in \
scripts will not work anymore. This action cannot be reversed. Continue?"
const DELETE_AUDIO_CUE_ASK = "Delete [b]%s[/b] file too? (cannot be reversed)"
const DELETE_AUDIO_FILE_MSG = "[b]%s[/b] will be deleted in the file system. This action cannot be \
reversed. Continue?"

enum Buttons {
	PLAY,
	STOP,
}

enum MenuOptions {
	SEPARATOR = -1,
	DELETE,
	ADD_TO_MUSIC,
	ADD_TO_SFX,
	ADD_TO_VOICE,
	ADD_TO_UI,
}

var last_played: TreeItem = null

# Uses the path to an audio file as the key, and the TreeItem created for the PopochiuAudioCue
# linked to that audio file as the value.
var _audio_files_in_group := {}
# Uses the path to an audio file as the key, and the TreeItem created for that file as the value.
var _audio_files_to_assign := {}
var _audio_cues_to_create := []
var _created_audio_cues := 0
var _wavs_to_reimport := []

@onready var _asp: AudioStreamPlayer = $AudioStreamPlayer
@onready var _btn_scan_files: Button = %BtnScanAudioFiles

var _unassigned_group: TreeItem

var _groups := {
	PopochiuResources.AudioTypes.MUSIC: {
		array = "mx_cues",
		group = null,
		icon = preload("res://addons/popochiu/icons/music.png"),
		title = "Music",
	},
	PopochiuResources.AudioTypes.SOUND_EFFECT: {
		array = "sfx_cues",
		group = null,
		icon = preload("res://addons/popochiu/icons/sfx.png"),
		title = "Sound effects",
	},
	PopochiuResources.AudioTypes.VOICE: {
		array = "vo_cues",
		group = null,
		icon = preload("res://addons/popochiu/icons/voice.png"),
		title = "Voices",
	},
	PopochiuResources.AudioTypes.UI: {
		array = "ui_cues",
		group = null,
		icon = preload("res://addons/popochiu/icons/ui.png"),
		title = "Graphic interface",
	},
}


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Create the Unassigned group (no icon, no create button)
	_unassigned_group = create_group("Unassigned", null, false, "", { "type": -1 })
	
	# Create the groups for each audio type
	for type_key: int in _groups:
		var t: Dictionary = _groups[type_key]
		t.group = create_group(t.title, t.icon, false, "", { "type": type_key })
	
	# Connect to the base class signals
	item_clicked.connect(_on_item_clicked)
	button_clicked.connect(_on_item_button_clicked)
	menu_item_selected.connect(_on_menu_item_selected)
	
	# Setup the scan button
	_btn_scan_files.icon = get_theme_icon("Search", "EditorIcons")
	_btn_scan_files.pressed.connect(search_audio_files)
	
	# Connect to helpers' signals
	PopochiuEditorHelper.signal_bus.audio_cues_deleted.connect(delete_rows)


#endregion

#region Public #####################################################################################
func fill_data() -> void:
	# Connect to Editor signals
	EditorInterface.get_resource_filesystem().sources_changed.connect(_on_sources_changed)
	
	# Look for audio files without AudioCue
	_put_audio_cues_in_group()
	search_audio_files()


func search_audio_files() -> void:
	var fs_directory: EditorFileSystemDirectory = \
		EditorInterface.get_resource_filesystem().get_filesystem_path(SEARCH_PATH)
	
	if not fs_directory:
		return
	
	_read_directory(fs_directory)
	
	if _audio_cues_to_create.is_empty():
		return
	
	var progress_dialog := await PopochiuEditorHelper.show_progress()
	progress_dialog.label.text = "Creating PopochiuAudioCues..."
	progress_dialog.progress_bar.max_value = _audio_cues_to_create.size()
	
	EditorInterface.get_resource_filesystem().sources_changed.disconnect(_on_sources_changed)
	_created_audio_cues = 0
	for arr in _audio_cues_to_create:
		await _create_audio_cue(arr[0], arr[1])
		
		progress_dialog.progress_bar.value = _created_audio_cues
	
	_put_audio_cues_in_group()
	_audio_cues_to_create.clear()
	
	EditorInterface.get_resource_filesystem().sources_changed.connect(_on_sources_changed)
	progress_dialog.close()
	
	# Reimport WAV files so they can be changed to LOOP without the need to manually reimport them
	if not _wavs_to_reimport.is_empty():
		await PopochiuEditorHelper.secs_passed(0.1)
		
		_reimport_wavs()


func delete_rows(filepaths: Array) -> void:
	for filepath in filepaths:
		if filepath in _audio_files_to_assign:
			remove_item(_audio_files_to_assign[filepath])
			_audio_files_to_assign.erase(filepath)
		elif filepath in _audio_files_in_group:
			remove_item(_audio_files_in_group[filepath])
			_audio_files_in_group.erase(filepath)


#endregion

#region Private ####################################################################################
func _on_sources_changed(exist: bool) -> void:
	# Look popochiu_data.cfg for PopochiuAudioCue files that don't exist in the project anymore
	await _delete_rows_without_audio_cue()
	search_audio_files()


func _delete_rows_without_audio_cue() -> void:
	for key: int in _groups:
		var group: String = _groups[key].array
		var group_data: Array = PopochiuResources.get_data_value("audio", group, [])
		
		if group_data.is_empty():
			continue
		
		group_data = group_data.filter(
			func (resource_path: String) -> bool:
				if FileAccess.file_exists(resource_path):
					return true
				
				var audio_cue_name: String = resource_path.get_file().get_basename()
				var group_item: TreeItem = _groups[key].group
				
				var item := get_item(group_item, audio_cue_name)
				if item:
					remove_item(item)
				
				# Fix #59 : remove the AudioCue from the A singleton
				PopochiuResources.remove_audio_autoload(group, audio_cue_name, resource_path)
				return false
		)
		
		if group_data.is_empty():
			PopochiuResources.erase_data_value("audio", group)
		else:
			group_data.sort_custom(
				func (a: String, b: String) -> bool:
					return PopochiuUtils.sort_by_file_name(a, b)
			)
			PopochiuResources.set_data_value("audio", group, group_data)
	
	await get_tree().process_frame
	
	# Remove freed objects in _audio_files_in_group
	var to_erase := []
	for key: String in _audio_files_in_group:
		if not _audio_files_in_group[key] or not is_instance_valid(_audio_files_in_group[key]):
			to_erase.append(key)
	
	for key in to_erase:
		_audio_files_in_group.erase(key)


func _put_audio_cues_in_group() -> void:
	# Put already loaded (in popochiu_data.cfg) PopochiuAudioCues into their corresponding group
	for key: int in _groups:
		var group_dic: Dictionary = _groups[key]
		var group_data: Array = PopochiuResources.get_data_value("audio", group_dic.array, [])
		
		if group_data.is_empty(): continue
		
		for resource_path: String in group_data:
			var ac: AudioCue = load(resource_path)
			
			if (
				ac.audio.resource_path in _audio_files_in_group
				and is_instance_valid(_audio_files_in_group[ac.audio.resource_path])
			):
				# TODO: Check if the resource_path has changed
				continue
			
			var item := _create_audio_cue_item(ac, group_dic.group)
			item.get_metadata(COL_TEXT).cue_group = group_dic.array
			
			_audio_files_in_group[ac.audio.resource_path] = item


func _create_audio_cue_item(audio_cue: AudioCue, group: TreeItem) -> TreeItem:
	var data := {
		"is_cue": true,
		"path": audio_cue.resource_path,
		"audio_cue": audio_cue,
		"cue_group": "",
	}
	var item := add_item(group, audio_cue.resource_name, null, data, true)
	
	# Add the action buttons
	add_button(item, get_theme_icon("MainPlay", "EditorIcons"), Buttons.PLAY, "Play")
	add_button(item, get_theme_icon("Stop", "EditorIcons"), Buttons.STOP, "Stop")
	add_menu_button(item)
	
	return item


func _create_audio_file_item(file_path: String) -> TreeItem:
	var data := {
		"is_cue": false,
		"path": file_path,
		"file_name": file_path.get_file(),
	}
	var item := add_item(_unassigned_group, file_path.get_file().get_basename(), null, data, true)
	
	# Add the action buttons
	add_button(item, get_theme_icon("MainPlay", "EditorIcons"), Buttons.PLAY, "Play")
	add_button(item, get_theme_icon("Stop", "EditorIcons"), Buttons.STOP, "Stop")
	add_menu_button(item)
	
	_audio_files_to_assign[file_path] = item
	return item


func _read_directory(dir: EditorFileSystemDirectory) -> void:
	if not dir: return
	
	if dir.get_subdir_count():
		for d in dir.get_subdir_count():
			# Look out sub directories
			_read_directory(dir.get_subdir(d))
		
		# Look out the directory files
		_read_files(dir)
	else:
		_read_files(dir)


func _read_files(dir: EditorFileSystemDirectory) -> void:
	for idx in dir.get_file_count():
		var file_name = dir.get_file(idx)
		
		if not file_name.get_extension() in AUDIO_FILE_EXTENSIONS:
			continue
		
		if dir.get_file_path(idx) in _audio_files_in_group \
		or dir.get_file_path(idx) in _audio_files_to_assign:
			# Don't put in the list an audio file already assigned to a PopochiuAudioCue in
			# popochiu_data.cfg
			continue
		
		# Check if the file prefix matches any of the prefixes defined to automatically assign it to
		# a group
		var target := _get_audio_type_for_file(dir.get_file_path(idx))
		
		if target != PopochiuResources.AudioTypes.NONE:
			_audio_cues_to_create.append([target, dir.get_file_path(idx)])
		else:
			# Put the file in the Unassigned group so devs can manually choose the group to which
			# the audio file should be assigned
			_create_audio_file_item(dir.get_file_path(idx))


## Returns the [enum PopochiuResources.AudioTypes] that matches the file's prefix, or
## [constant PopochiuResources.AudioTypes.NONE] if no prefix matches.
func _get_audio_type_for_file(file_path: String) -> int:
	var file_name := file_path.get_file()
	var prefix := file_name.get_slice(PopochiuConfig.get_prefix_character(), 0)
	
	if prefix in PopochiuConfig.get_music_prefixes():
		return PopochiuResources.AudioTypes.MUSIC
	elif prefix in PopochiuConfig.get_sound_effect_prefixes():
		return PopochiuResources.AudioTypes.SOUND_EFFECT
	elif prefix in PopochiuConfig.get_voice_prefixes():
		return PopochiuResources.AudioTypes.VOICE
	elif prefix in PopochiuConfig.get_ui_prefixes():
		return PopochiuResources.AudioTypes.UI
	
	return PopochiuResources.AudioTypes.NONE


func _create_audio_cue(type: int, path: String, audio_item: TreeItem = null) -> void:
	# Check if the audio file is a WAV file so its LoopMode is set properly
	var stream: AudioStream = load(path)
	if stream is AudioStreamWAV:
		_wavs_to_reimport.append({
			stream = stream,
			type = type
		})
	
	var cue_name := path.get_file().get_basename()
	var cue_file_name := cue_name
	cue_file_name += ".tres"
	
	# Create the AudioCue and save it in the file system
	var ac: AudioCue
	match type:
		PopochiuResources.AudioTypes.MUSIC:
			ac = AudioCueMusic.new()
			ac.loop = true
		_:
			ac = AudioCueSound.new()
	
	ac.audio = stream
	ac.resource_name = cue_name.to_lower()
	
	var error: int = ResourceSaver.save(ac, "%s/%s" % [path.get_base_dir(), cue_file_name])
	assert(error == OK, "[Popochiu] Couldn't create PopochiuAudioCue: %s" % cue_file_name)
	
	var res: AudioCue = load("%s/%s" % [path.get_base_dir(), cue_file_name])
	var target := ""
	
	match type:
		PopochiuResources.AudioTypes.MUSIC:
			target = "mx_cues"
		PopochiuResources.AudioTypes.SOUND_EFFECT:
			target = "sfx_cues"
		PopochiuResources.AudioTypes.VOICE:
			target = "vo_cues"
		PopochiuResources.AudioTypes.UI:
			target = "ui_cues"
	
	var target_data: Array = PopochiuResources.get_data_value("audio", target, [])
	
	if not target_data.has(res.resource_path):
		target_data.append(res.resource_path)
		target_data.sort_custom(
			func (a: String, b: String) -> bool:
				return PopochiuUtils.sort_by_file_name(a, b)
		)
		PopochiuResources.set_data_value("audio", target, target_data)
	else:
		await PopochiuEditorHelper.frame_processed()
		return
	
	await PopochiuEditorHelper.secs_passed(0.1)
	
	# Add the AudioCue to the A singleton
	PopochiuResources.update_autoloads(true)
	
	# Check if the AudioCue was created when assigning the audio file from the "Not assigned" group
	if is_instance_valid(audio_item):
		# Delete the file item
		_audio_files_to_assign.erase(path)
		remove_item(audio_item)
		
		# Put the item in its corresponding group
		_put_audio_cues_in_group()
	else:
		_created_audio_cues += 1


func _on_item_clicked(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	if data.get("is_cue", false):
		EditorInterface.edit_resource(data.audio_cue)


func _on_item_button_clicked(item: TreeItem, id: int) -> void:
	match id:
		Buttons.PLAY:
			_play(item)
		Buttons.STOP:
			_stop(item)


func _on_menu_item_selected(item: TreeItem, id: int) -> void:
	match id:
		MenuOptions.DELETE:
			_remove_audio(item)
		MenuOptions.ADD_TO_MUSIC:
			_create_audio_cue(PopochiuResources.AudioTypes.MUSIC, item.get_metadata(COL_TEXT).path, item)
		MenuOptions.ADD_TO_SFX:
			_create_audio_cue(PopochiuResources.AudioTypes.SOUND_EFFECT, item.get_metadata(COL_TEXT).path, item)
		MenuOptions.ADD_TO_VOICE:
			_create_audio_cue(PopochiuResources.AudioTypes.VOICE, item.get_metadata(COL_TEXT).path, item)
		MenuOptions.ADD_TO_UI:
			_create_audio_cue(PopochiuResources.AudioTypes.UI, item.get_metadata(COL_TEXT).path, item)


func _get_menu_cfg(item: TreeItem) -> Array:
	var data := item.get_metadata(COL_TEXT)
	var cfg := []
	
	if not data.get("is_cue", false):
		cfg.append({
			id = MenuOptions.ADD_TO_MUSIC,
			icon = preload("res://addons/popochiu/icons/music.png"),
			label = "Add to Music",
		})
		cfg.append({
			id = MenuOptions.ADD_TO_SFX,
			icon = preload("res://addons/popochiu/icons/sfx.png"),
			label = "Add to Sound Effects",
		})
		cfg.append({
			id = MenuOptions.ADD_TO_VOICE,
			icon = preload("res://addons/popochiu/icons/voice.png"),
			label = "Add to Voices",
		})
		cfg.append({
			id = MenuOptions.ADD_TO_UI,
			icon = preload("res://addons/popochiu/icons/ui.png"),
			label = "Add to Graphic Interface",
		})
		cfg.append(MenuOptions.SEPARATOR)
	
	cfg.append({
		id = MenuOptions.DELETE,
		icon = get_theme_icon("Remove", "EditorIcons"),
		label = "Remove",
	})
	
	return cfg


func _play(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	if data.get("is_playing", false):
		# Pause the audio stream
		_set_playing(item, false)
		return
	
	if is_instance_valid(last_played) and last_played != item:
		# Stop the currently playing item (which is different from this one)
		_stop(last_played)
	
	if not data.get("is_cue", false):
		# If the item does not have a PopochiuAudioCue assigned, then it is the item of an audio
		# file. Therefore, the AudioStream to play will be its own path
		var stream: AudioStream = load(data.path)
		stream.loop = false
		_asp.stream = stream
	else:
		# Otherwise, the AudioStream to play will be that of the audio file associated with this
		# PopochiuAudioCue.audio
		_asp.stream = data.audio_cue.audio
		_asp.pitch_scale = data.audio_cue.get_pitch_scale()
		_asp.volume_db = data.audio_cue.volume
	
	_set_playing(item, true)


func _set_playing(item: TreeItem, value: bool) -> void:
	var data := item.get_metadata(COL_TEXT)
	data.is_playing = value
	
	if value:
		if not _asp.finished.is_connected(_on_stream_finished):
			_asp.finished.connect(_on_stream_finished)
		_asp.play(data.get("playback_position", 0.0))
		last_played = item
	else:
		data.playback_position = _asp.get_playback_position()
		
		if _asp.playing:
			_asp.stop()
			if _asp.finished.is_connected(_on_stream_finished):
				_asp.finished.disconnect(_on_stream_finished)
	
	set_button_icon(item, Buttons.PLAY, get_theme_icon("Pause" if value else "MainPlay", "EditorIcons"))


func _stop(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	data.is_playing = false
	data.playback_position = 0.0
	_asp.stream = null
	last_played = null
	set_button_icon(item, Buttons.PLAY, get_theme_icon("MainPlay", "EditorIcons"))
	
	if _asp.playing:
		_asp.stop()
		if _asp.finished.is_connected(_on_stream_finished):
			_asp.finished.disconnect(_on_stream_finished)


func _on_stream_finished() -> void:
	if is_instance_valid(last_played):
		_stop(last_played)


func _remove_audio(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	delete_dialog = PopochiuEditorHelper.DELETE_CONFIRMATION_SCENE.instantiate()
	
	if data.get("is_cue", false):
		delete_dialog.title = "Remove %s cue" % data.audio_cue.resource_name
		delete_dialog.message = DELETE_AUDIO_CUE_MSG % data.audio_cue.resource_name
		delete_dialog.ask = DELETE_AUDIO_CUE_ASK % data.audio_cue.audio.resource_path
		delete_dialog.on_confirmed = _remove_from_popochiu.bind(item)
	else:
		delete_dialog.title = "Delete %s" % data.file_name
		delete_dialog.message = DELETE_AUDIO_FILE_MSG % data.path
		delete_dialog.on_confirmed = _delete_audio_file.bind(item)
	
	PopochiuEditorHelper.show_delete_confirmation(delete_dialog)


func _remove_from_popochiu(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	var audio_cue: AudioCue = data.audio_cue
	var cue_group: String = data.cue_group
	
	# Remove the AudioCue from popochiu_data.cfg
	var group_data: Array = PopochiuResources.get_data_value("audio", cue_group, [])
	if group_data:
		group_data.erase(audio_cue.resource_path)
		
		if group_data.is_empty():
			PopochiuResources.erase_data_value("audio", cue_group)
		else:
			group_data.sort_custom(
				func (a: String, b: String) -> bool:
					return PopochiuUtils.sort_by_file_name(a, b)
			)
			PopochiuResources.set_data_value("audio", cue_group, group_data)
	
	# Remove the AudioCue from the A singleton
	PopochiuResources.remove_audio_autoload(cue_group, item.get_text(COL_TEXT), audio_cue.resource_path)
	
	# Delete the file in its corresponding group in Audio tab
	_audio_files_in_group.erase(audio_cue.audio.resource_path)
	
	if delete_dialog.check_box.button_pressed:
		_delete_audio_cue_files(item)
	else:
		remove_item(item)
		# The audio file still exists but has no cue. Re-create its cue in the group matching its
		# prefix (e.g. sfx_ -> Sound effects), or put it in Unassigned if it has no recognized
		# prefix. This mirrors what a project rescan would do.
		var target := _get_audio_type_for_file(audio_cue.audio.resource_path)
		if target != PopochiuResources.AudioTypes.NONE:
			_create_audio_cue(target, audio_cue.audio.resource_path)
		else:
			_create_audio_file_item(audio_cue.audio.resource_path)


func _delete_audio_cue_files(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	var audio_cue: AudioCue = data.audio_cue
	var path: String = data.path
	
	# Delete the .tres file from the file system
	var err: int = DirAccess.remove_absolute(path)
	if err != OK:
		PopochiuUtils.print_error("Couldn't delete audio cue %s (err_code: %d)" % [path, err])
		return
	
	# Delete the audio file linked to the cue
	var audio_file_path := audio_cue.audio.resource_path
	err = DirAccess.remove_absolute(audio_file_path)
	if err != OK:
		PopochiuUtils.print_error(
			"Couldn't delete audio file %s (err_code: %d)" % [audio_file_path, err]
		)
		return
	
	# Do this so Godot removes the .import file of the audio file
	EditorInterface.get_resource_filesystem().update_file(audio_file_path)
	EditorInterface.get_resource_filesystem().scan()
	EditorInterface.get_resource_filesystem().scan_sources()
	remove_item(item)


func _delete_audio_file(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	var path: String = data.path
	
	# Delete the audio file from the file system
	var err: int = DirAccess.remove_absolute(path)
	if err != OK:
		PopochiuUtils.print_error("Couldn't delete audio file %s (err_code: %d)" % [path, err])
		return
	
	# Do this so Godot removes the .import file of the audio file
	EditorInterface.get_resource_filesystem().update_file(path)
	EditorInterface.get_resource_filesystem().scan()
	EditorInterface.get_resource_filesystem().scan_sources()
	remove_item(item)


## Reimport WAV files so they can be changed to LOOP without the need to manually reimport them.
func _reimport_wavs() -> void:
	var streams_to_reimport := _wavs_to_reimport.filter(
		func (stream_dic: Dictionary):
			return _change_wav_loop_mode(stream_dic.stream)
	)
	
	EditorInterface.get_resource_filesystem().reimport_files(PackedStringArray(
		streams_to_reimport.map(
			func (stream_dic: Dictionary) -> String:
				return stream_dic.stream.resource_path
	)))
	await PopochiuEditorHelper.filesystem_scanned()
	
	for stream_dic: Dictionary in streams_to_reimport:
		var stream: AudioStreamWAV = stream_dic.stream
		var type: PopochiuResources.AudioTypes = stream_dic.type
		stream.loop_mode = (
			AudioStreamWAV.LOOP_FORWARD if type == PopochiuResources.AudioTypes.MUSIC
			else AudioStreamWAV.LOOP_DISABLED
		)
	
	_wavs_to_reimport.clear()


func _change_wav_loop_mode(audio_stream: AudioStreamWAV) -> bool:
	var import_path := audio_stream.resource_path + ".import"
	
	if not FileAccess.file_exists(import_path):
		PopochiuUtils.print_warning(
			"[b]%s[/b]" % audio_stream.resource_name \
			+ " does not have the correct metadata to loop, please reimport the file" \
			+ " by setting its Loop Mode to Forward."
		)
		return false
	
	var config := ConfigFile.new()
	var err := config.load(import_path)
	if err != OK:
		PopochiuUtils.print_error("Couldn't open %s to change its Loop mode." % audio_stream)
		return false
	
	if config.get_value("params", "edit/loop_mode", 0) != 0:
		return false
	
	config.set_value("params", "edit/loop_mode", 1 + AudioStreamWAV.LOOP_FORWARD)
	config.save(import_path)
	return true


#endregion