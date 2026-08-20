@tool
class_name PopochiuTreeDock
extends VBoxContainer
# Base class for Popochiu dock tabs that display grouped items using a native [Tree] control.
#
# Handles the Tree setup, the filter LineEdit, the right-click context menu, and common helpers to
# create groups and items. Subclasses must provide a scene with a `%Filter` [LineEdit] and a `%Tree`
# [Tree] node, and implement the virtual methods to build their own content.
#
# Ref: #558

signal item_clicked(item: TreeItem)
signal button_clicked(item: TreeItem, id: int)
signal create_clicked(group_item: TreeItem)
signal group_button_clicked(group_item: TreeItem, id: int)
signal menu_item_selected(item: TreeItem, id: int)

const COL_TEXT := 0
const COL_TAG := 1
const COL_BUTTONS := 2

const MENU_SEPARATOR := -1
const MENU_BUTTON_ID := 100

const DELETE_MESSAGE = "This will remove the [b]%s[/b] object in [b]%s[/b] scene. Uses of this \
object in scripts will not work anymore. This action cannot be undone. Continue?"
const DELETE_ASK_MESSAGE = "Do you want to delete the [b]%s[/b] folder too?%s (cannot be reversed)"
const AUDIO_FILE_TYPES = ["AudioStreamOggVorbis", "AudioStreamMP3", "AudioStreamWAV"]
const AudioCue = preload("res://addons/popochiu/engine/audio_manager/audio_cue.gd")

var _context_menu: PopupMenu
var _context_item: TreeItem
var delete_dialog: PopochiuEditorHelper.DeleteConfirmation

@onready var filter: LineEdit = %Filter
@onready var tree: Tree = %Tree


#region Godot ######################################################################################
func _ready() -> void:
	_setup_filter()
	_setup_tree()
	_setup_context_menu()


#endregion

#region Public #####################################################################################
## Creates a group item (a parent item in the Tree) with an optional "+" create button.
func create_group(
	title: String, icon: Texture2D, can_create := true, create_text := "", data: Dictionary = {}
) -> TreeItem:
	# Ensure the hidden root exists first so groups are always its children, never the root itself
	var root := tree.get_root()
	if not root:
		root = tree.create_item()
	var group := tree.create_item(root)
	group.set_text(COL_TEXT, title)
	group.set_icon(COL_TEXT, icon)
	
	var meta := data.duplicate()
	meta["title"] = title
	meta["can_create"] = can_create
	meta["create_text"] = create_text
	group.set_metadata(COL_TEXT, meta)
	
	if can_create:
		add_button(group, get_theme_icon("Add", "EditorIcons"), 0, create_text)
	
	return group


## Appends a new item to [param group] as its last child, preserving the order in which items are
## discovered (no alphabetical sorting).
## Appends a new item to [param group]. By default it is added as the last child, preserving the
## order in which items are discovered. If [param sort] is true, it is inserted alphabetically by
## its text instead.
func add_item(
	group: TreeItem, name: String, icon: Texture2D, data: Dictionary = {}, sort := false
) -> TreeItem:
	var index := -1
	if sort:
		# Insert alphabetically by item text
		index = 0
		for child in group.get_children():
			if child.get_text(COL_TEXT) > name:
				break
			index += 1
	var item := tree.create_item(group, index)
	item.set_text(COL_TEXT, name)
	item.set_icon(COL_TEXT, icon)
	item.set_metadata(COL_TEXT, data)
	item.set_tooltip_text(COL_TEXT, data.get("path", ""))
	update_group_count(group)
	return item


## Adds an icon button to the item's buttons column.
func add_button(item: TreeItem, icon: Texture2D, id: int, tooltip := "") -> void:
	item.add_button(COL_BUTTONS, icon, id, false, tooltip)


## Updates the icon of a button on an item by its id.
func set_button_icon(item: TreeItem, id: int, icon: Texture2D) -> void:
	var btn_idx := item.get_button_by_id(COL_BUTTONS, id)
	if btn_idx >= 0:
		item.set_button(COL_BUTTONS, btn_idx, icon)


## Adds the three-dots button that opens the context menu for the item.
func add_menu_button(item: TreeItem) -> void:
	add_button(item, get_theme_icon("GuiTabMenuHl", "EditorIcons"), MENU_BUTTON_ID, "Options")


