extends 'res://addons/popochiu/editor/factories/factory_base_popochiu_obj.gd'
class_name PopochiuCharacterFactory

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func _init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_type = Constants.Types.CHARACTER
	_obj_type_label = 'character'
	_obj_type_target = 'characters'
	_obj_path_template = _main_dock.CHARACTERS_PATH + '%s/character_%s'


func create(obj_name: String) -> int:
	# If everything goes well, this won't change.
	var result_code := ResultCodes.SUCCESS

	# Setup the class variables that depends on the object name
	_setup_name(obj_name)

	# Create the folder for the character
	result_code = _create_obj_folder()
	if result_code != ResultCodes.SUCCESS: return result_code
	
	# Create the state Resource for the character and a script
	# so devs can add extra properties to that state
	result_code = _create_state_resource()
	if result_code != ResultCodes.SUCCESS: return result_code
		
	# Create the script for the character
	# populating the template with the right references
	result_code = _create_script_from_template()
	if result_code != ResultCodes.SUCCESS: return result_code
		
	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the character instance
	var new_obj: PopochiuCharacter = _load_obj_base_scene()

	new_obj.name = 'Character' + _obj_pascal_name
	new_obj.script_name = _obj_pascal_name
	new_obj.description = _obj_pascal_name.capitalize()
	new_obj.cursor = Constants.CURSOR_TYPE.TALK
	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	
	# Save the character scene (.tscn)
	result_code = _save_obj_scene(new_obj)
	if result_code != ResultCodes.SUCCESS: return result_code
	
	# Add the object to Popochiu dock list, plus open it in the editor
	_add_resource_to_popochiu()
	
	return result_code
