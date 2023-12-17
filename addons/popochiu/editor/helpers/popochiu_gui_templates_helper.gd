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
	
	var scene_path := PopochiuResources.GRAPHIC_INTERFACE_ADDON
	var template_path :=\
	PopochiuResources.GRAPHIC_INTERFACE_TEMPLATES + "graphic_interface_template.gd"
	var commands_template_path := PopochiuResources.GRAPHIC_INTERFACE_TEMPLATES
	
	match template_name.to_snake_case():
		"simple_click":
			scene_path += "templates/simple_click/simple_click_gi.tscn"
			commands_template_path += "simple_click_commands_template.gd"
		"9_verb":
			scene_path += "templates/9_verb/9_verb_gi.tscn"
			commands_template_path += "9_verb_commands_template.gd"
		"sierra":
			scene_path += "templates/sierra/sierra_gi.tscn"
			commands_template_path += "sierra_commands_template.gd"
		"custom":
			scene_path += "popochiu_graphic_interface.tscn"
			commands_template_path += "custom_commands_template.gd"
	
	# Create the res://popochiu/graphic_interface/ folder
	if not FileAccess.file_exists(PopochiuResources.GRAPHIC_INTERFACE_GAME):
		DirAccess.make_dir_recursive_absolute(
			PopochiuResources.GRAPHIC_INTERFACE_GAME.get_base_dir()
		)
	else:
		# Remove the graphic_interface.tscn file
		DirAccess.remove_absolute(PopochiuResources.GRAPHIC_INTERFACE_GAME)
		
		#await EditorInterface.get_base_control().get_tree().create_timer(0.1).timeout
		#
		#OS.move_to_trash(
			#PopochiuResources.GRAPHIC_INTERFACE_GAME.get_base_dir() + "/components"
		#)
	
	await EditorInterface.get_base_control().get_tree().create_timer(0.1).timeout
	
	# Make a copy of the selected GUI template (.tscn) and save it as
	# res://popochiu/graphic_interface/graphic_interface.tscn ------------------
	DirAccess.copy_absolute(
		scene_path,
		PopochiuResources.GRAPHIC_INTERFACE_GAME
	)
	
	# Create a copy of the corresponding commands template ---------------------
	var commands_path := PopochiuResources.GRAPHIC_INTERFACE_GAME.replace(
		"graphic_interface.tscn", "commands.gd"
	)
	DirAccess.copy_absolute(commands_template_path, commands_path)
	
	# Create a copy of the graphic interface script template -------------------
	var script_path := PopochiuResources.GRAPHIC_INTERFACE_GAME.replace(".tscn", ".gd")
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
	
	# Create a copy of the GUI template resources ------------------------------
	# TODO: Create res://game/graphic_interface/resources
	# 		Move files (and directories) in the GUI template resources folder
	# 		to the created folder.
	
	# Update the script of the created graphic_interface.tscn so it uses the
	# copy created above -------------------------------------------------------
	var scene := (load(
		PopochiuResources.GRAPHIC_INTERFACE_GAME
	) as PackedScene).instantiate()
	scene.set_script(load(script_path))
	
	# Copy the components used by the template so devs can modify them ---------
	_copy_components(scene)
	
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(scene)
	
	if ResourceSaver.save(
		packed_scene, PopochiuResources.GRAPHIC_INTERFACE_GAME
	) != OK:
		PopochiuUtils.print_error(
			"[Popochiu] Couldn't update graphic_interface.tscn script"
		)
		
		return
	
	await EditorInterface.get_base_control().get_tree().create_timer(0.1).timeout
	
	# Save the GI template in Settings -----------------------------------------
	var settings := PopochiuResources.get_settings()
	settings.graphic_interface = load(PopochiuResources.GRAPHIC_INTERFACE_GAME)
	PopochiuResources.save_settings(settings)
	
	# Update the info related to the GUI template and the GUI commands script
	# in the popochiu_data.cfg file --------------------------------------------
	PopochiuResources.set_data_value("ui", "template", template_name)
	PopochiuResources.set_data_value("ui", "commands", commands_path)


static func _copy_components(graphic_interface_scene: Control) -> void:
	# Create the res://game/graphic_interface/components folder
	var components_path := PopochiuResources.GRAPHIC_INTERFACE_GAME.get_base_dir() + "/components"
	
	DirAccess.make_dir_recursive_absolute(components_path)
	
	for c: Node in graphic_interface_scene.get_children():
		if c.scene_file_path.is_empty(): continue
		
		#prints(c.name, c.scene_file_path.get_base_dir().split("/")[-1])
		var source_folder := c.scene_file_path.get_base_dir()
		var target_folder_name := source_folder.split("/")[-1]
		var target_folder := "%s/%s" % [components_path, target_folder_name]
		
		DirAccess.make_dir_recursive_absolute(target_folder)
		
		prints(c.name, ResourceLoader.get_dependencies(c.scene_file_path))
		
		for file_name: String in DirAccess.get_files_at(source_folder):
			DirAccess.copy_absolute(
				"%s/%s" % [source_folder, file_name],
				"%s/%s" % [target_folder, file_name]
			)
	
	#_fix_dependencies(
		#EditorInterface.get_resource_filesystem().get_filesystem_path(
			#PopochiuResources.GRAPHIC_INTERFACE_GAME.get_base_dir()
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
