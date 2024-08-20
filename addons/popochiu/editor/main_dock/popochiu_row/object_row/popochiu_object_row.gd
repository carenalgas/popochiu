@tool
extends "res://addons/popochiu/editor/main_dock/popochiu_row/popochiu_row.gd"
## Row for the main object types: Room, Character, Inventory item, Dialog

enum Options {
	DELETE = MenuOptions.DELETE,
	ADD_TO_CORE,
}

const DELETE_MESSAGE = "This will remove the [b]%s[/b] object in [b]%s[/b] scene. Uses of this \
object in scripts will not work anymore. This action cannot be undone. Continue?"
const DELETE_ASK_MESSAGE = "Do you want to delete the [b]%s[/b] folder too?%s (cannot be reversed)"
const ADD_TO_CORE_ICON = preload(
	"res://addons/popochiu/editor/main_dock/popochiu_row/images/add_to_core.png"
)
const AUDIO_FILE_TYPES = ["AudioStreamOggVorbis", "AudioStreamMP3", "AudioStreamWAV"]

@onready var btn_open: Button = %BtnOpen
@onready var btn_script: Button = %BtnScript
@onready var btn_state: Button = %BtnState
@onready var btn_state_script: Button = %BtnStateScript


#region Godot ######################################################################################
func _ready() -> void:
	# Assign icons
	btn_open.icon = get_theme_icon("InstanceOptions", "EditorIcons")
	btn_script.icon = get_theme_icon("Script", "EditorIcons")
	btn_state.icon = get_theme_icon("Object", "EditorIcons")
	btn_state_script.icon = get_theme_icon("GDScript", "EditorIcons")
	
	# Connect to signals and create the options for the menu
	super()
	
	# Connect to childrens' signals
	btn_open.pressed.connect(_open)
	btn_script.pressed.connect(_open_script)
	btn_state.pressed.connect(_edit_state)
	btn_state_script.pressed.connect(_open_state_script)
	
	# Disable some options by default
	var add_to_core_idx := menu_popup.get_item_index(Options.ADD_TO_CORE)
	if add_to_core_idx >= 0:
		menu_popup.set_item_disabled(add_to_core_idx, true)


#endregion

#region Virtual ####################################################################################
## Shows a confirmation popup to ask the developer if the Popochiu object should be removed only
## from the core, or from the file system too.
func _remove_object() -> void:
	var location := _get_location()
	
	# Look into the Object"s folder for audio files and AudioCues to show the developer that those
	# files will be removed too.
	var audio_files := _search_audio_files(
		EditorInterface.get_resource_filesystem().get_filesystem_path(path.get_base_dir())
	)
	
	_delete_dialog = PopochiuEditorHelper.DELETE_CONFIRMATION_SCENE.instantiate()
	_delete_dialog.title = "Remove %s from %s" % [name, location]
	_delete_dialog.message = DELETE_MESSAGE % [name, location]
	_delete_dialog.ask = DELETE_ASK_MESSAGE % [
		path.get_base_dir(),
		"" if audio_files.is_empty()
		else " ([b]%d[/b] audio cues will be deleted)" % audio_files.size()
	]
	_delete_dialog.on_confirmed = _remove_from_core
	
	PopochiuEditorHelper.show_delete_confirmation(_delete_dialog)


func _get_state_template() -> Script:
	return null


func _get_location() -> String:
	return "Popochiu"


#endregion

#region Public #####################################################################################
## Called to make the row appear semitransparent to indicate that the object is in the project
## (has a folder with files inside) but is not part of the [code]popochiu_data.cfg[/code] file nor
## its corresponding autoload (e.g., R, C, I, D). This can happen when one removes an object from
## the project without removing its files, or when adding objects from another project.
func show_as_not_in_core() -> void:
	label.modulate.a = 0.5
	menu_popup.set_item_disabled(menu_popup.get_item_index(Options.ADD_TO_CORE), false)


#endregion

#region Private ####################################################################################
func _get_menu_cfg() -> Array:
	return [
		{
			id = Options.ADD_TO_CORE,
			icon = ADD_TO_CORE_ICON,
			label = "Add to Popochiu",
			types = PopochiuResources.MAIN_TYPES
		},
	] + super()


