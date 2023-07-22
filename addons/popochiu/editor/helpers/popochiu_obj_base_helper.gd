extends RefCounted

# const BASE_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/prop_template.gd'
# const BASE_OBJ_PATH := 'res://addons/popochiu/engine/objects/prop/popochiu_prop.tscn'

const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const MainDock := preload('res://addons/popochiu/editor/main_dock/popochiu_dock.gd')
const PopochiuObjectRow := preload('res://addons/popochiu/editor/main_dock/object_row/popochiu_object_row.gd')

var _main_dock: Panel = null
var _ei: EditorInterface

var _obj_script_name := ''
var _obj_name := ''
var _obj_path := ''
var _obj_path_template := ''
# TODO: reduce this to just "type", too much redundancy
var _obj_type := -1
var _obj_type_label := ''
var _obj_type_target := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(main_dock: Panel) -> void:
	_main_dock = main_dock
	_ei = _main_dock.ei


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░
func _setup_name(obj_name: String) -> void:
	_obj_name = obj_name.to_pascal_case()
	_obj_script_name = obj_name.to_snake_case()
	_obj_path = _obj_path_template % [_obj_script_name, _obj_script_name]


func _add_resource_to_popochiu() -> PopochiuObjectRow:
	# Add the created obj to Popochiu's rooms list
	if _main_dock.add_resource_to_popochiu(
		_obj_type_target,
		ResourceLoader.load(_obj_path + '.tres')
	) != OK:
		push_error(
			"[Popochiu] Couldn't add the created %s to Popochiu: %s" % 
			[_obj_type_label, _obj_name]
		)
		return
	
	# Add the room to the proper singleton
	PopochiuResources.update_autoloads(true)
	
	# Update the related list in the dock
	var row := (_main_dock as MainDock).add_to_list(
		_obj_type, _obj_name
	)

	return row
