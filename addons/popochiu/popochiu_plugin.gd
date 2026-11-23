@tool
extends EditorPlugin
## Main Popochiu editor plugin that manages singletons, the dock, and Inspector integrations.

# Some icons that might be useful: godot\editor\editor_themes.cpp

const ES := "[es] Estás usando Popochiu, un plugin para crear juegos point n' click"
const EN := "[en] You're using Popochiu, a plugin for making point n' click games"
const SYMBOL := "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ \\( u )3(u )/ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"
const POPOCHIU_CANVAS_EDITOR_MENU = preload(
	"res://addons/popochiu/editor/canvas_editor_menu/popochiu_canvas_editor_menu.tscn"
)

var dock: Panel

var _editor_file_system := EditorInterface.get_resource_filesystem()
var _is_first_install := false
var _input_actions := preload("res://addons/popochiu/engine/others/input_actions.gd")
var _export_plugin: EditorExportPlugin = null
var _translation_parser_plugin: EditorTranslationParserPlugin = null
var _inspector_plugins := []
# Tracks the last reported untyped variables per script to avoid repeating warnings.
var _untyped_state_scripts := {}


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
	add_autoload_singleton("T", PopochiuResources.ITRANSITION_LAYER_SNGL)


func _enter_tree() -> void:
	# Good morning, starshine. The Earth says hello.
	# Check system language and print the appropriate message
	var locale := OS.get_locale()
	if locale.begins_with("es"):
		prints(ES)
	else:
		prints(EN)
	print_rich("[wave]%s[/wave]" % SYMBOL)
	
	# ---- Assign values to the utility script for the Editor side of the plugin -------------------
	PopochiuEditorHelper.undo_redo = get_undo_redo()
	
	# ---- Add custom categories to the Editor settings and Project settings -----------------------
	PopochiuEditorConfig.initialize_editor_settings()
	PopochiuConfig.initialize_project_settings()
	
	# ---- Load Popochiu's Inspector plugins -------------------------------------------------------
	for path in [
		"res://addons/popochiu/editor/inspector/character_inspector_plugin.gd",
		"res://addons/popochiu/editor/inspector/audio_cue_inspector_plugin.gd",
		"res://addons/popochiu/editor/inspector/prop_inspector_plugin.gd",
	]:
		var eip: EditorInspectorPlugin = load(path).new()
		_inspector_plugins.append(eip)
		add_inspector_plugin(eip)

	_export_plugin = preload("popochiu_export_plugin.gd").new()
	add_export_plugin(_export_plugin)

	_translation_parser_plugin = preload(
		"res://addons/popochiu/editor/plugins/popochiu_translation_parser_plugin.gd"
	).new()
	add_translation_parser_plugin(_translation_parser_plugin)
	
	# ---- Load the Popochiu dock and add it to the Editor -----------------------------------------
	dock = load(PopochiuResources.MAIN_DOCK_PATH).instantiate()
	dock.focus_mode = Control.FOCUS_ALL
	dock.ready.connect(_on_dock_ready)
	
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	
	# ---- Add Popochiu's menus for the Canvas Editor ----------------------------------------------
	add_control_to_container(
		EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU,
		POPOCHIU_CANVAS_EDITOR_MENU.instantiate()
	)

	# ---- Warn about untyped custom state that save/load cannot persist ---------------------------
	resource_saved.connect(_on_resource_saved)
	_check_open_scripts.call_deferred()


func _exit_tree() -> void:
	if resource_saved.is_connected(_on_resource_saved):
		resource_saved.disconnect(_on_resource_saved)

	remove_control_from_docks(dock)
	
	if is_instance_valid(dock):
		dock.queue_free()
	
	if is_instance_valid(_export_plugin):
		remove_export_plugin(_export_plugin)

	if is_instance_valid(_translation_parser_plugin):
		remove_translation_parser_plugin(_translation_parser_plugin)
	
	for eip in _inspector_plugins:
		if is_instance_valid(eip):
			remove_inspector_plugin(eip)


#endregion

#region Virtual ####################################################################################
func _enable_plugin() -> void:
	_create_input_actions()
	EditorInterface.set_plugin_enabled("popochiu/editor/gizmos", true)
	EditorInterface.set_plugin_enabled("popochiu/editor/importers", true)


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
	EditorInterface.set_plugin_enabled("popochiu/editor/gizmos", false)
	EditorInterface.set_plugin_enabled("popochiu/editor/importers", false)
	remove_control_from_docks(dock)


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


func _on_dock_ready() -> void:
	PopochiuEditorHelper.dock = dock
	
	# Check if new migrations exist and run them if they do
	await MigrationsManager.do_migrations()
	
	# Fill the dock with Rooms, Characters, Inventory items, Dialogs and AudioCues
	dock.grab_focus()
	
	scene_changed.connect(_on_scene_changed)
	scene_closed.connect(_on_scene_closed)
	
	if EditorInterface.get_edited_scene_root():
		dock.scene_changed(EditorInterface.get_edited_scene_root())
	else:
		dock.check_open_scenes()
	
	PopochiuResources.create_auto_loads()
	PopochiuResources.update_autoloads(true)
	_editor_file_system.scan_sources()
	dock.fill_data()
	
	if not PopochiuResources.is_setup_done() or not PopochiuResources.is_gui_set():
		PopochiuEditorHelper.show_setup()
	
	if not EditorInterface.is_plugin_enabled("popochiu/editor/gizmos"):
		EditorInterface.set_plugin_enabled("popochiu/editor/gizmos", true)

	if not EditorInterface.is_plugin_enabled("popochiu/editor/importers"):
		EditorInterface.set_plugin_enabled("popochiu/editor/importers", true)


func _on_scene_changed(scene_root: Node) -> void:
	PopochiuEditorHelper.signal_bus.scene_changed.emit(scene_root)


func _on_scene_closed(filepath: String) -> void:
	PopochiuEditorHelper.signal_bus.scene_closed.emit(filepath)


func _on_resource_saved(resource: Resource) -> void:
	if resource is Script:
		_check_state_script(resource as Script)


func _check_open_scripts() -> void:
	var script_editor := EditorInterface.get_script_editor()
	if not is_instance_valid(script_editor):
		return

	for script: Script in script_editor.get_open_scripts():
		_check_state_script(script)


func _check_state_script(script: Script) -> void:
	if not is_instance_valid(script):
		return

	var script_path: String = script.resource_path
	var untyped_properties := PopochiuEditorHelper.get_untyped_state_properties(script)

	if untyped_properties.is_empty():
		_untyped_state_scripts.erase(script_path)
		return

	if _untyped_state_scripts.get(script_path, []) == untyped_properties:
		return

	_untyped_state_scripts[script_path] = untyped_properties

	var names := PackedStringArray(untyped_properties)
	var message := (
		"Untyped variables are excluded from save/load in %s: %s. "
		+ "If they hold game state, use ':=' or an explicit type."
	) % [script_path, ", ".join(names)]
	PopochiuUtils.print_warning(message)


#endregion
