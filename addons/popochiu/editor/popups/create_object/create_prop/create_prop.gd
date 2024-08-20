@tool
extends "res://addons/popochiu/editor/popups/create_object/create_room_object.gd"
## Allows you to create a new Prop for a room.
## 
## If it has interaction, it will be assigned a script that will be saved in the prop's folder.

var _new_prop_name := ""
var _factory: PopochiuPropFactory

@onready var interaction_checkbox: CheckBox = %InteractionCheckbox


#region Godot ######################################################################################
func _ready() -> void:
	_group_folder = "props"
	_info_files = _info_files.replace("&t", "prop")
	
	super()
	
	# Connect to childrens' signals
	interaction_checkbox.toggled.connect(_interaction_toggled)


#endregion

#region Virtual ####################################################################################
func _create() -> Object:
	if _new_prop_name.is_empty():
		error_feedback.show()
		return null
	
	# Setup the prop helper and use it to create the prop ------------------------------------------
	_factory = PopochiuPropFactory.new()
	var param := PopochiuPropFactory.PopochiuPropFactoryParam.new()
	param.obj_name = _new_prop_name
	param.room = _room
	param.is_interactive = interaction_checkbox.button_pressed
	
	if _factory.create(param) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return null
	await get_tree().create_timer(0.1).timeout
	
	return _factory.get_obj_scene()


func _set_info_text() -> void:
	_new_prop_name = _name.to_snake_case()
	_target_folder = _group_folder % _new_prop_name
	
	_update_info()


#endregion

#region Private ####################################################################################
func _interaction_toggled(is_pressed: bool) -> void:
	if is_pressed and not _name.is_empty():
		_update_info()
	else:
		info.text = ""
	
	_info_updated()


func _update_info() -> void:
	info.text = _info_text.replace("&n", _new_prop_name)


#endregion
