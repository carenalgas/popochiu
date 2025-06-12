@tool
extends "res://addons/popochiu/editor/importers/aseprite/docks/aseprite_importer_dock.gd"

## Aseprite importer dock for Inventory Items.
## Allows importing multiple inventory items from a single Aseprite file.
## Each Aseprite tag becomes a separate inventory item with its animation.

var _animation_creator = preload(
	"res://addons/popochiu/editor/importers/aseprite/animation_creator_texture_rect.gd"
).new()


#region Public ######################################################################################
## Initialize the inventory importer dock.
func init():
	# Instantiate animation creator
	_animation_creator.init(_aseprite, file_system)

	super()


#endregion

#region Private ####################################################################################
## Handle the import process for inventory items.
func _on_import_pressed():
	# Set everything up
	# This will populate _root_node and _options class variables
	super()

	var result: int = RESULT_CODE.SUCCESS
	var created_items: Array[PopochiuInventoryItem] = []

	# Create an inventory item for each tag that must be imported
	for tag in _options.get("tags"):
		# Ignore unwanted tags
		if not tag.import: continue
			
		# Always convert to PascalCase as a standard
		var item_name: String = tag.tag_name.to_pascal_case()
		
		# Check if the inventory item already exists, if so load it instead of creating new
		var inventory_item = _get_existing_inventory_item(item_name)
		if inventory_item == null:
			# Create new inventory item if it doesn't exist
			inventory_item = _create_inventory_item(item_name)
			if inventory_item == null:
				result = RESULT_CODE.ERR_CANT_CREATE_OBJ_FOLDER
		
		inventory_item.set_meta("ANIM_NAME", tag.tag_name)
		created_items.append(inventory_item)
	
	# Import animations for each created item
	for item in created_items:
		if not item.has_meta("ANIM_NAME"): continue
		
		# Make the output folder match the item's folder
		_options.output_folder = item.scene_file_path.get_base_dir()
		
		# Import a single tag animation
		result = await _animation_creator.create_tag_animations(
			item,
			item.get_meta("ANIM_NAME"),
			_options,
			_animation_creator.AutoplayMode.TAG_NAME
		)
	
	# Save all created items
	for item in created_items:
		if not item.has_meta("ANIM_NAME"): 
			continue
		
		result = await _save_inventory_item(item)

	_importing = false

	if typeof(result) == TYPE_INT and result != RESULT_CODE.SUCCESS:
		PopochiuUtils.print_error(RESULT_CODE.get_error_message(result))
		_show_message("Some errors occurred. Please check output panel.", "Warning!")
	else:
		await get_tree().create_timer(0.1).timeout
		
		_show_message(
			"%d inventory items created." % [created_items.size()],
			"Done!"
		)


## Customize the tag UI for inventory items.
func _customize_tag_ui(tag_row: AnimationTagRow):
	# Inventory items don't need prop-specific buttons
	pass


## Create a new inventory item with the specified name.
func _create_inventory_item(name: String) -> PopochiuInventoryItem:
	var factory = PopochiuInventoryItemFactory.new()
	
	if factory.create(name) != ResultCodes.SUCCESS:
		return null

	return factory.get_obj_scene()


## Check if an inventory item with the given name already exists and load it.
## Returns the loaded inventory item scene or null if it doesn't exist.
func _get_existing_inventory_item(item_name: String) -> PopochiuInventoryItem:
	var item_res_path: String = PopochiuResources.get_data_value("inventory_items", item_name.to_snake_case(), PopochiuEditorHelper.EMPTY_STRING)
	if item_res_path == PopochiuEditorHelper.EMPTY_STRING:
		return null

	var packed_scene: PackedScene = load(load(item_res_path).scene)
	
	var inventory_item = packed_scene.instantiate()
	if not inventory_item is PopochiuInventoryItem:
		inventory_item.queue_free()
		return null
	
	return inventory_item


## Save the inventory item scene to disk.
func _save_inventory_item(item: PopochiuInventoryItem) -> int:
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(item)
	if ResourceSaver.save(packed_scene, item.scene_file_path) != OK:
		PopochiuUtils.print_error(
			"Couldn't save animations for inventory item %s at %s" %
			[item.name, item.scene_file_path]
		)
		return ResultCodes.ERR_CANT_SAVE_OBJ_SCENE
	return ResultCodes.SUCCESS


#endregion