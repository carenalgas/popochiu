@tool
extends Resource
## Helper class for operations related to the GUI templates

static var _template_id := ""
static var _progress_window: Window
static var _progress_lines := ["|", "/", "-", "\\", "-"]
static var _progress_idx := 0

## Create a copy of the selected template, including its components.
## Also, generate the necessary scripts to define custom logic for the graphical
## interface and its commands.
static func copy_gui_template(template_name: String) -> void:
	if template_name == PopochiuResources.get_data_value("ui", "template", ""):
		PopochiuUtils.print_normal("No changes in GUI tempalte.")
		return
	
	_create_progress_window()
	
	var scene_path := PopochiuResources.GUI_CUSTOM_SCENE
	var commands_template_path := PopochiuResources.GUI_CUSTOM_TEMPLATE
	
	_template_id = template_name.to_snake_case()
	
	match _template_id:
		PopochiuResources.GUI_SIMPLE_CLICK:
			scene_path = PopochiuResources.GUI_SIMPLE_CLICK_SCENE
			commands_template_path = PopochiuResources.GUI_SIMPLE_CLICK_TEMPLATE
		PopochiuResources.GUI_9_VERB:
			scene_path = PopochiuResources.GUI_9_VERB_SCENE
			commands_template_path = PopochiuResources.GUI_9_VERB_TEMPLATE
		PopochiuResources.GUI_SIERRA:
			scene_path = PopochiuResources.GUI_SIERRA_SCENE
			commands_template_path = PopochiuResources.GUI_SIERRA_TEMPLATE
	
	var script_path := PopochiuResources.GUI_GAME_SCENE.replace(".tscn", ".gd")
	var commands_path := PopochiuResources.GUI_GAME_SCENE.replace(
		"graphic_interface.tscn", "commands.gd"
	)
	
	# ---- Make a copy of the selected GUI template ------------------------------------------------
	if _create_scene(scene_path) != OK:
		# TODO: Delete the graphic_interface folder and all its contents?
		PopochiuUtils.print_error(
			"[Popochiu] Couldn't create %s file" % PopochiuResources.GUI_GAME_SCENE
		)
		
		return
	
	# Copy the components used by the GUI template to the res://game/graphic_interface/components
	# folder so devs can play with them freely -----------------------------------------------------
	await _copy_components(scene_path, true)
	
	# Create a copy of the corresponding commands template -----------------------------------------
	_copy_scripts(commands_template_path, commands_path, script_path, scene_path)
	
	# Create a copy of the GUI template resources --------------------------------------------------
	# TODO: Create res://game/graphic_interface/resources
	# 		Move files (and directories) in the GUI template resources folder
	# 		to the created folder.
	
	# Update the script of the created graphic_interface.tscn so it uses the
	# copy created above ---------------------------------------------------------------------------
	if _update_scene_script(script_path) != OK:
		PopochiuUtils.print_error(
			"[Popochiu] Couldn't update graphic_interface.tscn script"
		)
		
		return
	
	# Save the GUI template in Settings and popochiu_data.cfg --------------------------------------
	_update_settings_and_config(template_name, commands_path)
	
	_progress_window.queue_free()


## Create the **graphic_interface.tscn** file as a copy of the selected GUI template scene.
## If a template change is being made, all components of the previous template are removed along
## with the **.tscn** file before copying the new one.
static func _create_scene(scene_path: String) -> int:
	# Create the res://game/graphic_interface/ folder
	if not FileAccess.file_exists(PopochiuResources.GUI_GAME_SCENE):
		DirAccess.make_dir_recursive_absolute(PopochiuResources.GUI_GAME_FOLDER)
	else:
		# Remove the graphic_interface.tscn file
		DirAccess.remove_absolute(PopochiuResources.GUI_GAME_SCENE)
		EditorInterface.get_resource_filesystem().scan()
		
		for dir_name: String in DirAccess.get_directories_at(PopochiuResources.GUI_GAME_FOLDER):
			_remove_components(PopochiuResources.GUI_GAME_FOLDER + dir_name)
	
	# Make a copy of the selected GUI template (.tscn) and save it in
	# res://game/graphic_interface/graphic_interface.tscn ------------------------------------------
	var gi_scene := load(scene_path).duplicate(true)
	
	return ResourceSaver.save(gi_scene, PopochiuResources.GUI_GAME_SCENE)


