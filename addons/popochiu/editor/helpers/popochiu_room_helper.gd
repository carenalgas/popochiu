extends 'res://addons/popochiu/editor/helpers/popochiu_obj_base_helper.gd'
class_name PopochiuRoomHelper

const BASE_STATE_TEMPLATE := 'res://addons/popochiu/engine/templates/room_state_template.gd'
const BASE_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/room_template.gd'
const BASE_OBJ_PATH := 'res://addons/popochiu/engine/objects/room/popochiu_room.tscn'

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_path_template = _main_dock.ROOMS_PATH + '%s/room_%s'
	_obj_type = Constants.Types.ROOM
	_obj_type_label = 'room'
	_obj_type_target = 'rooms'


func create(obj_name: String, set_as_main:bool = false) -> PopochiuRoom:
	# TODO: Check if another Prop was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	_setup_name(obj_name)

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the room
	DirAccess.make_dir_absolute(_main_dock.ROOMS_PATH + _obj_script_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the state Resource for the room and a script so devs can add extra
	# properties to that state
	var state_template: Script = load(BASE_STATE_TEMPLATE).duplicate()
	if ResourceSaver.save(state_template, _obj_path + '_state.gd') != OK:
		push_error('[Popochiu] Could not create room state script: %s' %_obj_name)
		# TODO: Show feedback in the popup
		return

	var obj_resource: PopochiuRoomData = load(_obj_path + '_state.gd').new()
	obj_resource.script_name = _obj_name
	obj_resource.scene = _obj_path + '.tscn'
	obj_resource.resource_name = _obj_name
	
	if ResourceSaver.save(obj_resource, _obj_path + '.tres') != OK:
		push_error("[Popochiu] Couldn't create PopochiuRoomData for room: %s" % _obj_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the room
	var obj_script: Script = load(BASE_SCRIPT_TEMPLATE).duplicate()
	var new_code := obj_script.source_code
	
	obj_script.source_code = ''
	
	if ResourceSaver.save(obj_script, _obj_path + '.gd') != OK:
		push_error("[Popochiu] Couldn't create script: %s" % _obj_name)
		# TODO: Show feedback in the popup
		return
	
	new_code = new_code.replace(
		'room_state_template',
		'room_%s_state' % _obj_script_name
	)
	
	new_code = new_code.replace(
		'Data = null',
		"Data = load('%s.tres')" % _obj_path
	)
	
	obj_script = load(_obj_path + '.gd')
	obj_script.source_code = new_code

	if ResourceSaver.save(obj_script, _obj_path + '.gd') != OK:
		push_error('[Popochiu] Could not update script: %s' % _obj_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the room instance
	var obj: PopochiuRoom = load(BASE_OBJ_PATH).instantiate()
	
	# 	The script is assigned first so that other properties will not be
	# 	overwritten by that assignment.
	obj.set_script(load(_obj_path + '.gd'))
	
	obj.name = 'Room' + _obj_name
	obj.script_name = _obj_name
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Save the room scene (.tscn)
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(obj)
	if ResourceSaver.save(packed_scene, _obj_path + '.tscn') != OK:
		push_error("[Popochiu] Couldn't create room: %s" % _obj_name)
		# TODO: Show feedback in the popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Load the scene to be returned to the calling code
	# Instancing the created .tscn file fixes #58
	var obj_instance: PopochiuRoom = load(_obj_path + '.tscn').instantiate()


	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the object to Popochiu dock list, plus open it in the editor
	var row = _add_resource_to_popochiu()
	
	# Establecer como la escena principal
	# Changed _set_as_main_check.pressed to _set_as_main_check.button_pressed
	# in order to fix #56
	if set_as_main:
		_main_dock.set_main_scene(obj_resource.scene)
		row.is_main = true # So the Heart icon shows

	return obj_instance
