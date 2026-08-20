class_name PopochiuRoomObjRow
extends PopochiuDockRow
# Base class for the rows of room objects (Props, Hotspots, Regions, Markers, Walkable areas) in
# the Room tab. Subclasses only set their config in _init(); all behavior is shared here.
#
# Ref: #558

func _init(dock: PopochiuTreeDock, type: int) -> void:
	super(dock, type)


func create_group() -> TreeItem:
	var can_create := get_popup() != null
	group = dock.create_group(get_title(), get_icon(), can_create, get_create_text(), { "type": type })
	return group


func create_row(child) -> TreeItem:
	if not is_instance_of(child, get_type_class()): return null
	
	var row_path := _get_row_path(child)
	if row_path in dock.rows_paths: return null
	
	var node_path := _get_node_path(child)
	var item := create_room_item(child.name, row_path, node_path)
	
	# Add the action buttons
	dock.add_button(item, dock.get_theme_icon("InstanceOptions", "EditorIcons"), Buttons.OPEN, "Open in Editor")
	if FileAccess.file_exists(row_path.replace(".tscn", ".gd")):
		dock.add_button(item, dock.get_theme_icon("Script", "EditorIcons"), Buttons.SCRIPT, "Open in Script")
	dock.add_menu_button(item)
	
	return item


func create_room_item(name: String, path: String, node_path: String) -> TreeItem:
	var data := {
		"type": type,
		"path": path,
		"node_path": node_path,
		"script_name": name,
	}
	var item := dock.add_item(group, name, get_icon(), data)
	dock.rows_paths.append("%s/%d/%s" % [dock.opened_room.script_name, type, name])
	return item


func get_menu_cfg(item: TreeItem) -> Array:
	return [
		{
			id = MenuOptions.DELETE,
			icon = dock.get_theme_icon("Remove", "EditorIcons"),
			label = "Remove",
		}
	]


func on_item_clicked(item: TreeItem) -> void:
	var data := item.get_metadata(dock.COL_TEXT)
	if is_instance_valid(dock.opened_room):
		var node: Node = dock.opened_room.get_node("%s/%s" % [get_parent_name(), data.node_path])
		PopochiuEditorHelper.select_node(node)


func remove_from_core(item: TreeItem, should_save_and_delete := true) -> void:
	var data := item.get_metadata(dock.COL_TEXT)
	var path: String = data.path
	var name: String = item.get_text(dock.COL_TEXT)
	
	var room_child_to_free: Node = null
	if EditorInterface.get_edited_scene_root() is PopochiuRoom:
		var opened_room: PopochiuRoom = EditorInterface.get_edited_scene_root()
		room_child_to_free = opened_room.call(get_getter(), name)
	
	# Check if the files should be deleted in the file system
	if dock.delete_dialog.check_box.button_pressed:
		dock.delete_from_file_system(path)
	
	# Fix #196: Remove the Node from the Room tree once the folder of the object has been deleted
	# from the FileSystem (this applies to Props, Hotspots, Walkable areas and Regions).
	if room_child_to_free:
		room_child_to_free.queue_free()
	
	EditorInterface.save_scene()


func on_child_added(node: Node) -> void:
	if not is_instance_of(node, get_type_class()): return
	
	node.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0


func on_child_removed(node: Node) -> void:
	if not is_instance_of(node, get_type_class()): return
	
	var node_name := node.name
	dock.rows_paths.erase("%s/%d/%s" % [dock.opened_room.script_name, type, node_name])
	
	var item := dock.get_item(group, node_name)
	if item:
		dock.remove_item(item)


func _get_row_path(child: Node) -> String:
	var row_path := child.scene_file_path
	
	if row_path.is_empty() and child.script and not "addons" in child.script.resource_path:
		row_path = child.script.resource_path
	
	return row_path


func _get_node_path(child: Node) -> String:
	return String(child.get_path()).split("%s/" % get_parent_name())[1]