class_name PopochiuRoomRow
extends PopochiuDockRow
# Row for Rooms in the Main tab. Rooms can be set as the main scene and played directly.
#
# Ref: #558

func _init(dock: PopochiuTreeDock) -> void:
	super(dock, PopochiuResources.Types.ROOM)
	_title = "Rooms"
	_icon = preload("res://addons/popochiu/icons/room.png")
	_create_text = "Create room"
	_popup = PopochiuEditorHelper.CREATE_ROOM
	_folder_path = PopochiuResources.ROOMS_PATH
	_scene_template = PopochiuResources.ROOMS_PATH.path_join("%s/room_%s.tscn")


#region Row #######################################################################################
func create_row(resource) -> TreeItem:
	if get_scene_template().replace("%s", resource.resource_name) in dock.rows_paths: return null
	
	var item := create_item(resource.script_name)
	var data := item.get_metadata(dock.COL_TEXT)
	
	# Check if the room is in the rooms array in Popochiu (Popochiu.tscn)
	var is_in_core := PopochiuResources.has_data_value("rooms", resource.script_name)
	
	# Check if the room is the main scene
	var main_scene: String = ProjectSettings.get_setting(PopochiuResources.MAIN_SCENE)
	if main_scene == resource.scene:
		dock.set_tag(item, dock.get_theme_icon("Heart", "EditorIcons"), true)
		data.is_main = true
	
	if not is_in_core:
		dock.set_dimmed(item, true)
		data.in_core = false
	
	return item


func _add_extra_buttons(item: TreeItem) -> void:
	dock.add_button(item, dock.get_theme_icon("MainPlay", "EditorIcons"), Buttons.PLAY, "Play scene")


func get_menu_cfg(item: TreeItem) -> Array:
	var data := item.get_metadata(dock.COL_TEXT)
	var cfg := [
		{
			id = MenuOptions.SET_AS_MAIN,
			icon = dock.get_theme_icon("Heart", "EditorIcons"),
			label = "Set as Main scene",
			disabled = data.get("is_main", false),
		},
	]
	cfg.append_array(super.get_menu_cfg(item))
	return cfg


func on_menu_item_selected(item: TreeItem, id: int) -> void:
	match id:
		MenuOptions.SET_AS_MAIN:
			set_main(item, true)
		_:
			super.on_menu_item_selected(item, id)


func on_button_clicked(item: TreeItem, id: int) -> void:
	match id:
		Buttons.PLAY:
			play(item)
		_:
			super.on_button_clicked(item, id)


func set_main(item: TreeItem, value: bool) -> void:
	if value:
		# Call this first since the favs will be cleared
		PopochiuEditorHelper.signal_bus.main_scene_changed.emit(item.get_metadata(dock.COL_TEXT).path)
	
	dock.set_tag(item, dock.get_theme_icon("Heart", "EditorIcons"), value)
	item.get_metadata(dock.COL_TEXT).is_main = value


func play(item: TreeItem) -> void:
	var path: String = item.get_metadata(dock.COL_TEXT).path
	EditorInterface.select_file(path)
	EditorInterface.play_custom_scene(path)


func _remove_from_data(name: String) -> void:
	PopochiuResources.remove_autoload_obj(PopochiuResources.R_SNGL, name)
	PopochiuResources.erase_data_value("rooms", name)


func _get_target_array() -> String:
	return "rooms"


#endregion