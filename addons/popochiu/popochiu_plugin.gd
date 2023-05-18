# Plugin setup.
# 
# Some icons that might be useful: godot\editor\editor_themes.cpp
@tool
extends EditorPlugin

const ES :=\
"[es] Estás usando Popochiu, un plugin para crear juegos point n' click"
const EN :=\
"[en] You're using Popochiu, a plugin for making point n' click games"
const SYMBOL :=\
"▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ \\( u )3(u )/ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"

var main_dock: Panel

var _editor_interface := get_editor_interface()
var _editor_file_system := _editor_interface.get_resource_filesystem()
var _is_first_install := false
var _input_actions :=\
preload('res://addons/popochiu/engine/others/input_actions.gd')
var _shown_helpers := []
var _export_plugin: EditorExportPlugin = null
var _inspector_plugins := []
var _selected_node: Node = null
var _vsep := VSeparator.new()
var _btn_baseline := Button.new()
var _btn_walk_to := Button.new()
var _types_helper: Resource = null
var _tool_btn_stylebox :=\
_editor_interface.get_base_control().get_theme_stylebox("normal", "Button")


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _get_plugin_name():
	return 'Popochiu 2.0'


func _init():
	if Engine.is_editor_hint():
		_is_first_install = PopochiuResources.init_file_structure()
	
	# Load Popochiu singletons
	add_autoload_singleton('Globals', PopochiuResources.GLOBALS_SNGL)
	add_autoload_singleton('Cursor', PopochiuResources.CURSOR_SNGL)
	add_autoload_singleton('E', PopochiuResources.POPOCHIU_SNGL)
	add_autoload_singleton('R', PopochiuResources.R_SNGL)
	add_autoload_singleton('C', PopochiuResources.C_SNGL)
	add_autoload_singleton('I', PopochiuResources.I_SNGL)
	add_autoload_singleton('D', PopochiuResources.D_SNGL)
	add_autoload_singleton('G', PopochiuResources.IGRAPHIC_INTERFACE_SNGL)
	add_autoload_singleton('A', PopochiuResources.A_SNGL)


func _enter_tree() -> void:
	if _is_first_install: return
	
	prints(ES)
	prints(EN)
	print_rich('[wave]%s[/wave]' % SYMBOL)
	
	_editor_file_system.scan_sources()
	
	_types_helper =\
	load('res://addons/popochiu/editor/helpers/popochiu_types_helper.gd')
	
	for path in [
		'res://addons/popochiu/editor/inspector/character_inspector_plugin.gd',
		'res://addons/popochiu/editor/inspector/walkable_area_inspector_plugin.gd',
		'res://addons/popochiu/editor/inspector/audio_cue_inspector_plugin.gd',
	]:
		var eip: EditorInspectorPlugin = load(path).new()
		
		eip.set('ei', _editor_interface)
		
		_inspector_plugins.append(eip)
		add_inspector_plugin(eip)
	
	_export_plugin = preload('popochiu_export_plugin.gd').new()
	add_export_plugin(_export_plugin)
	
	main_dock = load(PopochiuResources.MAIN_DOCK_PATH).instantiate()
	main_dock.ei = _editor_interface
	main_dock.fs = _editor_file_system
	main_dock.focus_mode = Control.FOCUS_ALL
	
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, main_dock)
	
	_create_container_buttons()
	
	await get_tree().create_timer(0.5).timeout
	
	# Fill the dock with Rooms, Characters, Inventory items, Dialogs and
	# AudioCues
	main_dock.grab_focus()
	
	# ==== Connect to signals ==================================================
	_editor_interface.get_selection().selection_changed.connect(_check_nodes)
	_editor_interface.get_file_system_dock().file_removed.connect(_on_file_removed)
	_editor_interface.get_file_system_dock().files_moved.connect(_on_files_moved)
	# TODO: This connection might be needed only by TabAudio.gd, so probably
	# would be better if it is done there
	_editor_file_system.sources_changed.connect(_on_sources_changed)
	
	scene_changed.connect(main_dock.scene_changed)
	scene_closed.connect(main_dock.scene_closed)
	# ================================================== Connect to signals ====
	
	if _editor_interface.get_edited_scene_root():
		main_dock.scene_changed(_editor_interface.get_edited_scene_root())
	
	main_dock.setup_dialog.es = _editor_interface.get_editor_settings()
	main_dock.setup_dialog.move_requested.connect(_move_to_project)
	
	if PopochiuResources.get_section('setup').is_empty():
		main_dock.setup_dialog.appear(true)
		(main_dock.setup_dialog as AcceptDialog).confirmed.connect(
			_set_setup_done
		)
	
	PopochiuResources.update_autoloads(true)
	_editor_file_system.scan_sources()


