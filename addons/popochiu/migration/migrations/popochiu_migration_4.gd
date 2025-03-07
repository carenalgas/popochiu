@tool
class_name PopochiuMigration4
extends PopochiuMigration

# Update constant values to be correct for your migration
const VERSION = 4
const DESCRIPTION = "short description of migration goes here"
const STEPS = [
	"Remove InventoryBar, SettingsBar, TextSettingsPopup and SoundSettingsPopup",
	"Add SimpleClickBar and SimpleClickSettingsPopup.",
	"Update SaveAndLoadPopup."
]
const ADDON_SIMPLE_CLICK_BAR_SCENE = (
	PopochiuResources.GUI_TEMPLATES_FOLDER +
	"simple_click/components/simple_click_bar/simple_click_bar.tscn"
)
const ADDON_SIMPLE_CLICK_POPUP_SCENE = (
	PopochiuResources.GUI_TEMPLATES_FOLDER +
	"simple_click/components/simple_click_settings_popup/simple_click_settings_popup.tscn"
)
const ADDON_SAVE_AND_LOAD_POPUP_SCENE = (
	PopochiuResources.GUI_ADDON_FOLDER +
	"components/popups/save_and_load_popup/save_and_load_popup.tscn"
)
const ADDON_SAVE_AND_LOAD_POPUP_SCRIPT = (
	PopochiuResources.GUI_ADDON_FOLDER +
	"components/popups/save_and_load_popup/save_and_load_popup.gd"
)
const GAME_SAVE_AND_LOAD_POPUP_SCRIPT = (
	"res://game/gui/components/popups/save_and_load_popup/save_and_load_popup.gd"
)
const SaveAndLoadPopup = preload(ADDON_SAVE_AND_LOAD_POPUP_SCRIPT)

var _gui_templates_helper := preload(
	"res://addons/popochiu/editor/helpers/popochiu_gui_templates_helper.gd"
)
var _gui_scene: PopochiuGraphicInterface = null


#region Virtual ####################################################################################
func _is_migration_needed() -> bool:
	if PopochiuResources.get_data_value("ui", "template", "") != "SimpleClick":
		return false
	
	_gui_scene = (ResourceLoader.load(
		PopochiuResources.GUI_GAME_SCENE, "", ResourceLoader.CACHE_MODE_IGNORE
	) as PackedScene).instantiate()
	
	# If the GUI already has the SimpleClickBar component, then the migration is not needed
	if is_instance_valid(_gui_scene.find_child("SimpleClickBar")):
		return false
	
	return true


func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			# Include the function names for each step here
			_remove_non_used_components,
			_add_new_components,
			_update_save_and_load_popup
		]
	)


func _is_reload_required() -> bool:
	return true


#endregion

#region Private ####################################################################################
func _remove_non_used_components() -> Completion:
	var nodes_to_remove: Array[Control] = []
	for node_name: String in [
		"InventoryBar", "SettingsBar", "TextSettingsPopup", "SoundSettingsPopup"
	]:
		var node: Node = _gui_scene.find_child(node_name)
		if is_instance_valid(node) and node is Control:
			nodes_to_remove.append(node)
	for node: Control in nodes_to_remove:
		node.owner = null
		node.queue_free()
	await PopochiuEditorHelper.frame_processed()
	
	return Completion.DONE


func _add_new_components() -> Completion:
	# Copy the SimpleClickBar component to the game's GUI
	var component_path := await _gui_templates_helper.copy_component(ADDON_SIMPLE_CLICK_BAR_SCENE)
	var component_scene: Control = (load(component_path) as PackedScene).instantiate()
	_gui_scene.add_child(component_scene)
	component_scene.owner = _gui_scene
	_gui_scene.move_child(component_scene, 1)
	
	# Copy the SimpleClickPopup component to the game's GUI
	component_path = await _gui_templates_helper.copy_component(ADDON_SIMPLE_CLICK_POPUP_SCENE)
	component_scene = (load(component_path) as PackedScene).instantiate()
	_gui_scene.get_node("Popups").add_child(component_scene)
	component_scene.owner = _gui_scene
	_gui_scene.get_node("Popups").move_child(component_scene, 0)
	
	# Save the GUI scene with all the changes made by this and previous steps
	PopochiuEditorHelper.pack_scene(_gui_scene, PopochiuResources.GUI_GAME_SCENE)
	return Completion.DONE


func _update_save_and_load_popup() -> Completion:
	# Update the save_and_load_popup.gd in the game's gui folder
	DirAccess.rename_absolute(
		ADDON_SAVE_AND_LOAD_POPUP_SCRIPT,
		GAME_SAVE_AND_LOAD_POPUP_SCRIPT
	)
	
	return Completion.DONE


#endregion
