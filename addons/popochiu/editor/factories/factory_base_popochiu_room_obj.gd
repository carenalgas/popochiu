class_name PopochiuRoomObjFactory
extends "res://addons/popochiu/editor/factories/factory_base_popochiu_obj.gd"

const CHILD_VISIBLE_IN_ROOM_META = "_popochiu_obj_factory_child_visible_in_room_"

# The following variable is setup by the sub-class constructor to
# define the holder node for the new room object (Props, Hotspots, etc)
var _obj_room_group := ""
# The following variables are setup by the _setup_room method
var _room: Node2D = null
var _room_path := ""
var _room_dir := ""


#region Public #####################################################################################
func get_group() -> String:
	return _obj_room_group


func create_from(node: Node, room: PopochiuRoom) -> int:
	_setup_room(room)
	_setup_name(node.name)
	
	var param := _get_param(node)
	param.room = room
	param.obj_name = node.name
	param.is_visible = node.visible
	param.should_setup_room_and_name = false
	param.should_add_to_room = false
	param.should_create_script = !FileAccess.file_exists(_path_script)
	
	return call("create", param)


func get_new_instance() -> PopochiuRoomObjFactory:
	return new()


#endregion

#region Private ####################################################################################
func _setup_room(room: PopochiuRoom) -> void:
	_room = room
	_room_path = _room.scene_file_path
	_room_dir = _room_path.get_base_dir()
	# Adding room path to room object path template
	_path_template = _room_dir + _path_template


# This function adds a child to the new object scene
# marking it as "visible in room scene"
func _add_visible_child(child: Node) -> void:
	child.set_meta(CHILD_VISIBLE_IN_ROOM_META, true)
	_scene.add_child(child)


func _add_resource_to_room() -> void:
	# Add the newly created obj to its room
	_room.get_node(_obj_room_group).add_child(_scene)

	# Set the ownership for the node plus all it's children
	# (this address colliders, polygons, etc)
	_scene.owner = _room
	for child in _scene.get_children():
		if child.has_meta(CHILD_VISIBLE_IN_ROOM_META):
			child.owner = _room
			child.remove_meta(CHILD_VISIBLE_IN_ROOM_META)

	# Center the object on the scene
	_scene.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0

	# Save the room scene (it's open in the editor)
	EditorInterface.save_scene()


func _get_param(_node: Node) -> PopochiuRoomObjFactoryParam:
	return PopochiuRoomObjFactoryParam.new()


#endregion

#region Subclass ###################################################################################
class PopochiuRoomObjFactoryParam extends RefCounted:
	var obj_name: String
	var room: PopochiuRoom
	var is_visible := true
	var should_setup_room_and_name := true
	var should_create_script := true
	var should_add_to_room := true
	## Property used to store the vectors stored in the [member CollisionPolygon2D.polygon] for
	## [PopochiuProp], [PopochiuHotspot], and [PopochiuRegion].
	var interaction_polygon := PackedVector2Array()


#endregion
