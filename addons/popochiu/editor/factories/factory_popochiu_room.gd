extends 'res://addons/popochiu/editor/factories/factory_base_popochiu_obj.gd'
class_name PopochiuRoomFactory

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func _init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_type = Constants.Types.ROOM
	_obj_type_label = 'room'
	_obj_type_target = 'rooms'
	_obj_path_template = _main_dock.ROOMS_PATH + '%s/room_%s'


func create(obj_name: String, set_as_main:bool = false) -> PopochiuRoom:
	# Setup the class variables that depends on the object name
	_setup_name(obj_name)

	# Create the folder for the room
	if _create_obj_folder() == ResultCodes.FAILURE: return

	# Create the state Resource for the room and a script so devs can add extra
	# properties to that state
	if _create_state_resource() == ResultCodes.FAILURE: return

	# Create the script for the character
	# populating the template with the right references
	if _create_script_from_template() == ResultCodes.FAILURE: return

	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the room instance
	var obj: PopochiuRoom = _load_obj_base_scene()
	
	obj.name = 'Room' + _obj_name
	obj.script_name = _obj_name
	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	
	# Save the room scene (.tscn)
	if _save_obj_scene(obj) == ResultCodes.FAILURE: return

	# Add the object to Popochiu dock list, plus open it in the editor
	_add_resource_to_popochiu()
	
	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Set as main room
	# Changed _set_as_main_check.pressed to _set_as_main_check.button_pressed
	# in order to fix #56
	if set_as_main:
		_main_dock.set_main_scene(_obj.scene)
		_obj_dock_row.is_main = true # So the Heart icon shows
	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

	return _obj
