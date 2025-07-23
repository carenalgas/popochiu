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

## Returns true for inventory items (autoplay by default).
func _get_default_autoplay_behavior() -> bool:
	return true


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
		inventory_item.set_meta("ANIM_AUTOPLAY", tag.autoplays)

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
			_options
		)

		if item.get_meta("ANIM_AUTOPLAY", false):
			# If the item has autoplay enabled, set it up
			_animation_creator.setup_autoplay(item.get_meta("ANIM_NAME"))
		else:
			# Otherwise, ensure autoplay animation is unset
			_animation_creator.setup_autoplay(PopochiuEditorHelper.EMPTY_STRING)

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
	# Show inventory-item-related buttons if we are importing inventory items
	tag_row.show_inventory_item_buttons()


func _customize_filter_ui():
	# Show props-related buttons in the main bar if we are in a room
	%FilterSeparator.visible = true
	%AutoplaysBulk.visible = true


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


func _get_scene_path_for_tag(tag_name: String) -> String:
	if not tag_name:
		return PopochiuEditorHelper.EMPTY_STRING
	
	# For inventory items, we need to find the scene path from the resource
	var item_name: String = tag_name.to_pascal_case()
	var item_resource_path: String = PopochiuResources.get_data_value(
		"inventory_items",
		item_name,
		PopochiuEditorHelper.EMPTY_STRING
	)

	if item_resource_path.is_empty():
		PopochiuUtils.print_warning("No inventory item resource found for '%s'" % item_name)
		return PopochiuEditorHelper.EMPTY_STRING

	# Load the inventory item resource to get the scene path
	var item_resource = load(item_resource_path)
	if not item_resource:
		PopochiuUtils.print_warning("Failed to load inventory item resource for '%s'" % item_name)
		return PopochiuEditorHelper.EMPTY_STRING

	return item_resource.scene


#endregion

#region Protected ##################################################################################
## Selects the animation in the inventory item's AnimationPlayer.
## This involves opening the inventory item scene and then selecting the AnimationPlayer.
func _select_animation(tag_name: String) -> void:
	var item_name: String = tag_name.to_pascal_case()
	var scene_path: String = _get_scene_path_for_tag(tag_name)
	if scene_path.is_empty():
		PopochiuUtils.print_warning("No scene path found for inventory item '%s'" % item_name)
		return
	
	EditorInterface.open_scene_from_path(scene_path)

	# Wait a frame to ensure the scene is fully loaded
	await PopochiuEditorHelper.frame_processed()

	# Get the current scene root (should be the inventory item now)
	var item_scene_root: Node = EditorInterface.get_edited_scene_root()
	if not is_instance_valid(item_scene_root):
		PopochiuUtils.print_warning("Failed to get edited scene root for inventory item '%s'" % item_name)
		return

	# Find the AnimationPlayer in the inventory item scene
	var animation_player: AnimationPlayer = item_scene_root.get_node_or_null("AnimationPlayer")
	_handle_animation_in_player(tag_name, animation_player, HANDLE_ANIM_SELECT)


## Removes the animation for the given tag from the inventory item's AnimationPlayer.
func _delete_animation_for_tag(tag_name: String) -> void:
	var item_name: String = tag_name.to_pascal_case()
	var scene_path: String = _get_scene_path_for_tag(tag_name)
	if scene_path.is_empty():
		PopochiuUtils.print_warning("No scene path found for inventory item '%s'" % item_name)
		return

	# Load the scene without opening it in the editor
	var packed_scene: PackedScene = load(scene_path)
	if not packed_scene:
		PopochiuUtils.print_warning("Failed to load scene for inventory item '%s'" % item_name)
		return
	
	# Instance the scene to work with it in memory
	var item_scene_root: Node = packed_scene.instantiate()
	if not is_instance_valid(item_scene_root):
		PopochiuUtils.print_warning("Failed to instantiate scene for inventory item '%s'" % item_name)
		return

	# Find the AnimationPlayer in the inventory item scene
	var animation_player: AnimationPlayer = item_scene_root.get_node_or_null("AnimationPlayer")
	_handle_animation_in_player(tag_name, animation_player, HANDLE_ANIM_DELETE)

	PopochiuEditorHelper.pack_scene(item_scene_root)

	# Clean up the instance
	item_scene_root.queue_free()

#endregion