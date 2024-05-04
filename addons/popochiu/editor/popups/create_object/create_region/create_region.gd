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
func _create() -> void:
	if _new_region_name.is_empty():
		error_feedback.show()
		return
	
	# Setup the region helper and use it to create the region --------------------------------------
	_factory = PopochiuRegionFactory.new()
	if _factory.create(_new_region_name, _room) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return
	
	# Open the properties of the created region in the inspector -----------------------------------
	# Done here because the creation is interactive in this case
	var region = _factory.get_obj_scene()
	await get_tree().create_timer(0.1).timeout
	
	PopochiuEditorHelper.select_node(region)


func _set_info_text() -> void:
	_new_region_name = _name.to_snake_case()
	_target_folder = _group_folder % _new_region_name
	info.text = _info_text.replace("&n", _new_region_name)


#endregion
