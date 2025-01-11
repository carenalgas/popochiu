@tool
class_name PopochiuMigration4
extends PopochiuMigration

# Update constant values to be correct for your migration
const VERSION = 4
const DESCRIPTION = "short description of migration goes here"
const STEPS = [
	"Remove InventoryBar, SettingsBar, TextSettingsPopup and SoundSettingsPopup.",
	"Add SimpleClickBar and SimpleClickSettingsPopup.",
	"Update SaveAndLoadPopup.",
]



#region Virtual ####################################################################################
func _is_migration_needed() -> bool:
	return PopochiuResources.get_data_value("ui", "template", "") == "SimpleClick"


func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			# Include the function names for each step here
			_remove_non_used_components,
			_step2,
			_step3,
		]
	)


func _is_reload_required() -> bool:
	return false


#endregion

#region Private ####################################################################################
func _remove_non_used_components() -> Completion:
	var gui_scene := (ResourceLoader.load(
		PopochiuResources.GUI_GAME_SCENE, "", ResourceLoader.CACHE_MODE_IGNORE
	) as PackedScene).instantiate()
	var nodes_to_remove: Array[Control] = []
	for node_name: String in [
		"InventoryBar", "SettingsBar", "TextSettingsPopup", "SoundSettingsPopup"
	]:
		var node: Node = gui_scene.find_child(node_name)
		if is_instance_valid(node) and node is Control:
			nodes_to_remove.append(node)
	for node: Control in nodes_to_remove:
		node.owner = null
		node.queue_free()
	await PopochiuEditorHelper.frame_processed()
	
	var gui_packed_scene := PackedScene.new()
	gui_packed_scene.pack(gui_scene)
	ResourceSaver.save(gui_packed_scene, PopochiuResources.GUI_GAME_SCENE)
	
	return Completion.DONE


func _step2() -> Completion:
	return Completion.DONE


func _step3() -> Completion:
	return Completion.DONE


#endregion
