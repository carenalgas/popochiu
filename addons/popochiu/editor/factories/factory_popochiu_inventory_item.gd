extends 'res://addons/popochiu/editor/factories/factory_base_popochiu_obj.gd'
class_name PopochiuInventoryItemFactory

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func _init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_type = Constants.Types.INVENTORY_ITEM
	_obj_type_label = 'inventory_item'
	_obj_type_target = 'inventory_items'
	_obj_path_template = _main_dock.INVENTORY_ITEMS_PATH + '%s/item_%s'


func create(obj_name: String) -> PopochiuInventoryItem:
	# Setup the class variables that depends on the object name
	_setup_name(obj_name)

	# Create the folder for the item
	if _create_obj_folder() == ResultCodes.FAILURE: return

	# Create the state Resource for the item and a script so devs can add extra
	# properties to that state
	if _create_state_resource() == ResultCodes.FAILURE: return

	# Create the script for the character
	# populating the template with the right references
	if _create_script_from_template() == ResultCodes.FAILURE: return
	
	# ▓▓▓ LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the item instance
	var obj: PopochiuInventoryItem = _load_obj_base_scene()

	obj.name = 'Item' + _obj_name
	obj.script_name = _obj_name
	obj.description = _obj_name.capitalize()
	obj.cursor = Constants.CURSOR_TYPE.USE
	obj.size_flags_vertical = obj.SIZE_SHRINK_CENTER
	# ▓▓▓ END OF LOCAL CODE ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	
	# Save the item scene (.tscn)
	if _save_obj_scene(obj) == ResultCodes.FAILURE: return

	# Add the object to Popochiu dock list, plus open it in the editor
	_add_resource_to_popochiu()
	
	return _obj