func _menu_item_pressed(id: int) -> void:
	match id:
		Options.ADD_TO_CORE:
			_add_object_to_core()
		_:
			super(id)


## Add this Object (Room, Character, InventoryItem, Dialog) to popochiu_data.cfg so it can be used
## by Popochiu.
func _add_object_to_core() -> void:
	var target_array := ""
	var resource: Resource
	
	if ".tscn" in path:
		resource = load(path.replace(".tscn", ".tres"))
	else:
		resource = load(path)
	
	match type:
		PopochiuResources.Types.ROOM:
			target_array = "rooms"
		PopochiuResources.Types.CHARACTER:
			target_array = "characters"
		PopochiuResources.Types.INVENTORY_ITEM:
			target_array = "inventory_items"
		PopochiuResources.Types.DIALOG:
			target_array = "dialogs"
	
	if PopochiuEditorHelper.add_resource_to_popochiu(target_array, resource) != OK:
		PopochiuUtils.print_error("Couldn't add Object [b]%s[/b] to Popochiu." % str(name))
		return
	
	# Add the object to its corresponding singleton
	PopochiuResources.update_autoloads(true)
	
	label.modulate.a = 1.0
	
	menu_popup.set_item_disabled(menu_popup.get_item_index(Options.ADD_TO_CORE), true)


## Selects the main file of the object in the FileSystem and opens it so that it can be edited.
func _open() -> void:
	EditorInterface.select_file(path)
	
	if ".tres" in path:
		EditorInterface.edit_resource(load(path))
	else:
		EditorInterface.set_main_screen_editor("2D")
		EditorInterface.open_scene_from_path(path)
	
	select()


func _open_script() -> void:
	var script_path := path
	
	if ".tscn" in path:
		# A room, character, inventory item, or prop
		script_path = path.replace(".tscn", ".gd")
	elif ".tres" in path:
		# A dialog
		script_path = path.replace(".tres", ".gd")
	elif not ".gd" in path:
		return
	
	EditorInterface.select_file(script_path)
	EditorInterface.set_main_screen_editor("Script")
	EditorInterface.edit_script(load(script_path))
	
	select()


func _edit_state() -> void:
	EditorInterface.select_file(path.replace(".tscn", ".tres"))
	EditorInterface.edit_resource(load(path.replace(".tscn", ".tres")))
	
	select()


func _open_state_script() -> void:
	var state := load(path.replace(".tscn", ".tres"))
	
	EditorInterface.select_file(state.get_script().resource_path)
	EditorInterface.set_main_screen_editor("Script")
	EditorInterface.edit_resource(state.get_script())
	
	select()


func _search_audio_files(dir: EditorFileSystemDirectory) -> Array:
	var files := []
	
	for idx in dir.get_subdir_count():
		files.append_array(_search_audio_files(dir.get_subdir(idx)))
	
	for idx in dir.get_file_count():
		match dir.get_file_type(idx):
			AUDIO_FILE_TYPES:
				files.append(dir.get_file_path(idx))
	
	return files


func _remove_from_core() -> void:
	# Check if the files should be deleted in the file system
	if _delete_dialog.check_box.button_pressed:
		_delete_from_file_system()
	elif type in PopochiuResources.MAIN_TYPES:
		show_as_not_in_core()
	
	var edited_scene: Node = EditorInterface.get_edited_scene_root()
	if edited_scene and edited_scene.get("script_name") and edited_scene.script_name == name:
		# If the open scene matches the object being deleted, skip saving the scene
		queue_free()
		return
	
	EditorInterface.save_scene()
	queue_free()


## Remove this object's directory (subfolders included) from the file system.
func _delete_from_file_system() -> void:
	var object_dir: EditorFileSystemDirectory = \
		EditorInterface.get_resource_filesystem().get_filesystem_path(path.get_base_dir())
	
	# Remove files, sub folders and its files.
	_recursive_delete(object_dir)


