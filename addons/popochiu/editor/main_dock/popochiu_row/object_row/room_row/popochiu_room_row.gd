@tool
extends "res://addons/popochiu/editor/main_dock/popochiu_row/object_row/popochiu_object_row.gd"

enum RoomOptions {
	DELETE = MenuOptions.DELETE,
	ADD_TO_CORE = Options.ADD_TO_CORE,
	SET_AS_MAIN,
}

const STATE_TEMPLATE = "res://addons/popochiu/engine/templates/room_state_template.gd"

var is_main := false : set = set_is_main

@onready var btn_play: Button = %BtnPlay


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Assign icons
	tag.texture = get_theme_icon("Heart", "EditorIcons")
	btn_play.icon = get_theme_icon("MainPlay", "EditorIcons")
	
	btn_play.pressed.connect(_play)


#endregion

#region Virtual ####################################################################################
func _get_state_template() -> Script:
	return load(STATE_TEMPLATE)


func _clear_tag() -> void:
	if is_main:
		is_main = false


#endregion

#region SetGet #####################################################################################
func set_is_main(value: bool) -> void:
	is_main = value
	
	if is_main:
		# Call this first since the favs will be cleared
		PopochiuEditorHelper.signal_bus.main_scene_changed.emit(path)
	
	tag.visible = value
	menu_popup.set_item_disabled(menu_popup.get_item_index(RoomOptions.SET_AS_MAIN), value)


#endregion

#region Private ####################################################################################
func _get_menu_cfg() -> Array:
	return [
		{
			id = RoomOptions.SET_AS_MAIN,
			icon = get_theme_icon("Heart", "EditorIcons"),
			label = "Set as Main scene",
		},
	] + super()


func _menu_item_pressed(id: int) -> void:
	match id:
		RoomOptions.SET_AS_MAIN:
			is_main = true
		_:
			super(id)


## Plays the scene of the clicked row
func _play() -> void:
	EditorInterface.select_file(path)
	EditorInterface.play_custom_scene(path)


func _remove_from_core() -> void:
	# Delete the object from Popochiu
	PopochiuResources.remove_autoload_obj(PopochiuResources.R_SNGL, name)
	PopochiuResources.erase_data_value("rooms", str(name))
	
	# Continue with the deletion flow
	super()


#endregion