func _exit_tree() -> void:
	remove_control_from_docks(main_dock)
	main_dock.queue_free()
	
	if is_instance_valid(_export_plugin):
		remove_export_plugin(_export_plugin)
	
	for eip in _inspector_plugins:
		if is_instance_valid(eip):
			remove_inspector_plugin(eip)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _enable_plugin() -> void:
	_create_input_actions()
	
	if _is_first_install:
		# Show the window that asks devs to reload the project
		var ad := AcceptDialog.new()
		
		# TODO: Localize
		ad.title = 'Popochiu'
		ad.dialog_text =\
		'[es] Reinicia el motor para completar la instalación:\n' +\
		'Proyecto > Volver a Cargar el Proyecto Actual\n\n' + \
		'[en] Restart Godot to complete the installation:\n' +\
		'Project > Reload Current Project'
		
		_editor_interface.get_base_control().add_child(ad)
		ad.popup_centered()


func _disable_plugin() -> void:
	remove_autoload_singleton('Globals')
	remove_autoload_singleton('Cursor')
	remove_autoload_singleton('E')
	remove_autoload_singleton('R')
	remove_autoload_singleton('C')
	remove_autoload_singleton('I')
	remove_autoload_singleton('D')
	remove_autoload_singleton('G')
	remove_autoload_singleton('A')
	
	_remove_input_actions()
	
	remove_control_from_docks(main_dock)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _create_input_actions() -> void:
	# Register in the Project settings the Inputs for popochiu-interact,
	# popochiu-look and popochiu-skip. Thanks QuentinCaffeino ;)
	for d in _input_actions.ACTIONS:
		var setting_name = 'input/' + d.name
		
		if not ProjectSettings.has_setting(setting_name):
			var event: InputEvent
			
			if d.has('button'):
				event = InputEventMouseButton.new()
				event.button_index = d.button
			elif d.has('key'):
				event = InputEventKey.new()
				event.scancode = d.key
			
			ProjectSettings.set_setting(
				setting_name,
				{
					deadzone = float(d.deadzone if d.has('deadzone') else 0.5),
					events = [event]
				}
			)

	var result = ProjectSettings.save()
	assert(result == OK) #,'[Popochiu] Failed to save project settings.')


func _remove_input_actions() -> void:
	for d in _input_actions.ACTIONS:
		var setting_name = 'input/' + d.name
		
		if ProjectSettings.has_setting(setting_name):
			ProjectSettings.clear(setting_name)
	
	var result = ProjectSettings.save()
	assert(result == OK) #,'[Popochiu] Failed to save project settings.')


func _set_setup_done() -> void:
	PopochiuResources.set_data_value('setup', 'done', true)


func _check_popochiu_dependencies() -> void:
	_fix_dependencies(
		_editor_file_system.get_filesystem_path(
			PopochiuResources.GRAPHIC_INTERFACE_POPOCHIU.get_base_dir()
		)
	)
	
	await get_tree().create_timer(0.3).timeout
	
	_fix_dependencies(
		_editor_file_system.get_filesystem_path(
			PopochiuResources.TRANSITION_LAYER_POPOCHIU.get_base_dir()
		)
	)
	
	await get_tree().process_frame


# Thanks PigDev ;)
# https://github.com/pigdevstudio/godot_tools/blob/master/source/tools/DependencyFixer.gd
func _fix_dependencies(dir: EditorFileSystemDirectory) -> void:
	var res := _editor_file_system.get_filesystem()
	
	for f in dir.get_file_count():
		var path = dir.get_file_path(f)
		var dependencies = ResourceLoader.get_dependencies(path)

		for d in dependencies:
			if FileAccess.file_exists(d):
				continue
			_fix_dependency(d, res, path)

	for subdir_id in dir.get_subdir_count():
		var subdir := dir.get_subdir(subdir_id)
		
		for f in subdir.get_file_count():
			var path = subdir.get_file_path(f)
			var dependencies = ResourceLoader.get_dependencies(path)
			
			if dependencies.size() < 1:
				continue
			
			for d in dependencies:
				if FileAccess.file_exists(d):
					continue
				
				_fix_dependency(d, res, path)
	
	_editor_file_system.scan()


func _fix_dependency(dependency, directory, resource_path):
	for subdir in directory.get_subdir_count():
		_fix_dependency(dependency, directory.get_subdir(subdir), resource_path)

	for f in directory.get_file_count():
		if not directory.get_file(f) == dependency.get_file():
			continue
		var file_read = FileAccess.open(resource_path, FileAccess.READ)
		var text = file_read.get_as_text()
		file_read.close()
		
		text = text.replace(dependency, directory.get_file_path(f))
		
		var file_write = FileAccess.open(resource_path, FileAccess.WRITE)
		file_write.store_string(text)
		file_write.close()


func _on_sources_changed(exist: bool) -> void:
	if Engine.is_editor_hint() and is_instance_valid(main_dock):
		main_dock.search_audio_files()


