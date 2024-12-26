@tool
extends Resource
## Helper class for operations related to the GUI templates

static var _template_id := ""
static var _template_theme_path := ""

#region Public #####################################################################################
## Creates a copy of the selected template, including its components. Also generate the necessary
## scripts to define custom logic for the graphical interface and its commands.
static func copy_gui_template(
	template_name: String, on_progress: Callable, on_complete: Callable
) -> void:
	if (
		DirAccess.dir_exists_absolute(PopochiuResources.GUI_GAME_FOLDER)
		and template_name == PopochiuResources.get_data_value("ui", "template", "")
	):
		PopochiuUtils.print_normal("No changes in GUI template.")
		
		on_complete.call()
		return
	
	on_progress.call(0, "Starting GUI template application")
	
	_template_theme_path = ""
	
	var scene_path := PopochiuResources.GUI_CUSTOM_SCENE
	var commands_template_path := PopochiuResources.GUI_CUSTOM_TEMPLATE
	
	_template_id = template_name.to_snake_case()
	
	if _template_id != PopochiuResources.GUI_CUSTOM:
		scene_path = PopochiuResources.GUI_TEMPLATES_FOLDER.path_join(
			"%s/%s_gui.tscn" % [_template_id, _template_id]
		)
		commands_template_path = PopochiuResources.GUI_SCRIPT_TEMPLATES_FOLDER.path_join(
			"%s_commands_template.gd" % _template_id
		)
	
	var script_path := PopochiuResources.GUI_GAME_SCENE.replace(".tscn", ".gd")
	
	await _wait()
	on_progress.call(5, "Creating Graphic Interface scene")
	
	# ---- Make a copy of the selected GUI template ------------------------------------------------
	if _create_scene(scene_path) != OK:
		PopochiuUtils.print_error("Couldn't create %s file" % PopochiuResources.GUI_GAME_SCENE)
		return
	
	await _wait(2.0)
	on_progress.call(10, "Copying a bunch of components")
	
	# Copy the components used by the GUI template to the res://game/gui/components
	# folder so devs can play with them freely -----------------------------------------------------
	await copy_components(scene_path, true)
	
	on_progress.call(60, "Creating scripts")
	
	# Create a copy of the corresponding commands template -----------------------------------------
	_copy_commands_and_gui_scripts(
		commands_template_path, PopochiuResources.GUI_COMMANDS, script_path, scene_path
	)
	
	await _wait(1.5)
	on_progress.call(80, "Assigning scripts")
	
	# Update the script of the created gui.tscn so it uses the copy created above ------------------
	if _update_scene_script(script_path) != OK:
		PopochiuUtils.print_error("Couldn't update gui.tscn script")
		return
	
	await _wait()
	on_progress.call(90, "Updating config file")
	
	# Update the info related to the GUI template and the GUI commands script
	# in the popochiu_data.cfg file ----------------------------------------------------------------
	PopochiuResources.set_data_value("ui", "template", template_name)
	await _wait(0.8)
	
	on_progress.call(100, "All in place. Thanks for your patience.")
	PopochiuUtils.print_normal("[wave]Selected GUI template successfully applied[/wave]")
	await _wait()
	await PopochiuEditorHelper.filesystem_scanned()
	
	on_complete.call()


static func copy_component(source_scene_path: String) -> String:
	var file_name := source_scene_path.get_file()
	var source_folder := source_scene_path.get_base_dir()
	
	var target_folder := source_folder.replace(PopochiuResources.GUI_ADDON_FOLDER, "")
	target_folder = PopochiuResources.GUI_GAME_FOLDER + target_folder
	
	if not DirAccess.dir_exists_absolute(target_folder):
		DirAccess.make_dir_recursive_absolute(target_folder)
	
	# Make a copy of the component and save it in the graphic interface components folder
	var component_instance := (load(source_scene_path) as PackedScene).instantiate()
	var target_scene_file := "%s/%s" % [target_folder, file_name]
	
	var packed_scene := PackedScene.new()
	packed_scene.pack(component_instance)
	packed_scene.resource_path = target_scene_file
	
	var err := ResourceSaver.save(packed_scene, target_scene_file)
	
	if err != OK:
		PopochiuUtils.print_error(
			"Couldn't create instance of %s component. Error code: %d." % [
				file_name.get_slice(".", 0).capitalize(),
				err
			]
		)
		
		return ""
	
	# Move the dependencies of the source scene to the graphic interface folder
	await copy_components(source_scene_path)
	
	return target_scene_file


