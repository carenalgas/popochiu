tool
extends VBoxContainer
# Handles the Audio tab in Popochiu's dock
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

const SEARCH_PATH := 'res://popochiu/'
const AudioCue := preload('res://addons/Popochiu/Engine/AudioManager/AudioCue.gd')

var main_dock: Panel setget _set_main_dock
var last_played: Control = null
var last_selected: Control = null

var _audio_row := preload(\
'res://addons/Popochiu/Editor/MainDock/AudioRow/PopochiuAudioRow.tscn')
# Array with all the paths to files that are already assigned to a category
# in PopochiuData.cfg
var _audio_files_in_group := []
var _audio_files_to_assign := []
var _audio_cues_to_create := []
var _created_audio_cues := 0

onready var _unassigned_group: PopochiuGroup = find_node('UnassignedGroup')
onready var _groups := {
	mx = {
		array = 'mx_cues',
		group = find_node('MusicGroup')
	},
	sfx = {
		array = 'sfx_cues',
		group = find_node('SFXGroup')
	},
	vo = {
		array = 'vo_cues',
		group = find_node('VoiceGroup')
	},
	ui = {
		array = 'ui_cues',
		group = find_node('UIGroup')
	}
}
onready var _asp: AudioStreamPlayer = find_node('AudioStreamPlayer')
onready var _btn_search_files: Button = find_node('BtnSearchAudioFiles')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	_btn_search_files.icon = get_icon('Search', 'EditorIcons')
	_btn_search_files.connect('pressed', self, 'search_audio_files')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func fill_data() -> void:
	# Look for audio files without AudioCue
	search_audio_files()


func search_audio_files() -> void:
	# Look PopochiuData.cfg to remove entries for AudioCue files that don't
	# exists in the project anymore
	_group_audio_cues()
	_read_directory(main_dock.fs.get_filesystem_path(SEARCH_PATH))
	
	if not _audio_cues_to_create.empty():
		_created_audio_cues = 0
		var progress: ProgressBar = main_dock.loading_dialog.find_node('Progress')
		
		progress.max_value = _audio_cues_to_create.size()
		(main_dock.loading_dialog as Popup).set_as_minsize()
		(main_dock.loading_dialog as Popup).popup_centered()
		
		yield(get_tree(), 'idle_frame')
		
		for arr in _audio_cues_to_create:
			yield(_create_audio_cue(arr[0], arr[1]), 'completed')
			progress.value = _created_audio_cues
			yield(get_tree(), 'idle_frame')
		
		_group_audio_cues()
		_audio_cues_to_create.clear()
		
		(main_dock.loading_dialog as Popup).hide()


func delete_rows(filepaths: Array) -> void:
	for filepath in filepaths:
		if filepath in _audio_files_to_assign:
			for row in _unassigned_group.get_elements():
				if row.file_path == filepath:
					row.queue_free()
					break
			_audio_files_to_assign.erase(filepath)
		elif filepath in _audio_files_in_group:
			var deleted := false
			
			for group_dic in _groups.values():
				for row in group_dic.group.get_elements():
					if row.audio_cue.audio.resource_path == filepath:
						row.queue_free()
						deleted = true
						break
				if deleted:
					_audio_files_in_group.erase(filepath)
					break


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _group_audio_cues() -> void:
	var entries_to_delete := {}
	
	# Put already loaded (in PopochiuData.cfg) AudioCues into their corresponding
	# group
	for d in _groups:
		var group: Dictionary = _groups[d]
		var group_data: Array = PopochiuResources.get_data_value(
			'audio', group.array, []
		)
		entries_to_delete[d] = []
		
		if not group_data: continue
		
		for rp in group_data:
			if not (main_dock.dir as Directory).file_exists(rp):
				entries_to_delete[d].append(rp)
				continue
			
			var ac: AudioCue = load(rp)
			
			if ac.audio.resource_path in _audio_files_in_group:
				# TODO: Check if the resource_path has changed
				continue
			
			var ar := _create_audio_cue_row(ac)
			ar.cue_group = group.array
			group.group.add(ar)
			
			_audio_files_in_group.append(ac.audio.resource_path)
	
	for dic in entries_to_delete:
		if entries_to_delete[dic].empty(): continue
		
		var group: String = _groups[dic].array
		var paths: Array = PopochiuResources.get_data_value('audio', group, [])
		
		for rp in entries_to_delete[dic]:
			(_groups[dic].group as PopochiuGroup).remove_by_name(
				rp.get_file().get_basename()\
				.capitalize().to_lower().replace(' ', '_')
			)
			
			paths.erase(rp)
		
		if paths.empty():
			PopochiuResources.erase_data_value('audio', group)
		else:
			PopochiuResources.set_data_value('audio', group, paths)