# Toggles Clickable helpers in order to show walk-to-point, baseline and dialog
# position (PopochiuCharacter) only when a node of that type is selected in the
# scene tree.
func _check_nodes() -> void:
	for n in _shown_helpers:
		if is_instance_valid(n):
			n.hide_helpers()
	
	_shown_helpers.clear()
	
	if not is_instance_valid(_editor_interface.get_selection()): return
	
	for n in _editor_interface.get_selection().get_selected_nodes():
		if n.has_method('show_helpers'):
			n.show_helpers()
			_shown_helpers.append(n)
		elif n.get_parent().has_method('show_helpers'):
			n.get_parent().show_helpers()
			_shown_helpers.append(n.get_parent())
	
	if not is_instance_valid(_types_helper): return
	
	if _editor_interface.get_selection().get_selected_nodes().size() == 1:
		_selected_node = _editor_interface.get_selection().get_selected_nodes()[0]
		
		if _types_helper.is_prop(_selected_node)\
		or _types_helper.is_hotspot(_selected_node)\
		or _types_helper.is_prop(_selected_node.get_parent())\
		or _types_helper.is_hotspot(_selected_node.get_parent()):
			if _types_helper.is_prop(_selected_node)\
			or _types_helper.is_hotspot(_selected_node):
				_btn_baseline.set_pressed_no_signal(false)
				_btn_walk_to.set_pressed_no_signal(false)
			
			_btn_baseline.show()
			_btn_walk_to.show()
		else:
			_btn_baseline.hide()
			_btn_walk_to.hide()


func _on_files_moved(old_file: String, new_file: String) -> void:
	# TODO: Check if the change affects one of the .tres files created by
	# Popochiu and update the respective file names and rows in the Dock
	pass


func _on_file_removed(file: String) -> void:
	pass


func _create_container_buttons() -> void:
	var panl := Panel.new()
	var hbox := HBoxContainer.new()
	
	_btn_baseline.icon = preload('res://addons/popochiu/icons/baseline.png')
	_btn_baseline.tooltip_text = 'Baseline'
	_btn_baseline.toggle_mode = true
	_btn_baseline.add_theme_stylebox_override('normal', _tool_btn_stylebox)
	_btn_baseline.add_theme_stylebox_override('hover', _tool_btn_stylebox)
	_btn_baseline.pressed.connect(_select_baseline)
	
	_btn_walk_to.icon = preload('res://addons/popochiu/icons/walk_to_point.png')
	_btn_walk_to.tooltip_text = 'Walk to point'
	_btn_walk_to.toggle_mode = true
	_btn_walk_to.add_theme_stylebox_override('normal', _tool_btn_stylebox)
	_btn_walk_to.add_theme_stylebox_override('hover', _tool_btn_stylebox)
	_btn_walk_to.pressed.connect(_select_walk_to)
	
	hbox.add_child(_vsep)
	hbox.add_child(_btn_baseline)
	hbox.add_child(_btn_walk_to)
	
	panl.add_child(hbox)
	
	add_control_to_container(
		EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU,
		panl
	)
	
	_vsep.hide()
	_btn_baseline.hide()
	_btn_walk_to.hide()


func _select_walk_to() -> void:
	_btn_walk_to.set_pressed_no_signal(true)
	_btn_baseline.set_pressed_no_signal(false)
	_vsep.hide()
	
	if _types_helper.is_prop(_selected_node)\
	or _types_helper.is_hotspot(_selected_node):
		_editor_interface.edit_node(_selected_node.get_node('WalkToHelper'))
	else:
		_editor_interface.edit_node(_selected_node.get_node('../WalkToHelper'))


func _select_baseline() -> void:
	_btn_baseline.set_pressed_no_signal(true)
	_btn_walk_to.set_pressed_no_signal(false)
	_vsep.show()
	
	if _types_helper.is_prop(_selected_node)\
	or _types_helper.is_hotspot(_selected_node):
		_editor_interface.edit_node(_selected_node.get_node('BaselineHelper'))
	else:
		_editor_interface.edit_node(_selected_node.get_node('../BaselineHelper'))


func _move_to_project(id: int) -> void:
	# Move files and folders so developer can overwrite them
	if id == PopochiuResources.GI:
		DirAccess.rename_absolute(
			PopochiuResources.GRAPHIC_INTERFACE_ADDON.get_base_dir(),
			PopochiuResources.GRAPHIC_INTERFACE_POPOCHIU.get_base_dir()
		)
	elif id == PopochiuResources.TL:
		DirAccess.rename_absolute(
			PopochiuResources.TRANSITION_LAYER_ADDON.get_base_dir(),
			PopochiuResources.TRANSITION_LAYER_POPOCHIU.get_base_dir()
		)
	
	# Refresh FileSystem
	_editor_file_system.scan()

	# Fix dependencies
	await _editor_file_system.filesystem_changed
	await _check_popochiu_dependencies()
	
	# Save settings
	var settings := PopochiuResources.get_settings()
	
	if id == PopochiuResources.GI:
		settings.graphic_interface = load(PopochiuResources.GRAPHIC_INTERFACE_POPOCHIU)
		PopochiuResources.set_data_value('setup', 'gi_moved', true)
	elif id == PopochiuResources.TL:
		settings.transition_layer = load(PopochiuResources.TRANSITION_LAYER_POPOCHIU)
		PopochiuResources.set_data_value('setup', 'tl_moved', true)

	PopochiuResources.save_settings(settings)
	
	main_dock.setup_dialog.update_state()