## Makes a copy of the components used by the original GUI template to the
## **res://game/gui/components/** folder so devs can play with those scenes without
## affecting the ones in the plugin's folder.
static func copy_components(source_scene_path: String, is_gui_game_scene := false) -> void:
	var dependencies_to_update: Array[Dictionary] = []
	
	# Make a copy of the dependencies of the graphic interface
	for dep: String in ResourceLoader.get_dependencies(source_scene_path):
		var source_file_path := dep.get_slice("::", 2)
		
		if (
			is_gui_game_scene and source_file_path.get_extension() == "gd"
			and source_scene_path.get_base_dir() == source_file_path.get_base_dir()
		):
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
		
		# Make sure all the copied components share the copied GUI theme
		if source_file_path.get_extension() == "tres" and "_theme" in source_file_path:
			if is_gui_game_scene and _template_theme_path.is_empty():
				# Change the name of the GUI template theme so it differs from the original one
				dependency_data.target_path = "%s/%s" % [
					target_folder, "gui_theme.tres"
				]
				_template_theme_path = dependency_data.target_path
			elif not is_gui_game_scene:
				dependency_data.target_path = _template_theme_path
		
		dependencies_to_update.append(dependency_data)
		
		if FileAccess.file_exists(dependency_data.target_path):
			# Ignore any file that has already been copied
			continue
		
		if not DirAccess.dir_exists_absolute(target_folder):
			DirAccess.make_dir_recursive_absolute(target_folder)
		
		# --- Make a copy of the original file -----------------------------------------------------
		if source_file_path.get_extension() == "gd":
			_copy_component_script(source_file_path, dependency_data.target_path)
		else:
			_copy_file(source_file_path, target_folder, dependency_data.target_path)
	
		EditorInterface.get_resource_filesystem().scan()
		await EditorInterface.get_resource_filesystem().filesystem_changed
		
		# Repeat the process for each of the dependencies of the .tscn resources
		if source_file_path.get_extension() == "tscn":
			await copy_components(source_file_path)
	
	if is_gui_game_scene:
		_update_dependencies(PopochiuResources.GUI_GAME_SCENE, dependencies_to_update)
	else:
		var game_scene_path := source_scene_path.replace(PopochiuResources.GUI_ADDON_FOLDER, "")
		game_scene_path = game_scene_path.replace("templates/%s/" % _template_id, "")
		game_scene_path = PopochiuResources.GUI_GAME_FOLDER + game_scene_path
		
		_update_dependencies(game_scene_path, dependencies_to_update)
	
	EditorInterface.get_resource_filesystem().scan()
	await EditorInterface.get_resource_filesystem().filesystem_changed


#endregion

#region Private ####################################################################################
## Create the **gui.tscn** file as a copy of the selected GUI template scene.
## If a template change is being made, all components of the previous template are removed along
## with the **.tscn** file before copying the new one.
static func _create_scene(scene_path: String) -> int:
	# Create the res://game/gui/ folder
	if not FileAccess.file_exists(PopochiuResources.GUI_GAME_SCENE):
		DirAccess.make_dir_recursive_absolute(PopochiuResources.GUI_GAME_FOLDER)
	else:
		# Remove the gui.tscn file
		DirAccess.remove_absolute(PopochiuResources.GUI_GAME_SCENE)
		EditorInterface.get_resource_filesystem().scan()
		
		for dir_name: String in DirAccess.get_directories_at(PopochiuResources.GUI_GAME_FOLDER):
			_remove_components(PopochiuResources.GUI_GAME_FOLDER + dir_name)
	
	# Make a copy of the selected GUI template (.tscn) and save it in
	# res://game/gui/gui.tscn ------------------------------------------
	var gi_scene := load(scene_path).duplicate(true)
	gi_scene.resource_path = PopochiuResources.GUI_GAME_SCENE
	
	return ResourceSaver.save(gi_scene, PopochiuResources.GUI_GAME_SCENE)