func _create_audio_cue_row(audio_cue: AudioCue) -> HBoxContainer:
	var ar: HBoxContainer = _audio_row.instance()
	
	ar.audio_cue = audio_cue
	ar.main_dock = main_dock
	ar.audio_tab = self
	ar.stream_player = _asp
	
	ar.connect('deleted', self, '_audio_cue_deleted')
	
	return ar


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
		
		if not file_name.get_extension() in ['ogg', 'mp3', 'wav', 'opus']:
			continue
		
		if dir.get_file_path(idx) in _audio_files_in_group\
		or dir.get_file_path(idx) in _audio_files_to_assign:
			# Don't put in the list an audio file already assigned to an
			# AudioCue in PopochiuData.cfg
			continue
			
		# Check if the file prefix matches one of the defined for automatic
		# group assignation: mx_, sfx_, vo_, ui_
		# TODO: This could be read from a settings file so developers can
		# define their own prefixes.
		var target := ''
		if file_name.find('mx_') > -1:
			target = 'music'
		elif file_name.find('sfx_') > -1:
			target = 'sfx'
		elif file_name.find('vo_') > -1:
			target = 'voice'
		elif file_name.find('ui_') > -1:
			target = 'ui'
		
		if target:
			_audio_cues_to_create.append([target, dir.get_file_path(idx)])
		else:
			_create_audio_file_row(dir.get_file_path(idx))


func _create_audio_file_row(file_path: String) -> void:
	var ar: HBoxContainer = _audio_row.instance()
	
	ar.name = file_path.get_file().get_basename()
	ar.file_name = file_path.get_file()
	ar.file_path = file_path
	ar.main_dock = main_dock
	ar.audio_tab = self
	ar.stream_player = _asp
	
	ar.connect('target_clicked', self, '_create_audio_cue', [file_path, ar])
	
	_unassigned_group.add(ar)
	_audio_files_to_assign.append(file_path)


func _create_audio_cue(\
type: String, path: String, audio_row: Container = null
) -> void:
	var cue_name := path.get_file().get_basename()
	var cue_file_name := U.snake2pascal(cue_name)
	cue_file_name += '.tres'
	
	# Create the AudioCue and save it in the file system
	var ac: AudioCue = AudioCue.new()
	var stream: AudioStream = load(path)
	ac.audio = stream
	ac.resource_name = cue_name.to_lower()
	
	var error: int = ResourceSaver.save(
		'%s/%s' % [path.get_base_dir(), cue_file_name],
		ac
	)
	
	assert(error == OK, "[Popochiu] Can't save AudioCue: %s" % cue_file_name)
	
	var res: AudioCue = load('%s/%s' % [path.get_base_dir(), cue_file_name])
	var target := ''
	
	match type:
		'music':
			target = 'mx_cues'
		'sfx':
			target = 'sfx_cues'
		'voice':
			target = 'vo_cues'
		'ui':
			target = 'ui_cues'
	
	var target_data: Array = PopochiuResources.get_data_value(
		'audio', target, []
	)
	
	if not target_data.has(res.resource_path):
		target_data.append(res.resource_path)
		target_data.sort_custom(A, '_sort_resource_paths')
		PopochiuResources.set_data_value('audio', target, target_data)
	else:
		yield(get_tree(), 'idle_frame')
		return
	
	# ...
#	main_dock.fs.scan()
	yield(main_dock.fs, 'filesystem_changed')
	
	# Check if the AudioCue was created when assigning the audio file from the
	# "Not assigned" group
	if is_instance_valid(audio_row):
		# Delete the file row
		_audio_files_to_assign.erase(path)
		audio_row.queue_free()
	
		# Put the row in its corresponding group
#		yield(get_tree().create_timer(0.1), 'timeout')
		_group_audio_cues()
	else:
		_created_audio_cues += 1


func _audio_cue_deleted(file_path: String) -> void:
	_audio_files_in_group.erase(file_path)
	_create_audio_file_row(file_path)


func _set_main_dock(value: Panel) -> void:
	main_dock = value
