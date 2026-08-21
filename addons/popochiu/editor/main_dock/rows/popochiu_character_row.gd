class_name PopochiuCharacterRow
extends PopochiuDockRow
# Row for Characters in the Main tab. A character can be set as the Player-controlled Character
# (PC).
#
# Ref: #558

const PLAYER_ICON = preload("res://addons/popochiu/icons/player_character.png")

func _init(dock: PopochiuTreeDock) -> void:
	super(dock, PopochiuResources.Types.CHARACTER)
	_title = "Characters"
	_icon = preload("res://addons/popochiu/icons/character.png")
	_create_text = "Create character"
	_popup = PopochiuEditorHelper.CREATE_CHARACTER
	_folder_path = PopochiuResources.CHARACTERS_PATH
	_scene_template = PopochiuResources.CHARACTERS_PATH.path_join("%s/character_%s.tscn")


#region Row #######################################################################################
func create_row(resource: Variant) -> TreeItem:
	if get_scene_template().replace("%s", resource.resource_name) in dock.rows_paths: return null
	
	var item := create_item(resource.script_name)
	var data := item.get_metadata(dock.COL_TEXT)
	
	# Check if the character is in the characters array in Popochiu (Popochiu.tscn)
	var is_in_core := PopochiuResources.has_data_value("characters", resource.script_name)
	
	# Check if the character is the Player-controlled Character (PC)
	if resource.script_name == PopochiuResources.get_data_value("setup", "pc", ""):
		dock.set_tag(item, PLAYER_ICON, true)
		data.is_pc = true
	
	if not is_in_core:
		dock.set_dimmed(item, true)
		data.in_core = false
	
	return item


func get_menu_cfg(item: TreeItem) -> Array:
	var data := item.get_metadata(dock.COL_TEXT)
	var cfg := [
		{
			id = MenuOptions.SET_AS_PC,
			icon = PLAYER_ICON,
			label = "Set as Player-controlled Character (PC)",
			disabled = data.get("is_pc", false),
		},
	]
	cfg.append_array(super.get_menu_cfg(item))
	return cfg


func on_menu_item_selected(item: TreeItem, id: int) -> void:
	match id:
		MenuOptions.SET_AS_PC:
			set_pc_item(item, true)
		_:
			super.on_menu_item_selected(item, id)


func set_pc_item(item: TreeItem, value: bool) -> void:
	if value:
		# Call this first since the favs will be cleared
		PopochiuEditorHelper.signal_bus.pc_changed.emit(item.get_metadata(dock.COL_TEXT).script_name)
	
	dock.set_tag(item, PLAYER_ICON, value)
	item.get_metadata(dock.COL_TEXT).is_pc = value


func _remove_from_data(name: String) -> void:
	PopochiuResources.remove_autoload_obj(PopochiuResources.C_SNGL, name)
	PopochiuResources.erase_data_value("characters", name)


func _get_target_array() -> String:
	return "characters"


#endregion