@tool
extends "res://addons/popochiu/editor/popups/create_object/create_room_object.gd"
## Allows you to create a new Region for a room.

var _new_region_name := ""
var _factory: PopochiuRegionFactory


#region Godot ######################################################################################
func _ready() -> void:
	_group_folder = "regions"
	_info_files = _info_files.replace("&t", "region")
	
	super()


#endregion

#region Virtual ####################################################################################
func _create() -> Object:
	if _new_region_name.is_empty():
		error_feedback.show()
		return null
	
	# Setup the region helper and use it to create the region --------------------------------------
	_factory = PopochiuRegionFactory.new()
	var param := PopochiuRegionFactory.PopochiuRegionFactoryParam.new()
	param.obj_name = _new_region_name
	param.room = _room
	
	if _factory.create(param) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return null
	await get_tree().create_timer(0.1).timeout
	
	return _factory.get_obj_scene()


func _set_info_text() -> void:
	_new_region_name = _name.to_snake_case()
	_target_folder = _group_folder % _new_region_name
	info.text = _info_text.replace("&n", _new_region_name)


#endregion
