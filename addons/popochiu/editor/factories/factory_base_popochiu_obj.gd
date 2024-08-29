extends RefCounted

const BASE_STATE_TEMPLATE := "res://addons/popochiu/engine/templates/%s_state_template.gd"
const BASE_SCRIPT_TEMPLATE := "res://addons/popochiu/engine/templates/%s_template.gd"
const BASE_SCENE_PATH := "res://addons/popochiu/engine/objects/%s/popochiu_%s.tscn"
const EMPTY_SCRIPT := "res://addons/popochiu/engine/templates/empty_script_template.gd"

# The following variables are setup on creation Names variants and name parameter passed to the
# create method.
var _path_template := "" # always set by child class
var _snake_name := ""
var _pascal_name := ""
var _path_base := ""
var _path_scene = ""
var _path_resource = ""
var _path_state = ""
var _path_script := ""
# The following variables are setup by the sub-class constructor to define the type of object to be
# processed
# TODO: reduce this to just "type", too much redundancy
var _type := -1
var _type_label := ""
var _type_target := ""
var _type_method: Callable
# The following variables are references to the elements generated for the creation of the new
# Popochiu object, such as resources, scenes, scripts, state scripts, etc
var _scene: Node
var _resource: Resource
var _state_resource: Resource
var _script: Resource


#region Public #####################################################################################
func get_obj_scene() -> Node:
	return _scene


func get_snake_name() -> String:
	return _snake_name


func get_obj_resource() -> Resource:
	return _resource
	

func get_state_resource() -> Resource:
	return _state_resource


func get_obj_script() -> Resource:
	return _script


func get_scene_path() -> String:
	return _path_scene


func get_type() -> int:
	return _type


func get_type_method() -> Callable:
	return _type_method


#endregion

#region Private ####################################################################################
func _setup_name(obj_name: String) -> void:
	_pascal_name = obj_name.to_pascal_case()
	_snake_name = obj_name.to_snake_case()
	_path_base = _path_template % [_snake_name, _snake_name]
	_path_script = _path_base + ".gd"
	_path_state = _path_base + "_state.gd"
	_path_resource = _path_base + ".tres"
	_path_scene = _path_base + ".tscn"


func _create_obj_folder() -> int:
	# TODO: Remove created files if the creation process failed.
	if  DirAccess.make_dir_recursive_absolute(_path_base.get_base_dir()) != OK:
		PopochiuUtils.print_error(
			"Could not create %s directory: %s" %
			[_path_base.get_base_dir(), _pascal_name]
		)
		return ResultCodes.ERR_CANT_CREATE_OBJ_FOLDER
	return ResultCodes.SUCCESS


func _create_state_resource() -> int:
	var state_template: Script = load(
		BASE_STATE_TEMPLATE % _type_label
	).duplicate()

	if ResourceSaver.save(state_template, _path_state) != OK:
		PopochiuUtils.print_error(
			"Could not create %s state script: %s" %
			[_type_label, _pascal_name]
		)
		return ResultCodes.FAILURE
	
	_state_resource = load(_path_state).new()
	_state_resource.script_name = _pascal_name
	_state_resource.scene = _path_scene
	_state_resource.resource_name = _pascal_name
	
	if ResourceSaver.save(_state_resource, _path_resource) != OK:
		PopochiuUtils.print_error(
			"Could not create state resource for %s: %s" %
			[_type_label, _pascal_name]
		)
		return ResultCodes.ERR_CANT_CREATE_OBJ_STATE
	
	return ResultCodes.SUCCESS


func _copy_script_template() -> int:
	var _script: Script = load(
		BASE_SCRIPT_TEMPLATE % _type_label
	).duplicate()

	if ResourceSaver.save( _script, _path_script) != OK:
		PopochiuUtils.print_error(
			"Could not create %s script: %s" %
			[_type_label, _path_script]
		)
		return ResultCodes.ERR_CANT_CREATE_OBJ_SCRIPT

	return ResultCodes.SUCCESS


## Create the script for the object based on the template of its type.
func _create_script_from_template() -> int:
	var script_template_file = FileAccess.open(
		BASE_SCRIPT_TEMPLATE % _type_label, FileAccess.READ
	)
	
	if script_template_file == null:
		PopochiuUtils.print_error(
			"Could not read script template from %s" %
			[BASE_SCRIPT_TEMPLATE % _type_label]
		)
		return ResultCodes.ERR_CANT_OPEN_OBJ_SCRIPT_TEMPLATE
	
	var new_code: String = script_template_file.get_as_text()
	script_template_file.close()

	new_code = new_code.replace(
		"%s_state_template" % _type_label,
		"%s_%s_state" % [_type_label, _snake_name]
	)

	new_code = new_code.replace(
		"Data = null",
		'Data = load("%s.tres")' % _path_base
	)

	_script = load(EMPTY_SCRIPT).duplicate()
	_script.source_code = new_code

	if ResourceSaver.save( _script, _path_script) != OK:
		PopochiuUtils.print_error(
			"Could not create %s script: %s" %
			[_type_label, _path_script]
		)
		return ResultCodes.ERR_CANT_CREATE_OBJ_SCRIPT

	return ResultCodes.SUCCESS


func _save_obj_scene(obj: Node) -> int:
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(obj)
	if ResourceSaver.save(packed_scene, _path_scene) != OK:
		PopochiuUtils.print_error(
			"Could not create %s: %s" %
			[_type_label, _path_script]
		)
		return ResultCodes.ERR_CANT_SAVE_OBJ_SCENE
	# Load the scene to be get by the calling code
	# Instancing the created .tscn file fixes #58
	_scene = (load(_path_scene) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	
	return ResultCodes.SUCCESS


func _save_obj_resource(obj: Resource) -> int:
	if ResourceSaver.save(obj, _path_resource) != OK:
		PopochiuUtils.print_error(
			"Could not create %s: %s" %
			[_type_label, _pascal_name]
		)
		return ResultCodes.ERR_CANT_SAVE_OBJ_RESOURCE
	
	# Load the resource to be get by the calling code
	_resource = load(_path_resource)

	return ResultCodes.SUCCESS


## Makes a copy of the base scene for the object (e.g. popochiu_room.tscn,
## popochiu_inventory_item.tscn, popochiu_prop.tscn).
func _load_obj_base_scene() -> Node:
	var obj = (
		load(BASE_SCENE_PATH % [_type_label, _type_label]) as PackedScene
	).instantiate(PackedScene.GEN_EDIT_STATE_MAIN_INHERITED)

	# 	The script is assigned first so that other properties will not be
	# 	overwritten by that assignment.
	if _script != null:
		obj.set_script(load(_path_script))
	
	return obj


func _add_resource_to_popochiu() -> void:
	# Add the created obj to Popochiu's correct list
	var resource := ResourceLoader.load(_path_resource)
	if PopochiuResources.set_data_value(
		_type_target,
		resource.script_name,
		resource.resource_path
	) != OK:
		PopochiuUtils.print_error(
			"Could not add the created %s to Popochiu: %s" %
			[_type_label, _pascal_name]
		)
		return

	# Add the object to the proper singleton
	PopochiuResources.update_autoloads(true)

	# Update the related list in the dock
	PopochiuEditorHelper.signal_bus.main_object_added.emit(_type, _pascal_name)


#endregion
