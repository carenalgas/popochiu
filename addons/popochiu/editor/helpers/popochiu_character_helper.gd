extends 'res://addons/popochiu/editor/helpers/popochiu_obj_base_helper.gd'
class_name PopochiuCharacterHelper

const BASE_STATE_TEMPLATE := 'res://addons/popochiu/engine/templates/character_state_template.gd'
const BASE_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/character_template.gd'
const BASE_OBJ_PATH := 'res://addons/popochiu/engine/objects/character/popochiu_character.tscn'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_path_template = _main_dock.CHARACTERS_PATH + '%s/character_%s'
	_obj_type = Constants.Types.CHARACTER
	_obj_type_label = 'character'
	_obj_type_target = 'characters'


func create(obj_name: String) -> PopochiuCharacter:
	# TODO: Check if another Prop was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	_setup_name(obj_name)

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the character
	DirAccess.make_dir_absolute(_main_dock.CHARACTERS_PATH + _obj_script_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the state Resource for the character and a script so devs can add extra
	# properties to that state
	var state_template: Script = load(BASE_STATE_TEMPLATE).duplicate()
	if ResourceSaver.save(state_template, _obj_path + '_state.gd') != OK:
		push_error('[Popochiu] Could not create character state script: %s' %_obj_name)
		# TODO: Show feedback in the popup
		return

	var obj_resource: PopochiuCharacterData = load(_obj_path + '_state.gd').new()
	obj_resource.script_name = _obj_name
	obj_resource.scene = _obj_path + '.tscn'
	obj_resource.resource_name = _obj_name
	
	if ResourceSaver.save(obj_resource, _obj_path + '.tres') != OK:
		push_error("[Popochiu] Couldn't create PopochiuCharacterData for character: %s" % _obj_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the character
	var obj_script: Script = load(BASE_SCRIPT_TEMPLATE).duplicate()
	var new_code := obj_script.source_code
	
	obj_script.source_code = ''
	
	if ResourceSaver.save(obj_script, _obj_path + '.gd') != OK:
		push_error("[Popochiu] Couldn't create script: %s" % _obj_name)
		# TODO: Show feedback in the popup
		return
	
	new_code = new_code.replace(
		'character_state_template',
		'character_%s_state' % _obj_script_name
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
	# Create the character instance
	var obj: PopochiuCharacter = load(BASE_OBJ_PATH).instantiate()
	
	# 	The script is assigned first so that other properties will not be
	# 	overwritten by that assignment.
	obj.set_script(load(_obj_path + '.gd'))
	
	obj.name = 'Character' + _obj_name
	obj.script_name = _obj_name
	obj.description = _obj_name.capitalize()
	obj.cursor = Constants.CURSOR_TYPE.TALK
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Save the character scene (.tscn)
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(obj)
	if ResourceSaver.save(packed_scene, _obj_path + '.tscn') != OK:
		push_error("[Popochiu] Couldn't create character: %s" % _obj_name)
		# TODO: Show feedback in the popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Load the scene to be returned to the calling code
	# Instancing the created .tscn file fixes #58
	var obj_instance: PopochiuCharacter = load(_obj_path + '.tscn').instantiate()


	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the object to Popochiu dock list, plus open it in the editor
	_add_resource_to_popochiu()
	
	return obj_instance
