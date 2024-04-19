@tool
extends EditorPlugin
## Plugin setup.
## 
## Some icons that might be useful: godot\editor\editor_themes.cpp

const ES := "[es] Estás usando Popochiu, un plugin para crear juegos point n' click"
const EN := "[en] You're using Popochiu, a plugin for making point n' click games"
const SYMBOL := "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ \\( u )3(u )/ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"
const POPOCHIU_CANVAS_EDITOR_MENU = preload(
	"res://addons/popochiu/editor/canvas_editor_menu/popochiu_canvas_editor_menu.tscn"
)

var main_dock: Panel

var _editor_interface := get_editor_interface()
var _editor_file_system := _editor_interface.get_resource_filesystem()
var _is_first_install := false
var _input_actions := preload("res://addons/popochiu/engine/others/input_actions.gd")
var _export_plugin: EditorExportPlugin = null
var _inspector_plugins := []
var _gui_templates_helper := preload(
	"res://addons/popochiu/editor/helpers/popochiu_gui_templates_helper.gd"
)


#region Godot ######################################################################################
func _get_plugin_name():
	return "Popochiu 2.0"


func _init():
	if Engine.is_editor_hint():
		_is_first_install = PopochiuResources.init_file_structure()
	
	# Load Popochiu singletons
	add_autoload_singleton("Globals", PopochiuResources.GLOBALS_SNGL)
	add_autoload_singleton("Cursor", PopochiuResources.CURSOR_SNGL)
	add_autoload_singleton("E", PopochiuResources.POPOCHIU_SNGL)
	add_autoload_singleton("R", PopochiuResources.R_SNGL)
	add_autoload_singleton("C", PopochiuResources.C_SNGL)
	add_autoload_singleton("I", PopochiuResources.I_SNGL)
	add_autoload_singleton("D", PopochiuResources.D_SNGL)
	add_autoload_singleton("A", PopochiuResources.A_SNGL)
	add_autoload_singleton("G", PopochiuResources.IGRAPHIC_INTERFACE_SNGL)


func _enter_tree() -> void:
	if _is_first_install: return
	
	# Good morning, starshine. The Earth says hello.
	prints(ES)
	prints(EN)
	print_rich("[wave]%s[/wave]" % SYMBOL)
	
	_editor_file_system.scan_sources()
	
	PopochiuEditorConfig.initialize_editor_settings()
	PopochiuConfig.initialize_project_settings()
	
	# Configure main dock to be passed down the plugin chain
	# TODO: Get rid of this cascading assignment and switch to a SignalBus instead!
	main_dock = load(PopochiuResources.MAIN_DOCK_PATH).instantiate()
	main_dock.focus_mode = Control.FOCUS_ALL
	PopochiuEditorHelper.undo_redo = get_undo_redo()

	for path in [
		"res://addons/popochiu/editor/inspector/character_inspector_plugin.gd",
		"res://addons/popochiu/editor/inspector/walkable_area_inspector_plugin.gd",
		"res://addons/popochiu/editor/inspector/aseprite_importer_inspector_plugin.gd",
		"res://addons/popochiu/editor/inspector/audio_cue_inspector_plugin.gd",
	]:
		var eip: EditorInspectorPlugin = load(path).new()
		
		eip.set("main_dock", main_dock) # TODO: change with SignalBus
		
		_inspector_plugins.append(eip)
		add_inspector_plugin(eip)
	
	_export_plugin = preload("popochiu_export_plugin.gd").new()
	add_export_plugin(_export_plugin)
	
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, main_dock)
	add_control_to_container(
		EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU,
		POPOCHIU_CANVAS_EDITOR_MENU.instantiate()
	)
	
	await get_tree().create_timer(0.5).timeout
	
	# Fill the dock with Rooms, Characters, Inventory items, Dialogs and AudioCues
	main_dock.call_deferred("grab_focus")
	
	# ==== Connect to signals ======================================================================
	_editor_interface.get_file_system_dock().file_removed.connect(_on_file_removed)
	_editor_interface.get_file_system_dock().files_moved.connect(_on_files_moved)
	# TODO: This connection might be needed only by TabAudio.gd, so probably would be better if it
	# is done there
	_editor_file_system.sources_changed.connect(_on_sources_changed)
	
	scene_changed.connect(main_dock.scene_changed)
	scene_closed.connect(main_dock.scene_closed)
	# ====================================================================== Connect to signals ====
	
	if _editor_interface.get_edited_scene_root():
		main_dock.scene_changed(_editor_interface.get_edited_scene_root())
	
	main_dock.setup_dialog.es = _editor_interface.get_editor_settings()
	
	# Connect signals between other nodes
	main_dock.setup_dialog.gui_selected.connect(_gui_templates_helper.copy_gui_template)
	
	# Check if the Setup popup should be shown: the first time the Editor is opened after installing
	# the plugin or if there is no GUI scene (template) selected.
	if not (PopochiuResources.is_setup_done() or PopochiuResources.is_gui_set()):
		main_dock.setup_dialog.appear(true)
		(main_dock.setup_dialog as AcceptDialog).confirmed.connect(_set_setup_done)
	
	PopochiuResources.update_autoloads(true)
	_editor_file_system.scan_sources()
	
	main_dock.call_deferred("fill_data")


