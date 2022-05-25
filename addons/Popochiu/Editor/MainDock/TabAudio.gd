tool
extends VBoxContainer
# Handles the Audio tab in Popochiu's dock
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

const AUDIO_MANAGER_SCENE := 'res://addons/Popochiu/Engine/AudioManager/AudioManager.tscn'
#const CUES_PATH := 'res://popochiu/AudioManager/Cues'
const SEARCH_PATH := 'res://popochiu/'
const AudioCue := preload('res://addons/Popochiu/Engine/AudioManager/AudioCue.gd')

var main_dock: Panel setget _set_main_dock
var audio_manager: Node = null
var last_played: Control = null
var last_selected: Control = null

var _audio_row := preload(\
'res://addons/Popochiu/Editor/MainDock/AudioRow/PopochiuAudioRow.tscn')
# Array with all the paths to files that are already assigned to a category
# in AudioManager
var _audio_files_in_group := []
var _audio_files_to_assign := []
# To count the AudioCue created during audio files search. Used when there
# are files with the defined prefixes:  mx_, sfx_, vo_, ui_
var _created_audio_cues := 0

onready var _am_unassigned_group: PopochiuGroup = find_node('UnassignedGroup')
onready var _am_groups := {
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
onready var _am_search_files: Button = find_node('BtnSearchAudioFiles')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	audio_manager = load(AUDIO_MANAGER_SCENE).instance()
	_am_search_files.icon = get_icon('Search', 'EditorIcons')
	_am_search_files.connect('pressed', self, 'search_audio_files')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func fill_data() -> void:
	# Look for audio files without AudioCue
	search_audio_files()


func search_audio_files() -> void:
	_created_audio_cues = 0
	
	_read_audio_manager_cues()
	_read_directory(main_dock.fs.get_filesystem_path(SEARCH_PATH))
	
	if _created_audio_cues > 0:
		_read_audio_manager_cues()


func get_audio_manager() -> Node:
	audio_manager.free()
	audio_manager = load(AUDIO_MANAGER_SCENE).instance()
	return audio_manager


func save_audio_manager() -> int:
	var result := OK
	
	var new_audio_manager: PackedScene = PackedScene.new()
	new_audio_manager.pack(audio_manager)
	
	result = ResourceSaver.save(AUDIO_MANAGER_SCENE, new_audio_manager)
	
	assert(result == OK, "[Popochiu] Couldn't save the AudioManager")
	
	# Save changes in AudioManager.tscn
	main_dock.ei.reload_scene_from_path(AUDIO_MANAGER_SCENE)
	
	if main_dock.ei.get_edited_scene_root().name == 'AudioManager':
		main_dock.ei.save_scene()
	
	return result


func delete_rows(filepaths: Array) -> void:
	for filepath in filepaths:
		if filepath in _audio_files_to_assign:
			for row in _am_unassigned_group.get_elements():
				if row.file_path == filepath:
					row.queue_free()
					break
			_audio_files_to_assign.erase(filepath)
		elif filepath in _audio_files_in_group:
			var deleted := false
			
			for group_dic in _am_groups.values():
				for row in group_dic.group.get_elements():
					if row.audio_cue.audio.resource_path == filepath:
						row.queue_free()
						deleted = true
						break
				if deleted:
					_audio_files_in_group.erase(filepath)
					break


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _read_audio_manager_cues() -> void:
	# Put already loaded (in AudioManager) AudioCues into their corresponding
	# group
	for d in _am_groups:
		var group: Dictionary = _am_groups[d]
		
		if not audio_manager[group.array].empty():
			for m in audio_manager[group.array]:
				if (m as AudioCue).audio.resource_path in _audio_files_in_group:
					# TODO: Check if the resource_path has changed
					continue
				
				var ar := _create_audio_cue_row(m)
				ar.cue_group = group.array
				group.group.add(ar)
				
				_audio_files_in_group.append(
					(m as AudioCue).audio.resource_path
				)


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
		
		if file_name.get_extension() == "ogg" or \
		file_name.get_extension() == "mp3" or \
		file_name.get_extension() == "wav" or \
		file_name.get_extension() == "opus":
			if dir.get_file_path(idx) in _audio_files_in_group\
			or dir.get_file_path(idx) in _audio_files_to_assign:
				# Don't put in the list an audio file already assigned to an
				# AudioCue in AudioManager
				continue
			
			# Check if the file prefix matches one of the defined for automatic
			# group assignation: mx_, sfx_, vo_, ui_
			# TODO: This could be read from a settings file so developers can
			# define their own prefixes.
			if file_name.find('mx_') > -1:
				_create_audio_cue('music', dir.get_file_path(idx))
				_created_audio_cues += 1
			elif file_name.find('sfx_') > -1:
				_create_audio_cue('sfx', dir.get_file_path(idx))
				_created_audio_cues += 1
			elif file_name.find('vo_') > -1:
				_create_audio_cue('voice', dir.get_file_path(idx))
				_created_audio_cues += 1
			elif file_name.find('ui_') > -1:
				_create_audio_cue('ui', dir.get_file_path(idx))
				_created_audio_cues += 1
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
	
	_am_unassigned_group.add(ar)
	
	_audio_files_to_assign.append(file_path)


func _create_audio_cue(
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
#		'%s/%s' % [CUES_PATH, cue_file_name],
		'%s/%s' % [path.get_base_dir(), cue_file_name],
		ac
	)
	
	assert(error == OK, '[Popochiu] Can not save AudioCue: %s' % cue_file_name)
	
	# Put the created AudioCue into the corresponding Dictionary in the AudioManager
	audio_manager.free()
	audio_manager = load(AUDIO_MANAGER_SCENE).instance()
	
	var resource: AudioCue = load('%s/%s' % [path.get_base_dir(), cue_file_name])
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
	
	if audio_manager[target].empty():
		audio_manager[target] = [resource]
	else:
		audio_manager[target].append(resource)
	
	audio_manager[target].sort_custom(A, '_sort_cues')
	
	save_audio_manager()
	
	if is_instance_valid(audio_row):
		# Delete the file row
		_audio_files_to_assign.erase(path)
		audio_row.queue_free()
	
		# Put the row in its corresponding group
		yield(get_tree().create_timer(0.1), 'timeout')
		_read_audio_manager_cues()


func _audio_cue_deleted(file_path: String) -> void:
	_audio_files_in_group.erase(file_path)
	_create_audio_file_row(file_path)


func _set_main_dock(value: Panel) -> void:
	main_dock = value
