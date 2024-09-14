@tool
extends "res://addons/popochiu/editor/popups/create_object/create_object.gd"
## Creates a [PopochiuRoom].
## 
## It creates all the necessary files to make a [PopochiuRoom] to work and
## to store its state:
## - room_xxx.tscn
## - room_xxx.gd
## - room_xxx.tres
## - room_xxx_state.gd

var _new_room_name := ""
var _factory: PopochiuRoomFactory
var _show_set_as_main := false : set = set_show_set_as_main

@onready var set_as_main_panel: PanelContainer = %SetAsMainPanel
@onready var rtl_is_main = %RtlIsMain
@onready var btn_is_main: CheckBox = %BtnIsMain


#region Godot ######################################################################################
func _ready() -> void:
	_info_files = _info_files.replace("&t", "room")
	
	super()


#endregion

#region Virtual ####################################################################################
func _create() -> Object:
	if _new_room_name.is_empty():
		error_feedback.show()
		return null
	
	# Setup the prop helper and use it to create the prop ------------------------------------------
	_factory = PopochiuRoomFactory.new()
	if _factory.create(_new_room_name, btn_is_main.button_pressed) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return null
	await get_tree().create_timer(0.1).timeout
	
	return _factory.get_obj_scene()


func _on_about_to_popup() -> void:
	PopochiuEditorHelper.override_font(rtl_is_main, "normal_font", "main")
	PopochiuEditorHelper.override_font(rtl_is_main, "bold_font", "bold")
	PopochiuEditorHelper.override_font(rtl_is_main, "mono_font", "source")
	
	_check_if_first_room()
	info.hide()


func _set_info_text() -> void:
	_new_room_name = _name.to_snake_case()
	_target_folder = PopochiuResources.ROOMS_PATH.path_join(_new_room_name)
	
	info.text = (_info_text % _target_folder).replace("&n", _new_room_name)


#endregion

#region SetGet #####################################################################################
func set_show_set_as_main(value: bool) -> void:
	_show_set_as_main = value
	
	if is_instance_valid(set_as_main_panel):
		set_as_main_panel.visible = _show_set_as_main


#endregion

#region Private ####################################################################################
func _check_if_first_room() -> void:
	# Display a checkbox if no main scene has been defined for the project yet
	_show_set_as_main = ProjectSettings.get_setting(PopochiuResources.MAIN_SCENE, "").is_empty()


#endregion
