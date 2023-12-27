extends 'res://addons/popochiu/editor/factories/factory_base_popochiu_obj.gd'

const CHILD_VISIBLE_IN_ROOM_META = '_popochiu_obj_factory_child_visible_in_room_'
const TabRoom := preload("res://addons/popochiu/editor/main_dock/tab_room.gd")

var _room_tab: VBoxContainer = null

# The following variable is setup by the sub-class constructor to
# define the holder node for the new room object (Props, Hotspots, etc)
var _obj_room_group := ''
# The following variables are setup by the _setup_room method
var _room: Node2D = null
var _room_path := ''
var _room_dir := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func _init(main_dock: Panel) -> void:
	super(main_dock)
	_room_tab = _main_dock.get_opened_room_tab()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
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