## Shows or hides the status tag icon (e.g. main scene, PC, start-with-it) on the item.
func set_tag(item: TreeItem, icon: Texture2D, value: bool) -> void:
	if value:
		item.set_icon(COL_TAG, icon)
	else:
		item.set_icon(COL_TAG, null)


## Dims or restores the item text to indicate whether the object is part of Popochiu or not.
func set_dimmed(item: TreeItem, dimmed: bool) -> void:
	if dimmed:
		item.set_custom_color(COL_TEXT, Color(1, 1, 1, 0.5))
	else:
		item.clear_custom_color(COL_TEXT)


## Updates the group title with its child count. The count is shown from one item onward.
func update_group_count(group: TreeItem) -> void:
	var title: String = group.get_metadata(COL_TEXT).title
	var count := group.get_child_count()
	group.set_text(COL_TEXT, "%s (%d)" % [title, count] if count > 0 else title)


## Enables or disables a button on an item by its id.
func set_button_disabled(item: TreeItem, id: int, disabled: bool) -> void:
	var btn_idx := item.get_button_by_id(COL_BUTTONS, id)
	if btn_idx >= 0:
		item.set_button_disabled(COL_BUTTONS, btn_idx, disabled)


## Enables or disables the group's create button.
func set_create_disabled(group: TreeItem, disabled: bool) -> void:
	set_button_disabled(group, 0, disabled)


## Clears the status tag icon on every child of [param group].
func clear_group_tags(group: TreeItem) -> void:
	for child in group.get_children():
		child.set_icon(COL_TAG, null)


## Returns the first child of [param group] whose text matches [param name], or null.
func get_item(group: TreeItem, name: String) -> TreeItem:
	for child in group.get_children():
		if child.get_text(COL_TEXT) == name:
			return child
	return null


## Removes [param item] from the Tree and updates its parent group count.
func remove_item(item: TreeItem) -> void:
	var group := item.get_parent()
	item.free()
	if group:
		update_group_count(group)


## Clears the whole Tree.
func clear() -> void:
	tree.clear()


## Clears all items but keeps the group items (useful for tabs that keep their groups across
## content changes, like the Room tab).
func clear_items() -> void:
	var root := tree.get_root()
	if not root: return
	
	for group in root.get_children():
		for child in group.get_children():
			child.free()
		update_group_count(group)


#endregion

#region Private ####################################################################################
func _setup_filter() -> void:
	# Only set a default placeholder if the scene did not provide one
	if filter.placeholder_text.is_empty():
		filter.placeholder_text = "Filter game objects"
	filter.clear_button_enabled = true
	filter.right_icon = get_theme_icon("Search", "EditorIcons")
	filter.text_changed.connect(_filter_items)


func _setup_tree() -> void:
	tree.columns = 3
	tree.hide_root = true
	tree.select_mode = Tree.SELECT_ROW
	tree.allow_rmb_select = true
	tree.set_column_expand(COL_TEXT, true)
	tree.set_column_expand(COL_TAG, false)
	tree.set_column_expand(COL_BUTTONS, false)
	tree.set_column_custom_minimum_width(COL_TAG, 16)
	
	tree.item_selected.connect(_on_item_selected)
	tree.button_clicked.connect(_on_button_clicked)
	tree.item_mouse_selected.connect(_on_item_mouse_selected)


func _setup_context_menu() -> void:
	_context_menu = PopupMenu.new()
	_context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	add_child(_context_menu)


## Hides items whose name does not match the filter text, and hides groups with no visible items.
func _filter_items(new_text: String) -> void:
	var root := tree.get_root()
	if not root: return
	
	for group in root.get_children():
		group.set_visible(true)
		
		var title_in_filter := false
		var group_title: String = group.get_metadata(COL_TEXT).title
		if group_title.findn(new_text) > -1:
			title_in_filter = true
		
		var hidden_rows := 0
		var rows := group.get_children()
		
		for row in rows:
			row.set_visible(true)
			if new_text.is_empty(): continue
			if row.get_text(COL_TEXT).findn(new_text) < 0 and not title_in_filter:
				hidden_rows += 1
				row.set_visible(false)
		
		if hidden_rows == rows.size() and not new_text.is_empty():
			group.set_visible(false)


func _on_item_selected() -> void:
	var item := tree.get_selected()
	# Ignore group items (direct children of the hidden root)
	if item and item.get_parent() != tree.get_root():
		item_clicked.emit(item)