func _exit_tree() -> void:
	remove_control_from_docks(main_dock)
	main_dock.queue_free()
	
	if is_instance_valid(_export_plugin):
		remove_export_plugin(_export_plugin)
	
	for eip in _inspector_plugins:
		if is_instance_valid(eip):
			remove_inspector_plugin(eip)


#endregion

#region Virtual ####################################################################################
func _enable_plugin() -> void:
	_create_input_actions()
	
	if _is_first_install:
		# Show the window that asks devs to reload the project
		var ad := AcceptDialog.new()
		ad.title = "Popochiu"
		ad.dialog_text =\
		"[ ES ] Se reiniciará Godot para completar la instalación.\n" +\
		"[ EN ] Godot will restart to complete the installation."
		ad.confirmed.connect(EditorInterface.restart_editor.bind(false))
		ad.close_requested.connect(EditorInterface.restart_editor.bind(false))
		
		_editor_interface.get_base_control().add_child(ad)
		ad.popup_centered()


func _disable_plugin() -> void:
	remove_autoload_singleton("Globals")
	remove_autoload_singleton("Cursor")
	remove_autoload_singleton("E")
	remove_autoload_singleton("R")
	remove_autoload_singleton("C")
	remove_autoload_singleton("I")
	remove_autoload_singleton("D")
	remove_autoload_singleton("G")
	remove_autoload_singleton("A")
	
	_remove_input_actions()
	
	remove_control_from_docks(main_dock)


#endregion

#region Private ####################################################################################
func _create_input_actions() -> void:
	# Register in the Project settings the Inputs for popochiu-interact,
	# popochiu-look and popochiu-skip. Thanks QuentinCaffeino ;)
	for d in _input_actions.ACTIONS:
		var setting_name = "input/" + d.name
		
		if not ProjectSettings.has_setting(setting_name):
			var event: InputEvent
			
			if d.has("button"):
				event = InputEventMouseButton.new()
				event.button_index = d.button
			elif d.has("key"):
				event = InputEventKey.new()
				event.keycode = d.key
			
			ProjectSettings.set_setting(
				setting_name,
				{
					deadzone = float(d.deadzone if d.has("deadzone") else 0.5),
					events = [event]
				}
			)

	var result = ProjectSettings.save()
	assert(result == OK)


func _remove_input_actions() -> void:
	for d in _input_actions.ACTIONS:
		var setting_name = "input/" + d.name
		
		if ProjectSettings.has_setting(setting_name):
			ProjectSettings.clear(setting_name)
	
	var result = ProjectSettings.save()
	assert(result == OK)


func _set_setup_done() -> void:
	PopochiuResources.set_data_value("setup", "done", true)


func _on_sources_changed(exist: bool) -> void:
	if Engine.is_editor_hint() and is_instance_valid(main_dock):
		main_dock.search_audio_files()


func _on_files_moved(old_file: String, new_file: String) -> void:
	# TODO: Check if the change affects one of the .tres files created by
	# Popochiu and update the respective file names and rows in the Dock
	pass


func _on_file_removed(file: String) -> void:
	pass


#endregion
