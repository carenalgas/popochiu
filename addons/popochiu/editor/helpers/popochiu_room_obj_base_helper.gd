extends 'res://addons/popochiu/editor/helpers/popochiu_obj_base_helper.gd'

# const BASE_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/prop_template.gd'
# const BASE_OBJ_PATH := 'res://addons/popochiu/engine/objects/prop/popochiu_prop.tscn'

const TabRoom := preload("res://addons/popochiu/editor/main_dock/tab_room.gd")

var _room_tab: VBoxContainer = null

var _room: Node2D = null
var _room_path := ''
var _room_dir := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(main_dock: Panel) -> void:
	super(main_dock)
	_room_tab = _main_dock.get_opened_room_tab()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _open_room(room: PopochiuRoom) -> void:
	_room = room
	_room_path = _room.scene_file_path
	_room_dir = _room_path.get_base_dir()
	# Adding room to room object path template
	_obj_path_template = _room_dir + _obj_path_template
