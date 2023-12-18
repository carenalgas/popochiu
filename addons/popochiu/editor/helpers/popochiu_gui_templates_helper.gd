@tool
extends Resource
## Helper class for operations related to the GUI templates



## Create a copy of the selected template, including its components.
## Also, generate the necessary scripts to define custom logic for the graphical
## interface and its commands.
static func copy_gui_template(template_name: String) -> void:
	if template_name == PopochiuResources.get_data_value("ui", "template", ""):
		PopochiuUtils.print_normal("No changes in GUI tempalte.")
		return
	
	var scene_path := PopochiuResources.GUI_CUSTOM_SCENE
	var commands_template_path := PopochiuResources.GUI_CUSTOM_TEMPLATE
	
	match template_name.to_snake_case():
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
	
	# Copy the components used by the GUI template to the res://game/graphic_interface/components
	# folder so devs can play with them freely -----------------------------------------------------
	_copy_components(scene_path)
	
	# ---- Make a copy of the selected GUI template ------------------------------------------------
	_create_scene(scene_path)
	
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


static func _create_scene(scene_path: String) -> void:
	# Create the res://game/graphic_interface/ folder
	if not FileAccess.file_exists(PopochiuResources.GUI_GAME_SCENE):
		DirAccess.make_dir_recursive_absolute(
			PopochiuResources.GUI_GAME_SCENE.get_base_dir()
		)
	else:
		# Remove the graphic_interface.tscn file
		DirAccess.remove_absolute(PopochiuResources.GUI_GAME_SCENE)
	
	#await EditorInterface.get_base_control().get_tree().create_timer(0.1).timeout
	
	# Make a copy of the selected GUI template (.tscn) and save it in
	# res://game/graphic_interface/graphic_interface.tscn ------------------------------------------
	DirAccess.copy_absolute(
		scene_path,
		PopochiuResources.GUI_GAME_SCENE
	)


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


static func _update_scene_script(script_path: String) -> int:
	# Update the script of the GUI -----------------------------------------------------------------
	var scene := (load(
		PopochiuResources.GUI_GAME_SCENE
	) as PackedScene).instantiate()
	scene.set_script(load(script_path))
	
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(scene)
	
	return ResourceSaver.save(packed_scene, PopochiuResources.GUI_GAME_SCENE)


static func _copy_components(gui_template_scene_path: String) -> void:
	# Create the res://game/graphic_interface/components folder ------------------------------------
	var components_path := PopochiuResources.GUI_GAME_SCENE.get_base_dir() + "/components"
	DirAccess.make_dir_recursive_absolute(components_path)
	
	
	for dep in ResourceLoader.get_dependencies(gui_template_scene_path):
		#print(dep.get_slice("::", 0)) # Prints UID.
		print(dep.get_slice("::", 2)) # Prints path.
	
	#for c: Node in graphic_interface_scene.get_children():
		#if c.scene_file_path.is_empty(): continue
		#
		##prints(c.name, c.scene_file_path.get_base_dir().split("/")[-1])
		#var source_folder := c.scene_file_path.get_base_dir()
		#var target_folder_name := source_folder.split("/")[-1]
		#var target_folder := "%s/%s" % [components_path, target_folder_name]
		#
		#DirAccess.make_dir_recursive_absolute(target_folder)
		#
		#prints(c.name, ResourceLoader.get_dependencies(c.scene_file_path))
		#
		#for file_name: String in DirAccess.get_files_at(source_folder):
			#DirAccess.copy_absolute(
				#"%s/%s" % [source_folder, file_name],
				#"%s/%s" % [target_folder, file_name]
			#)
	
	#_fix_dependencies(
		#EditorInterface.get_resource_filesystem().get_filesystem_path(
			#PopochiuResources.GUI_GAME_SCENE.get_base_dir()
		#)
	#)
	#
	#await EditorInterface.get_base_control().get_tree().create_timer(0.1).timeout


static func _fix_dependencies(dir: EditorFileSystemDirectory) -> void:
	if not is_instance_valid(dir):
		return
	
	var fs := EditorInterface.get_resource_filesystem().get_filesystem()
	
	for f in dir.get_file_count():
		var path = dir.get_file_path(f)
		var dependencies = ResourceLoader.get_dependencies(path)
		
		for d in dependencies:
			if FileAccess.file_exists(d):
				continue
			
			_fix_dependency(d, fs, path)

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
				
				_fix_dependency(d, fs, path)
	
	EditorInterface.get_resource_filesystem().scan()


static func _fix_dependency(dependency, directory, resource_path):
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


static func _update_settings_and_config(template_name: String, commands_path: String) -> void:
	var settings := PopochiuResources.get_settings()
	settings.graphic_interface = load(PopochiuResources.GUI_GAME_SCENE)
	PopochiuResources.save_settings(settings)
	
	# Update the info related to the GUI template and the GUI commands script
	# in the popochiu_data.cfg file ----------------------------------------------------------------
	PopochiuResources.set_data_value("ui", "template", template_name)
	PopochiuResources.set_data_value("ui", "commands", commands_path)
