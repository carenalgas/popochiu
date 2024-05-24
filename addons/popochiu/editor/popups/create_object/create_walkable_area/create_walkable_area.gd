@tool
extends "res://addons/popochiu/editor/popups/create_object/create_room_object.gd"
## Creates a new walkable area in a room.

var _new_walkable_area_name := ""
var _factory: PopochiuWalkableAreaFactory


#region Godot ######################################################################################
func _ready() -> void:
	_group_folder = "walkable_areas"
	_info_files = _info_files.replace("&t", "walkable_area")
	
	super()


#endregion

#region Virtual ####################################################################################
func _create() -> void:
	# Setup the region helper and use it to create the region --------------------------------------
	_factory = PopochiuWalkableAreaFactory.new()
	if _factory.create(_new_walkable_area_name, _room) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return
	
	# Open the properties of the created region in the inspector -----------------------------------
	# Done here because the creation is interactive in this case
	var walkable_area = _factory.get_obj_scene()
	await get_tree().create_timer(0.1).timeout
	
	PopochiuEditorHelper.select_node(walkable_area)


func _set_info_text() -> void:
	_new_walkable_area_name = _name.to_snake_case()
	_target_folder = _group_folder % _new_walkable_area_name
	info.text = _info_text.replace("&n", _new_walkable_area_name)


#endregion
