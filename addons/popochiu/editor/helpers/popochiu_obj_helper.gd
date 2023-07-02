extends RefCounted

# const BASE_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/prop_template.gd'
# const BASE_OBJ_PATH := 'res://addons/popochiu/engine/objects/prop/popochiu_prop.tscn'

const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const TabRoom := preload("res://addons/popochiu/editor/main_dock/tab_room.gd")

var _room_tab: VBoxContainer = null
var _ei: EditorInterface

var _room: Node2D = null
var _room_path := ''
var _room_dir := ''

var _obj_script_name := ''
var _obj_name := ''
var _obj_path := ''
var _obj_path_template := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░

func init(_main_dock: Panel) -> void:
	_ei = _main_dock.ei
	_room_tab = _main_dock.get_opened_room_tab()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░
func create(obj_name: String, room: PopochiuRoom, is_interactive:bool = false):
	pass

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _open_room(room: PopochiuRoom) -> void:
	_room = room
	_room_path = _room.scene_file_path
	_room_dir = _room_path.get_base_dir()
	
	
func _setup_name(obj_name: String) -> void:
	_obj_name = obj_name.to_pascal_case()
	_obj_script_name = obj_name.to_snake_case()
	_obj_path_template = _room_dir + _obj_path_template
	_obj_path = _obj_path_template % [_obj_script_name, _obj_script_name]
