class_name PopochiuCharacterInRoomRow
extends PopochiuDockRow
# Row for the Characters in the Room tab. Characters are external objects linked into the room, so
# this row is special: it has no create button, no context menu, and a "Remove character from room"
# button instead of the usual open/script buttons.
# It is the only Room Tab row that don't inherit from PopochiuRoomObjRow.
#
# Ref: #558

func _init(dock: PopochiuTreeDock) -> void:
	super(dock, PopochiuResources.Types.CHARACTER)
	_title = "Characters in room"
	_icon = preload("res://addons/popochiu/icons/character.png")
	_create_text = ""
	_method = "get_characters"
	_type_class = PopochiuCharacter
	_parent_name = "Characters"


func create_group() -> TreeItem:
	group = dock.create_group(get_title(), get_icon(), false, "", { "type": type })
	return group


func create_row(child: Variant) -> TreeItem:
	if not child is PopochiuCharacter: return null
	
	# Get the script_name of the character
	var char_name: String = child.name.trim_prefix("Character").rstrip(" *")
	dock.characters_in_room.append(char_name)
	
	# Create the item for the character
	var item := create_room_item(
		char_name,
		"res://game/characters/%s/character_%s.tscn".replace("%s", char_name.to_snake_case()),
		child.name
	)
	item.get_metadata(dock.COL_TEXT).no_menu = true
	
	# Create button to remove the character from the room
	dock.add_button(
		item, dock.get_theme_icon("Unlinked", "EditorIcons"), Buttons.REMOVE_CHARACTER,
		"Remove character from room"
	)
	
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


func on_item_clicked(item: TreeItem) -> void:
	var data := item.get_metadata(dock.COL_TEXT)
	if is_instance_valid(dock.opened_room):
		var node: Node = dock.opened_room.get_node("%s/%s" % [get_parent_name(), data.node_path])
		PopochiuEditorHelper.select_node(node)


func on_button_clicked(item: TreeItem, id: int) -> void:
	match id:
		Buttons.REMOVE_CHARACTER:
			_remove_character_from_room(item)


func get_menu_cfg(item: TreeItem) -> Array:
	return []


func on_child_added(node: Node) -> void:
	if not node is PopochiuCharacter: return
	
	node.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0


func on_child_removed(node: Node) -> void:
	if not node is PopochiuCharacter: return
	
	var node_name: String = node.name.lstrip("Character").rstrip(" *")
	dock.characters_in_room.erase(node_name)
	
	var item := dock.get_item(group, node_name)
	if item:
		dock.remove_item(item)


func _remove_character_from_room(item: TreeItem) -> void:
	dock.delete_dialog = PopochiuEditorHelper.DELETE_CONFIRMATION_SCENE.instantiate()
	dock.delete_dialog.title = "Remove character in room"
	dock.delete_dialog.message = (
		"Are you sure you want to remove [b]%s[/b] from this room?" % item.get_text(dock.COL_TEXT)
	)
	dock.delete_dialog.on_confirmed = _on_remove_character_confirmed.bind(item)
	
	PopochiuEditorHelper.show_delete_confirmation(dock.delete_dialog)


func _on_remove_character_confirmed(item: TreeItem) -> void:
	var name: String = item.get_text(dock.COL_TEXT)
	dock.characters_in_room.erase(name)
	dock.opened_room.get_node("Characters").get_node("Character%s *" % name).queue_free()
	dock.remove_item(item)
	EditorInterface.save_scene()