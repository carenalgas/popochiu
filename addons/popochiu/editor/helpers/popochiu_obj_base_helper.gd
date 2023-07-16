extends RefCounted

# const BASE_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/prop_template.gd'
# const BASE_OBJ_PATH := 'res://addons/popochiu/engine/objects/prop/popochiu_prop.tscn'

const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const MainDock := preload('res://addons/popochiu/editor/main_dock/popochiu_dock.gd')

var _main_dock: Panel = null
var _ei: EditorInterface

var _obj_script_name := ''
var _obj_name := ''
var _obj_path := ''
var _obj_path_template := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(main_dock: Panel) -> void:
	_main_dock = main_dock
	_ei = _main_dock.ei


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░
func _setup_name(obj_name: String) -> void:
	_obj_name = obj_name.to_pascal_case()
	_obj_script_name = obj_name.to_snake_case()
	_obj_path = _obj_path_template % [_obj_script_name, _obj_script_name]
