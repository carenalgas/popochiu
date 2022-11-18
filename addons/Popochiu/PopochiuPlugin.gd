tool
extends EditorPlugin
# Plugin setup.
# Some icons that might be useful:
#	godot\editor\editor_themes.cpp
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

var main_dock: Panel

var _editor_interface := get_editor_interface()
var _editor_file_system := _editor_interface.get_resource_filesystem()
var _directory := Directory.new()
var _is_first_install := false
var _input_actions :=\
preload('res://addons/Popochiu/Engine/Others/InputActions.gd')
var _shown_helpers := []
var _export_plugin: EditorExportPlugin = null
var _inspector_plugin: EditorInspectorPlugin = null
var _selected_node: Node = null
var _vsep := VSeparator.new()
var _btn_baseline := Button.new()
var _btn_walk_to := Button.new()
var _types_helper: Resource = null
var _tool_btn_stylebox :=\
_editor_interface.get_base_control().get_stylebox("normal", "ToolButton")


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _init() -> void:
	# Thanks Dialogic ;)
	if Engine.editor_hint:
		_is_first_install = PopochiuResources.init_file_structure()
	
	# Load Popochiu singletons
	add_autoload_singleton('Globals', PopochiuResources.GLOBALS_SNGL)
	add_autoload_singleton('U', PopochiuResources.UTILS_SNGL)
	add_autoload_singleton('Cursor', PopochiuResources.CURSOR_SNGL)
	add_autoload_singleton('E', PopochiuResources.POPOCHIU_SNGL)
	add_autoload_singleton('C', PopochiuResources.ICHARACTER_SNGL)
	add_autoload_singleton('I', PopochiuResources.IINVENTORY_SNGL)
	add_autoload_singleton('D', PopochiuResources.IDIALOG_SNGL)
	add_autoload_singleton('G', PopochiuResources.IGRAPHIC_INTERFACE_SNGL)
	add_autoload_singleton('A', PopochiuResources.IAUDIO_MANAGER_SNGL)


func _enter_tree() -> void:
	if _is_first_install: return
	
	prints('[es] Estás usando Popochiu, un plugin para crear juegos point n\' click')
	prints('[en] You\'re using Popochiu, a plugin for making point n\' click games')
	prints('▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ \\( o )3(o)/ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒')
	
	_editor_file_system.scan_sources()
	
	_types_helper =\
	load('res://addons/Popochiu/Editor/Helpers/PopochiuTypesHelper.gd')
	
	_export_plugin = preload('PopochiuExportPlugin.gd').new()
	add_export_plugin(_export_plugin)
	
	_inspector_plugin = load('res://addons/Popochiu/PopochiuInspectorPlugin.gd').new()
	_inspector_plugin.ei = _editor_interface
	add_inspector_plugin(_inspector_plugin)
	
	main_dock = load(PopochiuResources.MAIN_DOCK_PATH).instance()
	main_dock.ei = _editor_interface
	main_dock.fs = _editor_file_system
	main_dock.focus_mode = Control.FOCUS_ALL
	
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, main_dock)
	
	_create_container_buttons()
	
	yield(get_tree().create_timer(0.5), 'timeout')
	
	# Fill the dock with Rooms, Characters, Inventory items, Dialogs and Audio cues
	main_dock.fill_data()
	main_dock.grab_focus()
	
	# ==== Connect to signals ==================================================
	_editor_interface.get_selection().connect(
		'selection_changed', self, '_check_nodes'
	)
	_editor_interface.get_file_system_dock().connect(
		'file_removed', self, '_on_file_removed'
	)
	_editor_interface.get_file_system_dock().connect(
		'files_moved', self, '_on_files_moved'
	)
	# TODO: This connection might be needed only by TabAudio.gd, so probably
	# would be better if it is done there
	_editor_file_system.connect('sources_changed', self, '_on_sources_changed')
	
	connect('scene_changed', main_dock, 'scene_changed')
	connect('scene_closed', main_dock, 'scene_closed')
	# ================================================== Connect to signals ====
	
	main_dock.scene_changed(_editor_interface.get_edited_scene_root())
	main_dock.setup_dialog.es = _editor_interface.get_editor_settings()
	
	if PopochiuResources.get_section('setup').empty():
		main_dock.setup_dialog.appear(true)
		(main_dock.setup_dialog as AcceptDialog).connect(
			'popup_hide', self, '_move_addon_folders'
		)


func _exit_tree() -> void:
	remove_control_from_docks(main_dock)
	remove_control_from_container(
		EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU,
		_btn_baseline
	)
	main_dock.queue_free()
	
	if is_instance_valid(_export_plugin):
		remove_export_plugin(_export_plugin)
	
	if is_instance_valid(_inspector_plugin):
		remove_inspector_plugin(_inspector_plugin)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func enable_plugin() -> void:
	_create_input_actions()
	
	if _is_first_install:
		# Mostrar la ventana de diálogo para pedirle a la desarrolladora que reinicie
		# el motor.
		var ad := AcceptDialog.new()
		
		# TODO: Localize
		ad.window_title = 'Popochiu'
		ad.dialog_text =\
		'[es] Reinicia el motor para completar la instalación:\n' +\
		'Proyecto > Volver a Cargar el Proyecto Actual\n\n' + \
		'[en] Restart Godot to complete the instalation:\n' +\
		'Project > Reload Current Project'
#		var rtl := RichTextLabel.new()
		
