@tool
extends VBoxContainer
## Handles the Audio tab in Popochiu's dock.

const SEARCH_PATH = "res://game/"
const POPOCHIU_AUDIO_ROW_SCENE = preload(
	"res://addons/popochiu/editor/main_dock/popochiu_row/audio_row/popochiu_audio_row.tscn"
)
const AUDIO_FILE_EXTENSIONS = ["ogg", "mp3", "wav", "opus"]
const AudioCue = preload("res://addons/popochiu/engine/audio_manager/audio_cue.gd")
const AudioCueSound = preload("res://addons/popochiu/engine/audio_manager/audio_cue_sound.gd")
const AudioCueMusic = preload("res://addons/popochiu/engine/audio_manager/audio_cue_music.gd")
const PopochiuAudioRow = preload(
	"res://addons/popochiu/editor/main_dock/popochiu_row/audio_row/popochiu_audio_row.gd"
)

var last_played: Control = null
var last_selected: Control = null

# Uses the path to an audio file as the key, and the PopochiuAudioRow created for the
# PopochiuAudioCue linked to that audio file as the value.
var _audio_files_in_group := {}
# Uses the path to an audio file as the key, and the PopochiuAudioRow created for that file as the
# value.
var _audio_files_to_assign := {}
var _audio_cues_to_create := []
var _created_audio_cues := 0
var _wavs_to_reimport := []

@onready var _asp: AudioStreamPlayer = $AudioStreamPlayer
@onready var _btn_scan_files: Button = %BtnScanAudioFiles
@onready var unassigned_group: PopochiuGroup = %UnassignedGroup
@onready var _groups := {
	PopochiuResources.AudioTypes.MUSIC : {
		array = "mx_cues",
		group = %MusicGroup
	},
	PopochiuResources.AudioTypes.SOUND_EFFECT : {
		array = "sfx_cues",
		group = %SFXGroup
	},
	PopochiuResources.AudioTypes.VOICE : {
		array = "vo_cues",
		group = %VoiceGroup
	},
	PopochiuResources.AudioTypes.UI : {
		array = "ui_cues",
		group = %UIGroup
	}
}


#region Godot ######################################################################################
func _ready() -> void:
	$PopochiuFilter.groups = _groups
	_btn_scan_files.icon = get_theme_icon("Search", "EditorIcons")
	
	# Connect to children's signals
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
	var fs_directory: EditorFileSystemDirectory =\
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
			_audio_files_to_assign[filepath].free()
			_audio_files_to_assign.erase(filepath)
		elif filepath in _audio_files_in_group:
			_audio_files_in_group[filepath].free()
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
				var popochiu_group: PopochiuGroup = _groups[key].group
				
				popochiu_group.remove_by_name(audio_cue_name)
			
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
	# Put already loaded (in popochiu_data.cfg) PopochiuAudioCues into their corresponding
	# PopochiuGroup
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
			
			var ar := _create_audio_cue_row(ac)
			ar.cue_group = group_dic.array
			(group_dic.group as PopochiuGroup).add(ar, true)
			
			_audio_files_in_group[ac.audio.resource_path] = ar


func _create_audio_cue_row(audio_cue: AudioCue) -> HBoxContainer:
	var ar: HBoxContainer = POPOCHIU_AUDIO_ROW_SCENE.instantiate()
	
	ar.name = audio_cue.resource_name
	ar.path = audio_cue.resource_path
	ar.audio_cue = audio_cue
	ar.audio_tab = self
	ar.stream_player = _asp
	
	ar.deleted.connect(_audio_cue_deleted)
	ar.clicked.connect(_on_row_clicked)
	
	return ar


func _create_audio_file_row(file_path: String) -> void:
	var ar: HBoxContainer = POPOCHIU_AUDIO_ROW_SCENE.instantiate()
	
	ar.name = file_path.get_file().get_basename()
	ar.path = file_path
	ar.file_name = file_path.get_file()
	ar.audio_tab = self
	ar.stream_player = _asp
	
	ar.group_selected.connect(_create_audio_cue.bind(file_path, ar))
	ar.clicked.connect(_on_row_clicked)
	
	unassigned_group.add(ar, true)
	_audio_files_to_assign[file_path] = ar


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
		
		if dir.get_file_path(idx) in _audio_files_in_group\
		or dir.get_file_path(idx) in _audio_files_to_assign:
			# Don't put in the list an audio file already assigned to a PopochiuAudioCue in
			# popochiu_data.cfg
			continue
			
		# Check if the file prefix matches any of the prefixes defined to automatically assign it to
		# a group
		var target := PopochiuResources.AudioTypes.NONE
		var prefix := file_name.get_slice(PopochiuConfig.get_prefix_character(), 0)
		
		if prefix in PopochiuConfig.get_music_prefixes():
			target = PopochiuResources.AudioTypes.MUSIC
		elif prefix in PopochiuConfig.get_sound_effect_prefixes():
			target = PopochiuResources.AudioTypes.SOUND_EFFECT
		elif prefix in PopochiuConfig.get_voice_prefixes():
			target = PopochiuResources.AudioTypes.VOICE
		elif prefix in PopochiuConfig.get_ui_prefixes():
			target = PopochiuResources.AudioTypes.UI
		
		if target != PopochiuResources.AudioTypes.NONE:
			_audio_cues_to_create.append([target, dir.get_file_path(idx)])
		else:
			# Put the file in the Unassigned group so devs can manually choose the group to which
			# the audio file should be assigned
			_create_audio_file_row(dir.get_file_path(idx))


func _create_audio_cue(type: int, path: String, audio_row: Container = null) -> void:
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
	
	# Add the AudioCue to the A singleton ----------------------------------------------------------
	PopochiuResources.update_autoloads(true)
	
	# Check if the AudioCue was created when assigning the audio file from the "Not assigned" group
	if is_instance_valid(audio_row):
		# Delete the file row
		_audio_files_to_assign.erase(path)
		audio_row.queue_free()
	
		# Put the row in its corresponding group
		_put_audio_cues_in_group()
	else:
		_created_audio_cues += 1


func _audio_cue_deleted(file_path: String) -> void:
	_audio_files_in_group.erase(file_path)


func _on_row_clicked(row: HBoxContainer) -> void:
	if is_instance_valid(last_selected):
		last_selected.deselect()
	
	last_selected = row


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