static func _remove_components(dir_path: String) -> void:
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(file_name))
		EditorInterface.get_resource_filesystem().scan()
	
	for dir_name: String in DirAccess.get_directories_at(dir_path):
		var sub_dir_path := dir_path.path_join(dir_name)
		_remove_components(sub_dir_path)
	
	# Once the directory is empty, remove it
	DirAccess.remove_absolute(dir_path)
	EditorInterface.get_resource_filesystem().scan()


## Makes a copy of a GUI component's script.
static func _copy_component_script(
	source_file_path: String, target_file_path: String
) -> void:
	# Make a copy of the original script -----------------------------------------------------------
	var source_file := FileAccess.open(source_file_path, FileAccess.READ)
	var source_code := source_file.get_as_text()
	source_file.close()
	
	if "class_name " in source_code:
		source_code = source_code.replace("class_name Popochiu", "class_name GUI")
	
	var file_write := FileAccess.open(target_file_path, FileAccess.WRITE)
	file_write.store_string(source_code)
	file_write.close()
	
	# Create a script for devs to overwrite the functionality of the original's copy script --------
	file_write = FileAccess.open(target_file_path.replace(".gd", "_custom.gd"), FileAccess.WRITE)
	if "@tool" in source_code:
		file_write.store_string("@tool\n")
	file_write.store_string('extends "%s"' % target_file_path.get_file())


static func _copy_file(
	source_file_path: String, target_folder: String, target_file_path: String
) -> void:
	# ---- Create a copy of the scene file ---------------------------------------------------------
	if source_file_path.get_extension() in ["tscn", "tres"]:
		var file_resource := load(source_file_path).duplicate(true)
		file_resource.resource_path = target_file_path
		
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
		var target_path: String = dic.target_path
		
		if ".gd" in target_path:
			target_path = target_path.replace(".gd", "_custom.gd")
		
		text = text.replace(dic.source_path, target_path)
		
		var target_uid := ResourceUID.id_to_text(ResourceLoader.get_resource_uid(target_path))
		
		if "invalid" in target_uid: continue
		
		text = text.replace(dic.source_uid, target_uid)
	
	var file_write = FileAccess.open(scene_path, FileAccess.WRITE)
	file_write.store_string(text)
	file_write.close()


## Copy the commands and graphic interface scripts of the chosen GUI template. The new graphic
## interface scripts inherits from the one originally assigned to the .tscn file of the selected
## template.
static func _copy_commands_and_gui_scripts(
	commands_template_path: String, commands_path: String, script_path: String, scene_path: String
) -> void:
	DirAccess.copy_absolute(commands_template_path, commands_path)
	
	# Create a copy of the graphic interface script template ---------------------------------------
	var template_path := (
		PopochiuResources.GUI_SCRIPT_TEMPLATES_FOLDER + "gui_template.gd"
	)
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


## Updates the script of the created [b]res://game/gui/gui.tscn[/b] file so it uses the one created
## in [method _copy_commands_and_gui_scripts].
static func _update_scene_script(script_path: String) -> int:
	# Update the script of the GUI -----------------------------------------------------------------
	var scene := (load(
		PopochiuResources.GUI_GAME_SCENE
	) as PackedScene).instantiate()
	scene.set_script(load(script_path))
	
	# Set the name of the root node
	scene.name = "GUI"
	
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(scene)
	packed_scene.resource_path = PopochiuResources.GUI_GAME_SCENE
	
	return ResourceSaver.save(packed_scene, PopochiuResources.GUI_GAME_SCENE)


static func _wait(max := 1.0) -> void:
	await PopochiuEditorHelper.secs_passed(randf_range(0.5, max))


#endregion
