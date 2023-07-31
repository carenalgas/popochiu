extends RefCounted

const BASE_STATE_TEMPLATE := 'res://addons/popochiu/engine/templates/%s_state_template.gd'
const BASE_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/%s_template.gd'
const BASE_SCENE_PATH := 'res://addons/popochiu/engine/objects/%s/popochiu_%s.tscn'
const EMPTY_SCRIPT := 'res://addons/popochiu/engine/templates/empty_script_template.gd'

const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const MainDock := preload('res://addons/popochiu/editor/main_dock/popochiu_dock.gd')
const PopochiuObjectRow := preload('res://addons/popochiu/editor/main_dock/object_row/popochiu_object_row.gd')

var _main_dock: Panel = null
var _ei: EditorInterface

# The following variables are setup on creation
# Names variants and name parameter passed to
# the create method.
var _obj_script_name := ''
var _obj_name := ''
var _obj_path := ''
var _obj_path_template := ''
var _obj_script_path := ''
# The following variables are setup by the sub-class constructor
# to define the type of object to be processed
# TODO: reduce this to just "type", too much redundancy
var _obj_type := -1
var _obj_type_label := ''
var _obj_type_target := ''
# The following variables are references to the elements
# generated for the creation of the new Popochiu object,
# such as resources, scenes, scripts, state scripts, etc
var _obj: Node # Can be a scene or a simple node in the tree
var _obj_state_resource: Resource
var _obj_script: Resource
var _obj_dock_row: PopochiuObjectRow


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func _init(main_dock: Panel) -> void:
	_main_dock = main_dock
	_ei = _main_dock.ei


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░
func _setup_name(obj_name: String) -> void:
	_obj_name = obj_name.to_pascal_case()
	_obj_script_name = obj_name.to_snake_case()
	_obj_path = _obj_path_template % [_obj_script_name, _obj_script_name]
	_obj_script_path = _obj_path + '.gd'


func _add_resource_to_popochiu() -> void:
	# Add the created obj to Popochiu's correct list
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
	_obj_dock_row = (_main_dock as MainDock).add_to_list(
		_obj_type, _obj_name
	)


func _create_obj_folder() -> int:
	# TODO: Check if another object was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	if  DirAccess.make_dir_recursive_absolute(_obj_path.get_base_dir()) != OK:
		push_error(
			'[Popochiu] Could not create %s directory: %s' %
			[_obj_path.get_base_dir(), _obj_name]
		)
		return ResultCodes.FAILURE
	return ResultCodes.SUCCESS


func _create_state_resource() -> int:
	var state_template: Script = load(
		BASE_STATE_TEMPLATE % _obj_type_label
	).duplicate()
	if ResourceSaver.save(state_template, _obj_path + '_state.gd') != OK:
		push_error(
			'[Popochiu] Could not create %s state script: %s' %
			[_obj_type_label, _obj_name]
		)
		# TODO: Show feedback in the popup via signals/signalbus
		return ResultCodes.FAILURE
	
	_obj_state_resource = load(_obj_path + '_state.gd').new()
	_obj_state_resource.script_name = _obj_name
	_obj_state_resource.scene = _obj_path + '.tscn'
	_obj_state_resource.resource_name = _obj_name
	
	if ResourceSaver.save(_obj_state_resource, _obj_path + '.tres') != OK:
		push_error(
			"[Popochiu] Couldn't create PopochiuRoomData for %s: %s" %
			[_obj_type_label, _obj_name]
		)
		# TODO: Show feedback in the popup via signals/signalbus
		return ResultCodes.FAILURE
	
	return ResultCodes.SUCCESS


func _copy_script_template() -> int:
	var _obj_script: Script = load(
		BASE_SCRIPT_TEMPLATE % _obj_type_label
	).duplicate()

	if ResourceSaver.save(_obj_script, _obj_script_path) != OK:
		push_error(
			"[Popochiu] Couldn't create %s script: %s" %
			[_obj_type_label, _obj_script_path]
		)
		# TODO: Show feedback in the popup via signals/signalbus
		return ResultCodes.FAILURE

	return ResultCodes.SUCCESS


func _create_script_from_template() -> int:
	var script_template_file = FileAccess.open(BASE_SCRIPT_TEMPLATE % _obj_type_label, FileAccess.READ)
	if script_template_file == null:
		push_error(
			"[Popochiu] Couldn't read script template from %s" %
			[BASE_SCRIPT_TEMPLATE % _obj_type_label]
		)
		# TODO: Show feedback in the popup via signals/signalbus
		return ResultCodes.FAILURE
	var new_code: String = script_template_file.get_as_text()
	script_template_file.close()

	new_code = new_code.replace(
		'%s_state_template' % _obj_type_label,
		'%s_%s_state' % [_obj_type_label, _obj_script_name]
	)

	new_code = new_code.replace(
		'Data = null',
		"Data = load('%s.tres')" % _obj_path
	)

	_obj_script = load(EMPTY_SCRIPT).duplicate()
	_obj_script.source_code = new_code

	if ResourceSaver.save(_obj_script, _obj_script_path) != OK:
		push_error(
			"[Popochiu] Couldn't create %s script: %s" %
			[_obj_type_label, _obj_script_path]
		)
		# TODO: Show feedback in the popup via signals/signalbus
		return ResultCodes.FAILURE

	return ResultCodes.SUCCESS


func _save_obj_scene(obj: Node) -> int:
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(obj)
	if ResourceSaver.save(packed_scene, _obj_path + '.tscn') != OK:
		push_error(
			"[Popochiu] Couldn't create %s: %s" %
			[_obj_type_label, _obj_path + '.gd']
		)
		# TODO: Show feedback in the popup via signals/signalbus
		return ResultCodes.FAILURE

	# Load the scene to be returned to the calling code
	# Instancing the created .tscn file fixes #58
	_obj = load(_obj_path + '.tscn').instantiate()
	
	return ResultCodes.SUCCESS


func _load_obj_base_scene() -> Node:
	var obj = load(
		BASE_SCENE_PATH % [_obj_type_label, _obj_type_label]
	).instantiate()

	# 	The script is assigned first so that other properties will not be
	# 	overwritten by that assignment.
	if _obj_script != null:
		obj.set_script(load(_obj_script_path))

	return obj
