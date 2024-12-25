@tool
extends "res://addons/popochiu/editor/main_dock/popochiu_row/popochiu_row.gd"

signal group_selected(type: int)
signal deleted(file_path: String)

enum AudioOptions {
	DELETE = MenuOptions.DELETE,
	ADD_TO_MUSIC,
	ADD_TO_SFX,
	ADD_TO_VOICE,
	ADD_TO_UI
}

const DELETE_AUDIO_CUE_MSG = "This will remove the [b]%s[/b] resource. Calls to this audio in \
scripts will not work anymore. This action cannot be reversed. Continue?"
const DELETE_AUDIO_CUE_ASK = "Delete [b]%s[/b] file too? (cannot be reversed)"
const DELETE_AUDIO_FILE_MSG = "[b]%s[/b] will be deleted in the file system. This action cannot be \
reversed. Continue?"

# Only used by rows that represent an audio file
var file_name: String
var audio_cue: AudioCue
var cue_group: String
var stream_player: AudioStreamPlayer
var audio_tab: VBoxContainer = null
var is_playing := false :
	set = set_is_playing
var current_playback_position := 0.0

@onready var play_btn: Button = %Play
@onready var stop_btn: Button = %Stop


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Assign icons
	play_btn.icon = get_theme_icon("MainPlay", "EditorIcons")
	stop_btn.icon = get_theme_icon("Stop", "EditorIcons")
	
	# Connect to children's signals
	play_btn.pressed.connect(play)
	stop_btn.pressed.connect(stop)
	
	# Remove group options if this is a PopochiuAudioCue
	if is_instance_valid(audio_cue):
		menu_popup.remove_item(menu_popup.get_item_index(AudioOptions.ADD_TO_MUSIC))
		menu_popup.remove_item(menu_popup.get_item_index(AudioOptions.ADD_TO_SFX))
		menu_popup.remove_item(menu_popup.get_item_index(AudioOptions.ADD_TO_VOICE))
		menu_popup.remove_item(menu_popup.get_item_index(AudioOptions.ADD_TO_UI))
	else:
		label.text = file_name


#endregion

#region Virtual ####################################################################################
func _remove_object() -> void:
	_delete_dialog = PopochiuEditorHelper.DELETE_CONFIRMATION_SCENE.instantiate()
	
	if is_instance_valid(audio_cue):
		_delete_dialog.title = "Remove %s cue" % audio_cue.resource_name
		_delete_dialog.message = DELETE_AUDIO_CUE_MSG % audio_cue.resource_name
		_delete_dialog.ask = DELETE_AUDIO_CUE_ASK % audio_cue.audio.resource_path
		_delete_dialog.on_confirmed = _remove_from_popochiu
	else:
		_delete_dialog.title = "Delete %s" % file_name
		_delete_dialog.message = DELETE_AUDIO_FILE_MSG % path
		_delete_dialog.on_confirmed = _delete_from_file_system
	
	PopochiuEditorHelper.show_delete_confirmation(_delete_dialog)


#endregion

#region Public #####################################################################################
func select() -> void:
	EditorInterface.edit_resource(audio_cue)
	super()


func play() -> void:
	if is_playing:
		# Pause the audio stream
		is_playing = false
		return
	
	if is_instance_valid(audio_tab.last_played):
		# Stop the currently playing row (which is different from this one)
		audio_tab.last_played.stop()
	
	if not is_instance_valid(audio_cue):
		# If the row does not have a [PopochiuAudioCue] assigned, then it is the row of an audio
		# file. Therefore, the [AudioStream] to play will be its own [path]
		var stream: AudioStream = load(path)
		stream.loop = false
		stream_player.stream = stream
	else:
		# Otherwise, the [AudioStream] to play will be that of the audio file associated with this
		# [PopochiuAudioCue.audio]
		stream_player.stream = audio_cue.audio
		# The values of [AudioStream.pitch_scale] and [AudioStream.volume_db] should be taken from
		# the information stored in the [PopochiuAudioCue].
		stream_player.pitch_scale = audio_cue.get_pitch_scale()
		stream_player.volume_db = audio_cue.volume
	
	is_playing = true


func stop() -> void:
	is_playing = false
	current_playback_position = 0.0
	label.add_theme_color_override("font_color", dflt_font_color)
	stream_player.stream = null
	audio_tab.last_played = null


#endregion

#region SetGet #####################################################################################
func set_is_playing(value: bool) -> void:
	is_playing = value
	
	if is_playing:
		if not stream_player.finished.is_connected(stop):
			stream_player.finished.connect(stop)
		stream_player.play(current_playback_position)
		audio_tab.last_played = self
	else:
		current_playback_position = stream_player.get_playback_position()
		
		if stream_player.playing:
			stream_player.stop()
			stream_player.finished.disconnect(stop)
	
	play_btn.icon = play_btn.get_theme_icon("Pause" if is_playing else "MainPlay", "EditorIcons")


#endregion

#region Private ####################################################################################
func _get_menu_cfg() -> Array:
	return [
		{
			id = AudioOptions.ADD_TO_MUSIC,
			icon = preload("res://addons/popochiu/icons/music.png"),
			label = "Add to Music"
		},
		{
			id = AudioOptions.ADD_TO_SFX,
			icon = preload("res://addons/popochiu/icons/sfx.png"),
			label = "Add to Sound Effects"
		},
		{
			id = AudioOptions.ADD_TO_VOICE,
			icon = preload("res://addons/popochiu/icons/voice.png"),
			label = "Add to Voices"
		},
		{
			id = AudioOptions.ADD_TO_UI,
			icon = preload("res://addons/popochiu/icons/ui.png"),
			label = "Add to Graphic Interface"
		}
	] + super()


func _menu_item_pressed(id: int) -> void:
	match id:
		AudioOptions.ADD_TO_MUSIC:
			group_selected.emit(PopochiuResources.AudioTypes.MUSIC)
		AudioOptions.ADD_TO_SFX:
			group_selected.emit(PopochiuResources.AudioTypes.SOUND_EFFECT)
		AudioOptions.ADD_TO_VOICE:
			group_selected.emit(PopochiuResources.AudioTypes.VOICE)
		AudioOptions.ADD_TO_UI:
			group_selected.emit(PopochiuResources.AudioTypes.UI)
		_:
			super(id)


func _remove_from_popochiu() -> void:
	# Remove the AudioCue from popochiu_data.cfg ---------------------------------------------------
	var group_data: Array = PopochiuResources.get_data_value(
		"audio", cue_group, []
	)
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
	
	# Remove the AudioCue from the A singleton -----------------------------------------------------
	PopochiuResources.remove_audio_autoload(cue_group, name, audio_cue.resource_path)
	
	# Delete the file in its corresponding group in Audio tab
	deleted.emit(audio_cue.audio.resource_path)
	
	if _delete_dialog.check_box.button_pressed:
		_delete_from_file_system()
	else:
		queue_free()


func _delete_from_file_system() -> void:
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
	queue_free()


#endregion
