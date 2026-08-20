class_name PopochiuDockRow
extends RefCounted
# Base class for the rows shown in a PopochiuTreeDock tab. Each row knows how to create its group
# and its items, and how to handle clicks, buttons, and context-menu options for its resource type.
#
# Rows are plain RefCounted objects (not Nodes): they hold a reference to the owning tab (a
# PopochiuTreeDock) and call its public helpers to interact with the Tree. Subclasses set their
# config in _init() and override the virtual behavior methods.
#
# Originates from: #558

enum MenuOptions {
	SEPARATOR = -1,
	DELETE,
	ADD_TO_CORE,
	SET_AS_MAIN,
	SET_AS_PC,
	START_WITH_IT,
}

enum Buttons {
	OPEN,
	SCRIPT,
	STATE,
	STATE_SCRIPT,
	PLAY,
	REMOVE_CHARACTER,
	ADD_CHARACTER,
}

const ADD_TO_CORE_ICON = preload("res://addons/popochiu/icons/add_to_core.png")

var dock: PopochiuTreeDock
var type: int
var group: TreeItem

# Config (subclasses set these in _init())
var _title := ""
var _icon: Texture2D
var _create_text := ""
var _popup: PackedScene
var _folder_path := ""
var _scene_template := ""
var _method := ""
var _type_class: Variant
var _parent_name := ""
var _getter := ""


func _init(dock: PopochiuTreeDock, type: int) -> void:
	self.dock = dock
	self.type = type


#region Config ####################################################################################
func get_title() -> String:
	return _title


func get_icon() -> Texture2D:
	return _icon


func get_create_text() -> String:
	return _create_text


func get_popup() -> PackedScene:
	return _popup


func get_folder_path() -> String:
	return _folder_path


func get_scene_template() -> String:
	return _scene_template


func get_method() -> String:
	return _method


func get_type_class() -> Variant:
	return _type_class


func get_parent_name() -> String:
	return _parent_name


func get_getter() -> String:
	return _getter


#endregion

#region Group #####################################################################################
## Creates the group item for this row's type in the dock's Tree.
func create_group() -> TreeItem:
	group = dock.create_group(get_title(), get_icon(), true, get_create_text(), { "type": type })
	return group


#endregion

#region Row #######################################################################################
## Creates the row for [param source] in the dock's Tree. Type-specific. [param source] is a
## Resource for the main object types (rooms, characters, ...) or a Node for the room object types.
func create_row(source) -> TreeItem:
	return null


## Creates the TreeItem for this row's type with the shared action buttons.
func create_item(name_to_add: String) -> TreeItem:
	var path: String = get_scene_template().replace("%s", name_to_add.to_snake_case())
	var data := {
		"type": type,
		"path": path,
		"script_name": name_to_add,
		"in_core": true,
	}
	
	var item := dock.add_item(group, name_to_add, get_icon(), data)
	
	# Add the action buttons
	dock.add_button(item, dock.get_theme_icon("InstanceOptions", "EditorIcons"), Buttons.OPEN, "Open in Editor")
	dock.add_button(item, dock.get_theme_icon("Script", "EditorIcons"), Buttons.SCRIPT, "Open in Script")
	dock.add_button(item, dock.get_theme_icon("Object", "EditorIcons"), Buttons.STATE, "Open state")
	dock.add_button(item, dock.get_theme_icon("GDScript", "EditorIcons"), Buttons.STATE_SCRIPT, "Open state Script")
	_add_extra_buttons(item)
	dock.add_menu_button(item)
	
	dock.rows_paths.append(path)
	dock.has_data = true
	
	return item


## Hook for subclasses to add type-specific buttons (e.g. the Play button for rooms).
func _add_extra_buttons(item: TreeItem) -> void:
	pass


#endregion

#region Virtual ###################################################################################
## Returns the list of options for the right-click context menu of [param item]. Default: the
## shared "Add to Popochiu" + "Remove" options used by the main object types.
func get_menu_cfg(item: TreeItem) -> Array:
	var data := item.get_metadata(dock.COL_TEXT)
	return [
		{
			id = MenuOptions.ADD_TO_CORE,
			icon = ADD_TO_CORE_ICON,
			label = "Add to Popochiu",
			disabled = data.get("in_core", true),
		},
		MenuOptions.SEPARATOR,
		{
			id = MenuOptions.DELETE,
			icon = dock.get_theme_icon("Remove", "EditorIcons"),
			label = "Remove",
		},
	]