## Remove the `dir` directory from the system. For Godot to be able to delete a directory, it has to
## be empty, so this method first deletes the files from from the directory and each of its
## subdirectories.
func _recursive_delete(dir: EditorFileSystemDirectory) -> void:
	if dir.get_file_count() > 0:
		assert(
			_delete_files(dir) == OK,
			"[Popochiu] Error removing files in recursive elimination of %s" % dir.get_path()
		)
	
	if dir.get_subdir_count() > 0:
		for folder_idx in dir.get_subdir_count():
			# Check if there are more folders inside the folder or delete the files inside it before
			# deleting the folder itself
			_recursive_delete(dir.get_subdir(folder_idx))
	
	assert(
		 DirAccess.remove_absolute(dir.get_path()) == OK,
		"[Popochiu] Error removing folder in recursive elimination of %s" % dir.get_path()
	)
	EditorInterface.get_resource_filesystem().scan()


## Delete files within [param dir] directory. First, get the paths to each file, then delete them
## one by one calling [method EditorFileSystem.update_file], so that in case it's an imported file,
## its [b].import[/b] is also deleted.
func _delete_files(dir: EditorFileSystemDirectory) -> int:
	# Stores the paths of the files to be deleted.
	var files_paths := []
	# Stores the paths of the audio resources to delete
	var deleted_audios := []
	
	for file_idx: int in dir.get_file_count():
		match dir.get_file_type(file_idx):
			AUDIO_FILE_TYPES:
				deleted_audios.append(dir.get_file_path(file_idx))
			"Resource":
				var resource: Resource = load(dir.get_file_path(file_idx))
				if not resource is AudioCue:
					# If the resource is not an AudioCue, then it should be ignored for deletion
					# in the game data
					continue
				
				# Delete the [PopochiuAudioCue] in the project data file and the A singleton
				assert(
					_delete_audio_cue_in_data(resource) == true,
					"[Popochiu] Couldn't remove [b]%s[/b] during deletion of [b]%s[/b]." %
					[resource.resource_path, dir.get_path()]
				)
				
				deleted_audios.append(resource.audio.resource_path)
		
		files_paths.append(dir.get_file_path(file_idx))
	
	for fp: String in files_paths:
		var err: int = DirAccess.remove_absolute(fp)
		if err != OK:
			PopochiuUtils.print_error("Couldn't delete file %s. err_code:%d" % [err, fp])
			return err
		EditorInterface.get_resource_filesystem().scan()
	
	# Delete the rows of audio files and the deleted AudioCues in the Audio tab
	if not deleted_audios.is_empty():
		PopochiuEditorHelper.signal_bus.audio_cues_deleted.emit(deleted_audios)
	
	# Remove extra files (like .import)
	for file_name: String in DirAccess.get_files_at(dir.get_path()):
		DirAccess.remove_absolute(dir.get_path() + "/" + file_name)
		EditorInterface.get_resource_filesystem().scan()
	
	return OK


## Looks to which audio group corresponds [param audio_cue] and deletes it both from
## [code]popochiu_data.cfg[/code] and the [b]A[/b] singleton (which is the one used to allow code
## autocompletion related to [PopochiuAudioCue]s).
func _delete_audio_cue_in_data(audio_cue: AudioCue) -> bool:
	# TODO: This could be improved a lot if each PopochiuAudioCue has a variable to store the group
	# 		to which it corresponds to.
	# Delete the [PopochiuAudioCue] in the popochiu_data.cfg
	for cue_group in ["mx_cues", "sfx_cues", "vo_cues", "ui_cues"]:
		var cues: Array = PopochiuResources.get_data_value("audio", cue_group, [])
		if not cues.has(audio_cue.resource_path): continue
		
		cues.erase(audio_cue.resource_path)
		if PopochiuResources.set_data_value("audio", cue_group, cues) != OK:
			return false
		
		# Fix #59 : remove the [PopochiuAudioCue] from the [A] singleton
		PopochiuResources.remove_audio_autoload(
			cue_group, audio_cue.resource_name, audio_cue.resource_path
		)
		break
	return true


#endregion
