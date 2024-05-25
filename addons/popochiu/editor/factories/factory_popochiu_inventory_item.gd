extends "res://addons/popochiu/editor/factories/factory_base_popochiu_obj.gd"
class_name PopochiuInventoryItemFactory

#region Godot ######################################################################################
func _init() -> void:
	_type = PopochiuResources.Types.INVENTORY_ITEM
	_type_label = "inventory_item"
	_type_target = "inventory_items"
	_path_template = PopochiuResources.INVENTORY_ITEMS_PATH.path_join("%s/inventory_item_%s")


#endregion

#region Public #####################################################################################
func create(obj_name: String) -> int:
	# If everything goes well, this won't change.
	var result_code := ResultCodes.SUCCESS

	# Setup the class variables that depends on the object name
	_setup_name(obj_name)

	# Create the folder
	result_code = _create_obj_folder()
	if result_code != ResultCodes.SUCCESS: return result_code
	
	# Create the state Resource and a script
	# so devs can add extra properties to that state
	result_code = _create_state_resource()
	if result_code != ResultCodes.SUCCESS: return result_code
		
	# Create the script populating the template with the right references
	result_code = _create_script_from_template()
	if result_code != ResultCodes.SUCCESS: return result_code
	
	# ---- LOCAL CODE ------------------------------------------------------------------------------
	# Create the instance
	var new_obj: PopochiuInventoryItem = _load_obj_base_scene()

	new_obj.name = "Item" + _pascal_name
	new_obj.script_name = _pascal_name
	new_obj.description = _pascal_name.capitalize()
	new_obj.cursor = PopochiuResources.CURSOR_TYPE.USE
	new_obj.size_flags_vertical = new_obj.SIZE_SHRINK_CENTER

	if PopochiuConfig.is_pixel_art_textures():
		new_obj.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# ---- END OF LOCAL CODE -----------------------------------------------------------------------
	
	# Save the scene (.tscn)
	result_code = _save_obj_scene(new_obj)
	if result_code != ResultCodes.SUCCESS: return result_code

	# Add the object to Popochiu dock list, plus open it in the editor
	_add_resource_to_popochiu()
	
	return result_code


#endregion