func _on_button_clicked(
	item: TreeItem, column: int, id: int, mouse_button_index: int
) -> void:
	if column != COL_BUTTONS or mouse_button_index != MOUSE_BUTTON_LEFT: return
	
	if id == MENU_BUTTON_ID:
		if not item.get_metadata(COL_TEXT).get("no_menu", false):
			_open_context_menu(item)
		return
	
	if item.get_parent() == tree.get_root():
		# Group items: id 0 is the create button, other ids are custom group buttons
		if id == 0:
			create_clicked.emit(item)
		else:
			group_button_clicked.emit(item, id)
	else:
		button_clicked.emit(item, id)


func _on_item_mouse_selected(pos: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_RIGHT: return
	
	var item := tree.get_item_at_position(pos)
	if not item: return
	# Group headers (direct children of the hidden root) have no context menu
	if item.get_parent() == tree.get_root(): return
	# Items flagged with no_menu (e.g. characters in a room) have no context menu
	if item.get_metadata(COL_TEXT).get("no_menu", false): return
	
	_open_context_menu(item)


func _open_context_menu(item: TreeItem) -> void:
	_context_item = item
	_build_context_menu(item)
	# PopupMenu is a Window whose position is in screen coordinates, so we must pass the mouse
	# position in screen coordinates explicitly. Calling popup() with no args uses the viewport
	# mouse position, which for editor docks is wrong and makes the menu appear at the top-left
	# corner of the screen instead of under the cursor.
	_context_menu.popup(Rect2i(DisplayServer.mouse_get_position(), Vector2i.ZERO))


func _build_context_menu(item: TreeItem) -> void:
	_context_menu.clear()
	
	for option in _get_menu_cfg(item):
		if typeof(option) == TYPE_INT and option == MENU_SEPARATOR:
			_context_menu.add_separator()
		else:
			var idx := _context_menu.item_count
			_context_menu.add_icon_item(option.icon, option.label, option.id)
			if option.has("disabled") and option.disabled:
				_context_menu.set_item_disabled(idx, true)


func _on_context_menu_id_pressed(id: int) -> void:
	if _context_item:
		menu_item_selected.emit(_context_item, id)


#endregion

#region Shared helpers ############################################################################
# Helpers shared by all tabs: opening files and deleting objects from the file system.

func open(item: TreeItem) -> void:
	# Defer the scene opening to ensure current operations complete first.
	# Ugly but necessary to avoid errors (see _deferred_open comments).
	call_deferred("_deferred_open", item.get_metadata(COL_TEXT).path)


# Deferring this call removes an error that happens in Godot 4.4:
# 'ERROR: editor/editor_data.cpp:1216 - Condition "!p_node->is_inside_tree()" is true.'
func _deferred_open(path: String) -> void:
	EditorInterface.select_file(path)
	
	if ".tres" in path:
		EditorInterface.edit_resource(load(path))
	else:
		# Change to 2D view and open the scene
		EditorInterface.set_main_screen_editor("2D")
		EditorInterface.open_scene_from_path(path)
		
		# Select the scene root node automatically
		# to make inspector, gizmos and toolbar available
		# for the opened object scene
		if EditorInterface.get_edited_scene_root():
			PopochiuEditorHelper.select_node(EditorInterface.get_edited_scene_root())


func open_script(item: TreeItem) -> void:
	var path: String = item.get_metadata(COL_TEXT).path
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


func remove_object(item: TreeItem) -> void:
	var data := item.get_metadata(COL_TEXT)
	var path: String = data.path
	var name: String = item.get_text(COL_TEXT)
	var location := _get_location(path)
	
	# Look into the Object's folder for audio files and AudioCues to show the developer that those
	# files will be removed too.
	var audio_files := _search_audio_files(
		EditorInterface.get_resource_filesystem().get_filesystem_path(path.get_base_dir())
	)
	
	delete_dialog = PopochiuEditorHelper.DELETE_CONFIRMATION_SCENE.instantiate()
	delete_dialog.title = "Remove %s from %s" % [name, location]
	delete_dialog.message = DELETE_MESSAGE % [name, location]
	delete_dialog.ask = DELETE_ASK_MESSAGE % [
		path.get_base_dir(),
		"" if audio_files.is_empty()
		else " ([b]%d[/b] audio cues will be deleted)" % audio_files.size()
	]
	delete_dialog.on_confirmed = _remove_from_core.bind(item)
	
	PopochiuEditorHelper.show_delete_confirmation(delete_dialog)


# Remove this object's directory (subfolders included) from the file system.
func delete_from_file_system(path: String) -> void:
	var object_dir: EditorFileSystemDirectory = \
		EditorInterface.get_resource_filesystem().get_filesystem_path(path.get_base_dir())
	
	# Collect translatable file paths BEFORE deletion (directory object will be invalidated later)
	var pot_paths_to_remove := PackedStringArray()
	_collect_pot_paths(object_dir, pot_paths_to_remove)
	
	# Remove files, sub folders and its files.
	_recursive_delete(object_dir)
	
	# Remove collected paths from the POT list AFTER deletion to avoid ProjectSettings.save()
	# invalidating the EditorFileSystemDirectory reference used by _recursive_delete.
	_deregister_pot_files(pot_paths_to_remove)


# Removes the given [param paths_to_remove] from the POT generation list in a single batch save.
func _deregister_pot_files(paths_to_remove: PackedStringArray) -> void:
	if paths_to_remove.is_empty():
		return
	
	var files := PopochiuConfig.get_pot_files()
	var changed := false
	for p in paths_to_remove:
		var idx := files.find(p)
		if idx >= 0:
			files.remove_at(idx)
			changed = true
	if changed:
		PopochiuConfig.sync_pot_files(files)


# Recursively collects .gd and .tres file paths from [param dir] into [param result].
func _collect_pot_paths(dir: EditorFileSystemDirectory, result: PackedStringArray) -> void:
	for file_idx in dir.get_file_count():
		var file_path := dir.get_file_path(file_idx)
		var ext := file_path.get_extension()
		if ext == "gd" or ext == "tres":
			result.append(file_path)
	for subdir_idx in dir.get_subdir_count():
		_collect_pot_paths(dir.get_subdir(subdir_idx), result)


# Remove the `dir` directory from the system. For Godot to be able to delete a directory, it has to
# be empty, so this method first deletes the files from from the directory and each of its
# subdirectories.
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


# Delete files within [param dir] directory. First, get the paths to each file, then delete them
# one by one calling [method EditorFileSystem.update_file], so that in case it's an imported file,
# its [b].import[/b] is also deleted.
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


func _search_audio_files(dir: EditorFileSystemDirectory) -> Array:
	var files := []
	
	for idx in dir.get_subdir_count():
		files.append_array(_search_audio_files(dir.get_subdir(idx)))
	
	for idx in dir.get_file_count():
		match dir.get_file_type(idx):
			AUDIO_FILE_TYPES:
				files.append(dir.get_file_path(idx))
	
	return files


# Looks to which audio group corresponds [param audio_cue] and deletes it both from
# [code]popochiu_data.cfg[/code] and the [b]A[/b] singleton (which is the one used to allow code
# autocompletion related to [PopochiuAudioCue]s).
func _delete_audio_cue_in_data(audio_cue: AudioCue) -> bool:
	# TODO: This could be improved a lot if each PopochiuAudioCue has a variable to store the group
	# 		to which it corresponds to.
	# Delete the [PopochiuAudioCue] in the popochiu_data.cfg
	for cue_group in ["mx_cues", "sfx_cues", "vo_cues", "ui_cues"]:
		var cues: Array = PopochiuResources.get_data_value("audio", cue_group, [])
		if not audio_cue.resource_path in cues:
			continue
		
		cues.erase(audio_cue.resource_path)
		if PopochiuResources.set_data_value("audio", cue_group, cues) != OK:
			return false
		
		# Fix #59 : remove the AudioCue from the A singleton
		PopochiuResources.remove_audio_autoload(
			cue_group, audio_cue.resource_name, audio_cue.resource_path
		)
		break
	return true


#endregion

#region Virtual ####################################################################################
# TODO: Rename these virtuals to public (get_menu_cfg, get_location, remove_from_core) when the
# Audio tab is refactored. They are kept underscored for now because tab_audio.gd still overrides
# them.
## Returns the list of options for the right-click context menu of [param item]. Each option is a
## Dictionary with `id`, `icon`, `label` and optional `disabled` keys, or the MENU_SEPARATOR int.
func _get_menu_cfg(item: TreeItem) -> Array:
	return []


## Returns the location name shown in the delete confirmation (e.g. "Popochiu" or "RoomHome").
func _get_location(path: String) -> String:
	return "Popochiu"


## Handles the confirmed deletion of [param item]. Subclasses must implement this to remove the
## object from Popochiu data/autoloads or from the room tree, and to remove the item.
func _remove_from_core(item: TreeItem, should_save_and_delete := true) -> void:
	pass


#endregion