static func _create_progress_window() -> void:
	_progress_window = Window.new()
	_progress_window.borderless = true
	_progress_window.popup_window = true
	_progress_window.exclusive = true
	EditorInterface.get_base_control().add_child(_progress_window)
	
	var label := Label.new()
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	
	_animate_progress_text(label)
	
	var margin_container := MarginContainer.new()
	margin_container.add_child(label)
	margin_container.add_theme_constant_override("margin_top", 12)
	margin_container.add_theme_constant_override("margin_left", 12)
	margin_container.add_theme_constant_override("margin_bottom", 12)
	margin_container.add_theme_constant_override("margin_right", 12)
	
	var panel_container := PanelContainer.new()
	panel_container.add_child(margin_container)
	
	var style_box_flat := StyleBoxFlat.new()
	style_box_flat.bg_color = Color("2e2c9b")
	style_box_flat.border_color = Color("edf171")
	style_box_flat.set_border_width_all(4)
	style_box_flat.shadow_color = Color(Color.BLACK, 0.8)
	style_box_flat.shadow_offset = Vector2(0.0, 4.0)
	style_box_flat.shadow_size = 2
	
	panel_container.add_theme_stylebox_override("panel", style_box_flat)
	
	_progress_window.add_child(panel_container)
	_progress_window.popup_centered(_progress_window.get_contents_minimum_size())


static func _animate_progress_text(label: Label) -> void:
	if not is_instance_valid(label): return
	
	label.text = "Copying files to graphic interface folder... %s" % _progress_lines[_progress_idx]
	await EditorInterface.get_base_control().get_tree().create_timer(0.1).timeout
	
	_progress_idx = posmod(_progress_idx + 1, _progress_lines.size())
	_animate_progress_text(label)


static func _remove_components(dir_path: String) -> void:
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path + "/" + file_name)
		EditorInterface.get_resource_filesystem().scan()
	
	for dir_name: String in DirAccess.get_directories_at(dir_path):
		var sub_dir_path := dir_path + "/" + dir_name
		_remove_components(sub_dir_path)
	
	# Once the directory is empty, remove it
	DirAccess.remove_absolute(dir_path)
	EditorInterface.get_resource_filesystem().scan()


## Makes a copy of the components used by the original GUI template to the
## **res://game/graphic_interface/components/** folder so devs can play with those scenes without
## affecting the ones in the plugin's folder.
static func _copy_components(source_scene_path: String, is_gui_game_scene := false) -> void:
	var dependencies_to_update: Array[Dictionary] = []
	
	# Make a copy of the dependencies of the graphic interface
	for dep: String in ResourceLoader.get_dependencies(source_scene_path):
		var source_file_path := dep.get_slice("::", 2)
		
		if is_gui_game_scene and source_file_path.get_extension() == "gd"\
		and source_scene_path.get_base_dir() == source_file_path.get_base_dir():
			# Ignore the script of the GUI template scene file
			continue
		
		var source_file_uid := ResourceUID.id_to_text(
			ResourceLoader.get_resource_uid(source_file_path)
		)
		var dependency_data := {
			source_path = source_file_path,
			source_uid = source_file_uid,
			target_path = "",
		}
		
		# ---- Create the folder of the file -------------------------------------------------------
		var file_name := source_file_path.get_file()
		var source_folder := source_file_path.get_base_dir()
		
		var target_folder := source_folder.replace(PopochiuResources.GUI_ADDON_FOLDER, "")
		target_folder = target_folder.replace("templates/%s/" % _template_id, "")
		target_folder = PopochiuResources.GUI_GAME_FOLDER + target_folder
		
		dependency_data.target_path = "%s/%s" % [target_folder, file_name]
		dependencies_to_update.append(dependency_data)
		
		if FileAccess.file_exists(dependency_data.target_path):
			# Ignore any file that has already been copied
			continue
		
		if not DirAccess.dir_exists_absolute(target_folder):
			DirAccess.make_dir_recursive_absolute(target_folder)
		
		# --- Make a copy of the original file -----------------------------------------------------
		if source_file_path.get_extension() == "gd":
			_copy_script(source_file_path, target_folder, dependency_data.target_path)
		else:
			_copy_file(source_file_path, target_folder, dependency_data.target_path)
	
		EditorInterface.get_resource_filesystem().scan()
		await EditorInterface.get_resource_filesystem().filesystem_changed
		
		# Repeat the process for each of the dependencies of the .tscn resources
		if source_file_path.get_extension() == "tscn":
			await _copy_components(source_file_path)
	
	if is_gui_game_scene:
		_update_dependencies(PopochiuResources.GUI_GAME_SCENE, dependencies_to_update)
	else:
		var game_scene_path := source_scene_path.replace(PopochiuResources.GUI_ADDON_FOLDER, "")
		game_scene_path = game_scene_path.replace("templates/%s/" % _template_id, "")
		game_scene_path = PopochiuResources.GUI_GAME_FOLDER + game_scene_path
		
		_update_dependencies(game_scene_path, dependencies_to_update)
	
	EditorInterface.get_resource_filesystem().scan()
	await EditorInterface.get_resource_filesystem().filesystem_changed


