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
var _obj_path_template := '' # always set by child class
var _obj_snake_name := ''
var _obj_pascal_name := ''
var _obj_path_base := ''
var _obj_path_scene = ''
var _obj_path_resource = ''
var _obj_path_state = ''
var _obj_path_script := ''
# The following variables are setup by the sub-class constructor
# to define the type of object to be processed
# TODO: reduce this to just "type", too much redundancy
var _obj_type := -1
var _obj_type_label := ''
var _obj_type_target := ''
# The following variable is needed because the room factory
# must set a property on the dock row if the room is the
# primary one.
# TODO: remove the need for this using signals #67
var _obj_dock_row: PopochiuObjectRow
# The following variables are references to the elements
# generated for the creation of the new Popochiu object,
# such as resources, scenes, scripts, state scripts, etc
var _obj_scene: Node
var _obj_resource: Resource
var _obj_state_resource: Resource
var _obj_script: Resource


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _init(main_dock: Panel) -> void:
	_main_dock = main_dock
	_ei = _main_dock.ei


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func get_obj_scene() -> Node:
	return _obj_scene


func get_obj_resource() -> Resource:
	return _obj_resource
	

func get_state_resource() -> Resource:
	return _obj_state_resource


func get_obj_script() -> Resource:
	return _obj_script

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░
func _setup_name(obj_name: String) -> void:
	_obj_pascal_name = obj_name.to_pascal_case()
	_obj_snake_name = obj_name.to_snake_case()
	_obj_path_base = _obj_path_template % [_obj_snake_name, _obj_snake_name]
	_obj_path_script = _obj_path_base + '.gd'
	_obj_path_state = _obj_path_base + '_state.gd'
	_obj_path_resource = _obj_path_base + '.tres'
	_obj_path_scene = _obj_path_base + '.tscn'


func _create_obj_folder() -> int:
	# TODO: Check if another object was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	if  DirAccess.make_dir_recursive_absolute(_obj_path_base.get_base_dir()) != OK:
		push_error(
			'[Popochiu] Could not create %s directory: %s' %
			[_obj_path_base.get_base_dir(), _obj_pascal_name]
		)
		return ResultCodes.ERR_CANT_CREATE_OBJ_FOLDER
	return ResultCodes.SUCCESS


func _create_state_resource() -> int:
	var state_template: Script = load(
		BASE_STATE_TEMPLATE % _obj_type_label
	).duplicate()
	if ResourceSaver.save(state_template, _obj_path_state) != OK:
		push_error(
			'[Popochiu] Could not create %s state script: %s' %
			[_obj_type_label, _obj_pascal_name]
		)
		return ResultCodes.FAILURE
	
	_obj_state_resource = load(_obj_path_state).new()
	_obj_state_resource.script_name = _obj_pascal_name
	_obj_state_resource.scene = _obj_path_scene
	_obj_state_resource.resource_name = _obj_pascal_name
	
	if ResourceSaver.save(_obj_state_resource, _obj_path_resource) != OK:
		push_error(
			"[Popochiu] Couldn't create PopochiuRoomData for %s: %s" %
			[_obj_type_label, _obj_pascal_name]
		)
		return ResultCodes.ERR_CANT_CREATE_OBJ_STATE
	
	return ResultCodes.SUCCESS


func _copy_script_template() -> int:
	var _obj_script: Script = load(
		BASE_SCRIPT_TEMPLATE % _obj_type_label
	).duplicate()

	if ResourceSaver.save(_obj_script, _obj_path_script) != OK:
		push_error(
			"[Popochiu] Couldn't create %s script: %s" %
			[_obj_type_label, _obj_path_script]
		)
		return ResultCodes.ERR_CANT_CREATE_OBJ_SCRIPT

	return ResultCodes.SUCCESS


func _create_script_from_template() -> int:
	var script_template_file = FileAccess.open(BASE_SCRIPT_TEMPLATE % _obj_type_label, FileAccess.READ)
	if script_template_file == null:
		push_error(
			"[Popochiu] Couldn't read script template from %s" %
			[BASE_SCRIPT_TEMPLATE % _obj_type_label]
		)
		return ResultCodes.ERR_CANT_OPEN_OBJ_SCRIPT_TEMPLATE
	var new_code: String = script_template_file.get_as_text()
	script_template_file.close()

	new_code = new_code.replace(
		'%s_state_template' % _obj_type_label,
		'%s_%s_state' % [_obj_type_label, _obj_snake_name]
	)

	new_code = new_code.replace(
		'Data = null',
		"Data = load('%s.tres')" % _obj_path_base
	)

	_obj_script = load(EMPTY_SCRIPT).duplicate()
	_obj_script.source_code = new_code

	if ResourceSaver.save(_obj_script, _obj_path_script) != OK:
		push_error(
			"[Popochiu] Couldn't create %s script: %s" %
			[_obj_type_label, _obj_path_script]
		)
		return ResultCodes.ERR_CANT_CREATE_OBJ_SCRIPT

	return ResultCodes.SUCCESS


func _save_obj_scene(obj: Node) -> int:
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(obj)
	if ResourceSaver.save(packed_scene, _obj_path_scene) != OK:
		push_error(
			"[Popochiu] Couldn't create %s: %s" %
			[_obj_type_label, _obj_path_script]
		)
		return ResultCodes.ERR_CANT_SAVE_OBJ_SCENE

	# Load the scene to be returned to the calling code
	# Instancing the created .tscn file fixes #58
	_obj_scene = load(_obj_path_scene).instantiate()
	
	return ResultCodes.SUCCESS


func _save_obj_resource(obj: Resource) -> int:
	# Save dialog resource (local code because it's not a scene)
	if ResourceSaver.save(obj, _obj_path_resource) != OK:
		push_error(
			"[Popochiu] Couldn't create %s: %s" %
			[_obj_type_label, _obj_pascal_name]
		)
		return ResultCodes.ERR_CANT_SAVE_OBJ_RESOURCE
	
	# Load the scene to be returned to the calling code
	# Instancing the created .tscn file fixes #58
	_obj_resource = load(_obj_path_resource)

	return ResultCodes.SUCCESS
	

func _load_obj_base_scene() -> Node:
	var obj = load(
		BASE_SCENE_PATH % [_obj_type_label, _obj_type_label]
	).instantiate()

	# 	The script is assigned first so that other properties will not be
	# 	overwritten by that assignment.
	if _obj_script != null:
		obj.set_script(load(_obj_path_script))

	return obj


func _add_resource_to_popochiu() -> void:
	# Add the created obj to Popochiu's correct list
	if _main_dock.add_resource_to_popochiu(
		_obj_type_target,
		ResourceLoader.load(_obj_path_resource)
	) != OK:
		push_error(
			"[Popochiu] Couldn't add the created %s to Popochiu: %s" %
			[_obj_type_label, _obj_pascal_name]
		)
		return

	# Add the room to the proper singleton
	PopochiuResources.update_autoloads(true)

	# Update the related list in the dock
	_obj_dock_row = (_main_dock as MainDock).add_to_list(
		_obj_type, _obj_pascal_name
	)