#		rtl.rect_min_size = Vector2(640.0, 128.0)
#		rtl.margin_left = 0.0
#		rtl.margin_top = 0.0
#		rtl.margin_right = 0.0
#		rtl.margin_bottom = 0.0
#		rtl.bbcode_enabled = true
#		rtl.fit_content_height = true
#		rtl.add_stylebox_override('normal', rtl.get_stylebox("Content", "EditorStyles"))
#		rtl.append_bbcode(\
#		'[es] Reinicia el motor para completar la instalación ([b]Proyecto > Volver a Cargar el Proyecto Actual[/b]).\n' + \
#		'[en] Restart Godot to complete the instalation ([b]Project > Reload Current Project[/b]).'
#		)
#
#		ad.add_child(rtl)
#		prints('>>>', rtl.get_font('main', 'EditorFonts'))
#		rtl.add_font_override('normal_font', rtl.get_font('main', 'EditorFonts'))
#		rtl.add_font_override('bold_font', rtl.get_font("doc_source", 'EditorFonts'))
#		ad.set_as_minsize()
		
		_editor_interface.get_base_control().add_child(ad)
		ad.popup_centered()


func disable_plugin() -> void:
	remove_autoload_singleton('Globals')
	remove_autoload_singleton('U')
	remove_autoload_singleton('Cursor')
	remove_autoload_singleton('E')
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
	assert(result == OK, '[Popochiu] Failed to save project settings.')


func _remove_input_actions() -> void:
	for d in _input_actions.ACTIONS:
		var setting_name = 'input/' + d.name
		
		if ProjectSettings.has_setting(setting_name):
			ProjectSettings.clear(setting_name)
	
	var result = ProjectSettings.save()
	assert(result == OK, '[Popochiu] Failed to save project settings.')


func _move_addon_folders() -> void:
	# Move files and folders so developer can overwrite them
#	_directory.rename(
#		PopochiuResources.GRAPHIC_INTERFACE_ADDON.get_base_dir(),
#		PopochiuResources.GRAPHIC_INTERFACE_POPOCHIU.get_base_dir()
#	)
#	_directory.rename(
#		PopochiuResources.TRANSITION_LAYER_ADDON.get_base_dir(),
#		PopochiuResources.TRANSITION_LAYER_POPOCHIU.get_base_dir()
#	)
	
	# Refresh FileSystem
#	_editor_file_system.scan()

	# Fix dependencies
#	yield(_editor_file_system, 'filesystem_changed')
#	yield(_check_popochiu_dependencies(), 'completed')
	
	# Save settings
#	var settings := PopochiuResources.get_settings()
#	settings.graphic_interface = load(PopochiuResources.GRAPHIC_INTERFACE_POPOCHIU)
#	settings.transition_layer = load(PopochiuResources.TRANSITION_LAYER_POPOCHIU)
#
#	PopochiuResources.save_settings(settings)
	
	# Mark setup as done in PopochiuData.cfg
	PopochiuResources.set_data_value('setup', 'done', true)


func _check_popochiu_dependencies() -> void:
	_fix_dependencies(
		_editor_file_system.get_filesystem_path(
			PopochiuResources.GRAPHIC_INTERFACE_POPOCHIU.get_base_dir()
		)
	)
	
	yield(get_tree().create_timer(0.3), 'timeout')
	
	_fix_dependencies(
		_editor_file_system.get_filesystem_path(
			PopochiuResources.TRANSITION_LAYER_POPOCHIU.get_base_dir()
		)
	)
	
	yield(get_tree(), 'idle_frame')


# Thanks PigDev ;)
# https://github.com/pigdevstudio/godot_tools/blob/master/source/tools/DependencyFixer.gd
func _fix_dependencies(dir: EditorFileSystemDirectory) -> void:
	var res := _editor_file_system.get_filesystem()
	
	for f in dir.get_file_count():
		var path = dir.get_file_path(f)
		var dependencies = ResourceLoader.get_dependencies(path)
		var file = File.new()

		for d in dependencies:
			if file.file_exists(d):
				continue
			_fix_dependency(d, res, path)

	for subdir in dir.get_subdir_count():
		subdir = dir.get_subdir(subdir)
		for f in subdir.get_file_count():
			var path = subdir.get_file_path(f)
			var dependencies = ResourceLoader.get_dependencies(path)
			if dependencies.size() < 1:
				continue
			var file = File.new()
			for d in dependencies:
				if file.file_exists(d):
					continue
				_fix_dependency(d, res, path)
	_editor_file_system.scan()


func _fix_dependency(dependency, directory, resource_path):
	for subdir in directory.get_subdir_count():
		_fix_dependency(dependency, directory.get_subdir(subdir), resource_path)

	for f in directory.get_file_count():
		if not directory.get_file(f) == dependency.get_file():
			continue
		var file = File.new()
		file.open(resource_path, file.READ)
		var text = file.get_as_text()
		file.close()
		text = text.replace(dependency, directory.get_file_path(f))
		file.open(resource_path, file.WRITE)
		file.store_string(text)
		file.close()


func _on_sources_changed(exist: bool) -> void:
	if Engine.editor_hint and is_instance_valid(main_dock):
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
	
	_btn_baseline.icon = preload('res://addons/Popochiu/icons/baseline.png')
	_btn_baseline.hint_tooltip = 'Baseline'
	_btn_baseline.toggle_mode = true
	_btn_baseline.add_stylebox_override('normal', _tool_btn_stylebox)
	_btn_baseline.add_stylebox_override('hover', _tool_btn_stylebox)
	_btn_baseline.connect('pressed', self, '_select_baseline')
	
	_btn_walk_to.icon = preload('res://addons/Popochiu/icons/walk_to_point.png')
	_btn_walk_to.hint_tooltip = 'Walk to point'
	_btn_walk_to.toggle_mode = true
	_btn_walk_to.add_stylebox_override('normal', _tool_btn_stylebox)
	_btn_walk_to.add_stylebox_override('hover', _tool_btn_stylebox)
	_btn_walk_to.connect('pressed', self, '_select_walk_to')
	
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
