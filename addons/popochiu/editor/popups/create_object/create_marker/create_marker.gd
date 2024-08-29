@tool
extends "res://addons/popochiu/editor/popups/create_object/create_room_object.gd"
# Creates a new marker in the room.

var _new_marker_name := ""
var _factory: PopochiuMarkerFactory


#region Godot ######################################################################################
func _ready() -> void:
	_group_folder = "markers"
	_info_files = "[code]- marker_&n.tscn[/code]"
	
	super()


#endregion

#region Virtual ####################################################################################
func _create() -> Object:
	# Setup the region helper and use it to create the marker 
	_factory = PopochiuMarkerFactory.new()
	var param := PopochiuMarkerFactory.PopochiuRoomObjFactoryParam.new()
	param.obj_name = _new_marker_name
	param.room = _room
	
	if _factory.create(param) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return null
	await get_tree().create_timer(0.1).timeout
	
	return _factory.get_obj_scene()


func _set_info_text() -> void:
	_new_marker_name = _name.to_snake_case()
	_target_folder = _group_folder % _new_marker_name
	info.text = _info_text.replace("&n", _new_marker_name)


#endregion