static func _copy_script(
	source_file_path: String, _target_folder: String, target_file_path: String
) -> void:
	var file_write = FileAccess.open(target_file_path, FileAccess.WRITE)
	file_write.store_string('extends "%s"' % source_file_path)
	file_write.close()


static func _copy_file(
	source_file_path: String, target_folder: String, target_file_path: String
) -> void:
	# ---- Create a copy of the scene file -----------------------------------------------------
	if source_file_path.get_extension() in ["tscn", "tres"]:
		var file_resource := load(source_file_path).duplicate(true)
		
		if ResourceSaver.save(file_resource, target_file_path) != OK:
			DirAccess.remove_absolute(target_folder)
	else:
		DirAccess.copy_absolute(source_file_path, target_file_path)


## Replace the UID and paths of the components in the graphic interface scene
static func _update_dependencies(scene_path: String, dependencies_to_update: Array) -> void:
	if dependencies_to_update.is_empty():
		return
	
	# ---- Update the UID and paths of the copied components ---------------------------------------
	var file_read = FileAccess.open(scene_path, FileAccess.READ)
	var text := file_read.get_as_text()
	file_read.close()
	
	for dic: Dictionary in dependencies_to_update:
		text = text.replace(dic.source_path, dic.target_path)
		
		var target_uid := ResourceUID.id_to_text(
			ResourceLoader.get_resource_uid(dic.target_path)
		)
		
		if "invalid" in target_uid: continue
		
		text = text.replace(dic.source_uid, target_uid)
	
	var file_write = FileAccess.open(scene_path, FileAccess.WRITE)
	file_write.store_string(text)
	file_write.close()


## Copy the commands and graphic interface scripts of the chosen GUI template. The new graphic
## interface scripts inherits from the one originally assigned to the .tscn file of the selected
## template.
static func _copy_scripts(
	commands_template_path: String, commands_path: String, script_path: String, scene_path: String
) -> void:
	DirAccess.copy_absolute(commands_template_path, commands_path)
	
	# Create a copy of the graphic interface script template ---------------------------------------
	var template_path := PopochiuResources.GUI_TEMPLATES_FOLDER + "graphic_interface_template.gd"
	var script_file := FileAccess.open(template_path, FileAccess.READ)
	var source_code := script_file.get_as_text()
	script_file.close()
	source_code = source_code.replace(
		"extends PopochiuGraphicInterface",
		'extends "%s"' % scene_path.replace(".tscn", ".gd")
	)
	script_file = FileAccess.open(script_path, FileAccess.WRITE)
	script_file.store_string(source_code)
	script_file.close()


## Updates the script of the created **res://game/graphic_interface/graphic_interface.tscn** file so
## it uses the one created in `_copy_scripts(...)`.
static func _update_scene_script(script_path: String) -> int:
	# Update the script of the GUI -----------------------------------------------------------------
	var scene := (load(
		PopochiuResources.GUI_GAME_SCENE
	) as PackedScene).instantiate()
	scene.set_script(load(script_path))
	
	# Set the name of the root node
	scene.name = "GraphicInterface"
	
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(scene)
	
	return ResourceSaver.save(packed_scene, PopochiuResources.GUI_GAME_SCENE)


static func _update_settings_and_config(template_name: String, commands_path: String) -> void:
	var settings := PopochiuResources.get_settings()
	settings.graphic_interface = load(PopochiuResources.GUI_GAME_SCENE)
	PopochiuResources.save_settings(settings)
	
	# Update the info related to the GUI template and the GUI commands script
	# in the popochiu_data.cfg file ----------------------------------------------------------------
	PopochiuResources.set_data_value("ui", "template", template_name)
	PopochiuResources.set_data_value("ui", "commands", commands_path)
