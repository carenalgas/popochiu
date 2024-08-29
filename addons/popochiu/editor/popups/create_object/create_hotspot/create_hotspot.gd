@tool
extends "res://addons/popochiu/editor/popups/create_object/create_room_object.gd"
## Creates a new hotspot in the room.

var _new_hotspot_name := ""
var _factory: PopochiuHotspotFactory


#region Godot ######################################################################################
func _ready() -> void:
	_group_folder = "hotspots"
	_info_files = _info_files.replace("&t", "hotspot")
	
	super()


#endregion

#region Virtual ####################################################################################
func _create() -> Object:
	# Setup the region helper and use it to create the hotspot -------------------------------------
	_factory = PopochiuHotspotFactory.new()
	var param := PopochiuHotspotFactory.PopochiuHotspotFactoryParam.new()
	param.obj_name = _new_hotspot_name
	param.room = _room
	
	if _factory.create(param) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return null
	await get_tree().create_timer(0.1).timeout
	
	return _factory.get_obj_scene()


func _set_info_text() -> void:
	_new_hotspot_name = _name.to_snake_case()
	_target_folder = _group_folder % _new_hotspot_name
	info.text = _info_text.replace("&n", _new_hotspot_name)


#endregion
