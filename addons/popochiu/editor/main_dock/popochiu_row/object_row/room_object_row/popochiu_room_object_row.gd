@tool
extends "res://addons/popochiu/editor/main_dock/popochiu_row/object_row/popochiu_object_row.gd"

const PROP_TEMPLATE = "res://addons/popochiu/engine/templates/prop_template.gd"

var node_path := ""


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	if not FileAccess.file_exists(path.replace(".tscn", ".gd")):
		btn_script.hide()
	
	btn_state.hide()
	btn_state_script.hide()


#endregion

#region Virtual ####################################################################################
func _get_location() -> String:
	# Structure of path: "res://game/rooms/room_name/props/prop_name/"
	# path splitted: [res:, popochiu, rooms, room_name, props, prop_name]
	return "Room%s" % (path.split("/", false)[3]).to_pascal_case()


#endregion

#region Private ####################################################################################
func _remove_from_core() -> void:
	var room_child_to_free: Node = null
	
	if EditorInterface.get_edited_scene_root() is PopochiuRoom:
		var opened_room: PopochiuRoom = EditorInterface.get_edited_scene_root()
		match type:
			PopochiuResources.Types.PROP:
				room_child_to_free = opened_room.get_prop(str(name))
			PopochiuResources.Types.HOTSPOT:
				room_child_to_free = opened_room.get_hotspot(str(name))
			PopochiuResources.Types.MARKER:
				room_child_to_free = opened_room.get_marker(str(name))
			PopochiuResources.Types.REGION:
				room_child_to_free = opened_room.get_region(str(name))
			PopochiuResources.Types.WALKABLE_AREA:
				room_child_to_free = opened_room.get_walkable_area(str(name))
	
	# Continue with the deletion flow
	super()
	
	# Fix #196: Remove the Node from the Room tree once the folder of the object has been deleted
	# from the FileSystem (this applies to Props, Hotspots, Walkable areas and Regions).
	if room_child_to_free:
		room_child_to_free.queue_free()
	
	EditorInterface.save_scene()


#endregion
