@tool
class_name PopochiuMigration6
extends PopochiuMigration

const VERSION = 6
const DESCRIPTION = "Add AnimationPlayer nodes to all inventory items"
const STEPS = [
	"Add AnimationPlayer child nodes to existing inventory items",
]


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_add_animation_players_to_inventory_items
		]
	)


#endregion

#region Private ####################################################################################
## Add AnimationPlayer nodes to all inventory items that don't already have one.
func _add_animation_players_to_inventory_items() -> Completion:
	var inventory_path := PopochiuResources.INVENTORY_ITEMS_PATH
	if not DirAccess.dir_exists_absolute(inventory_path):
		return Completion.IGNORED
	
	var dir := DirAccess.open(inventory_path)
	if dir == null:
		return Completion.IGNORED
	
	var any_item_updated := false
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			var item_scene_path: String = PopochiuResources.get_data_value("inventory_items", file_name.to_snake_case(), null)
			if item_scene_path != null and FileAccess.file_exists(item_scene_path):
				# Process one item at a time to avoid memory issues
				if _update_inventory_item_by_path(item_scene_path):
					any_item_updated = true
		file_name = dir.get_next()

	_reload_needed = any_item_updated
	return Completion.DONE if any_item_updated else Completion.IGNORED


## Update a single inventory item by loading it from its scene path.
func _update_inventory_item_by_path(scene_path: String) -> bool:
	var packed_scene: PackedScene = load(scene_path)
	if not packed_scene:
		return false
	
	var item_instance = packed_scene.instantiate()
	if not item_instance is PopochiuInventoryItem:
		item_instance.queue_free()
		return false
	
	# Check if the item already has an AnimationPlayer node
	if item_instance.has_node("AnimationPlayer"):
		item_instance.queue_free()
		return false

	# Create and add the AnimationPlayer node
	var animation_player := AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	item_instance.add_child(animation_player)
	animation_player.owner = item_instance

	PopochiuUtils.print_normal(
		"Migration %d: added AnimationPlayer to inventory item '%s'." %
		[VERSION, item_instance.script_name]
	)

	# Save the scene
	if PopochiuEditorHelper.pack_scene(item_instance) != OK:
		PopochiuUtils.print_error(
			"Migration %d: Couldn't update [b]%s[/b] after adding AnimationPlayer." %
			[VERSION, item_instance.script_name]
		)
		item_instance.queue_free()
		return false

	# Clean up the instance
	item_instance.queue_free()
	return true


#endregion