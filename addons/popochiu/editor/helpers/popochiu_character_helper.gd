extends 'res://addons/popochiu/editor/helpers/popochiu_obj_base_helper.gd'
class_name PopochiuCharacterHelper

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_type = Constants.Types.CHARACTER
	_obj_type_label = 'character'
	_obj_type_target = 'characters'
	_obj_path_template = _main_dock.CHARACTERS_PATH + '%s/character_%s'


func create(obj_name: String) -> PopochiuCharacter:
	# Setup the class variables that depends on the object name
	_setup_name(obj_name)

	# Create the folder for the character
	if _create_obj_folder() == ResultCodes.FAILURE: return
	
	# Create the state Resource for the character and a script so devs can add extra
	# properties to that state
	if _create_state_resource() == ResultCodes.FAILURE: return
	
	# Create the script for the character
	# populating the template with the right references
	if _create_script_from_template() == ResultCodes.FAILURE: return
	
	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the character instance
	var obj: PopochiuCharacter = _load_obj_base_scene()

	obj.name = 'Character' + _obj_name
	obj.script_name = _obj_name
	obj.description = _obj_name.capitalize()
	obj.cursor = Constants.CURSOR_TYPE.TALK
	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	
	# Save the character scene (.tscn)
	if _save_obj_scene(obj) == ResultCodes.FAILURE: return

	# Add the object to Popochiu dock list, plus open it in the editor
	_add_resource_to_popochiu()
	
	return _obj
	