## Handles the confirmed deletion of [param item]. Shared by the main object types: removes the
## object from Popochiu data and its autoload (via _remove_from_data), then deletes the folder if
## requested, dims the row if the object is no longer in Popochiu, and saves the scene.
func remove_from_core(item: TreeItem, should_save_and_delete := true) -> void:
	var data := item.get_metadata(dock.COL_TEXT)
	var path: String = data.path
	var name: String = item.get_text(dock.COL_TEXT)
	
	# Remove the object from Popochiu data and its corresponding autoload
	_remove_from_data(name)
	
	# Check if the files should be deleted in the file system
	if dock.delete_dialog.check_box.button_pressed:
		dock.delete_from_file_system(path)
	elif type in PopochiuResources.MAIN_TYPES:
		dock.set_dimmed(item, true)
		data.in_core = false
	
	var edited_scene: Node = EditorInterface.get_edited_scene_root()
	if edited_scene and edited_scene.get("script_name") and edited_scene.script_name == name:
		# If the open scene matches the object being deleted, skip saving the scene
		dock.remove_item(item)
		return
	
	# Fix #438: Do not save and free the row always. When this function is called from the
	# popochiu_room_object_row script, saving the scene is handled there, and deleting the row
	# is not needed.
	if should_save_and_delete:
		EditorInterface.save_scene()
		dock.remove_item(item)


## Adds the object back to Popochiu (the core). Shared by the main object types.
func add_to_core(item: TreeItem) -> void:
	var data := item.get_metadata(dock.COL_TEXT)
	var path: String = data.path
	var resource: Resource
	
	if ".tscn" in path:
		resource = load(path.replace(".tscn", ".tres"))
	else:
		resource = load(path)
	
	if PopochiuEditorHelper.add_resource_to_popochiu(_get_target_array(), resource) != OK:
		PopochiuUtils.print_error(
			"Couldn't add Object [b]%s[/b] to Popochiu." % item.get_text(dock.COL_TEXT)
		)
		return
	
	# Add the object to its corresponding singleton
	PopochiuResources.update_autoloads(true)
	
	dock.set_dimmed(item, false)
	data.in_core = true


## Called when an item is clicked. Default: selects the file in the FileSystem dock.
func on_item_clicked(item: TreeItem) -> void:
	EditorInterface.select_file(item.get_metadata(dock.COL_TEXT).path)


## Called when a button on an item is clicked. Default: handles the OPEN, SCRIPT, STATE and
## STATE_SCRIPT buttons shared by the main object types.
func on_button_clicked(item: TreeItem, id: int) -> void:
	match id:
		Buttons.OPEN:
			dock.open(item)
		Buttons.SCRIPT:
			dock.open_script(item)
		Buttons.STATE:
			edit_state(item)
		Buttons.STATE_SCRIPT:
			open_state_script(item)


## Called when a context-menu option is selected. Default: handles DELETE and ADD_TO_CORE.
func on_menu_item_selected(item: TreeItem, id: int) -> void:
	match id:
		MenuOptions.DELETE:
			dock.remove_object(item)
		MenuOptions.ADD_TO_CORE:
			add_to_core(item)


## Opens the state resource (.tres) of the object in the editor.
func edit_state(item: TreeItem) -> void:
	var path: String = item.get_metadata(dock.COL_TEXT).path
	EditorInterface.select_file(path.replace(".tscn", ".tres"))
	EditorInterface.edit_resource(load(path.replace(".tscn", ".tres")))


## Opens the script of the object's state resource in the editor.
func open_state_script(item: TreeItem) -> void:
	var path: String = item.get_metadata(dock.COL_TEXT).path
	var state := load(path.replace(".tscn", ".tres"))
	
	EditorInterface.select_file(state.get_script().resource_path)
	EditorInterface.set_main_screen_editor("Script")
	EditorInterface.edit_resource(state.get_script())


## Removes the object from Popochiu data and its autoload. Type-specific.
func _remove_from_data(name: String) -> void:
	pass


## Returns the Popochiu data section name for this type (e.g. "rooms"). Type-specific.
func _get_target_array() -> String:
	return ""


#endregion