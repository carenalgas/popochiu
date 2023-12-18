@tool
extends Resource
## Helper class for operations related to the GUI templates

static var _components_path := PopochiuResources.GUI_GAME_SCENE.get_base_dir() + "/components"


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
	
	# ---- Make a copy of the selected GUI template ------------------------------------------------
	if _create_scene(scene_path) != OK:
		# TODO: Delete the graphic_interface folder and all its contents?
		PopochiuUtils.print_error(
			"[Popochiu] Couldn't create %s file" % PopochiuResources.GUI_GAME_SCENE
		)
		
		return
	
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
	
	# Copy the components used by the GUI template to the res://game/graphic_interface/components
	# folder so devs can play with them freely -----------------------------------------------------
	_copy_components(scene_path)
	
	# Save the GUI template in Settings and popochiu_data.cfg --------------------------------------
	_update_settings_and_config(template_name, commands_path)


## Create the **graphic_interface.tscn** file as a copy of the selected GUI template scene.
## If a template change is being made, all components of the previous template are removed along
## with the **.tscn** file before copying the new one.
static func _create_scene(scene_path: String) -> int:
	# Create the res://game/graphic_interface/ folder
	if not FileAccess.file_exists(PopochiuResources.GUI_GAME_SCENE):
		DirAccess.make_dir_recursive_absolute(
			PopochiuResources.GUI_GAME_SCENE.get_base_dir()
		)
	else:
		# Remove the graphic_interface.tscn file
		DirAccess.remove_absolute(PopochiuResources.GUI_GAME_SCENE)
		
		if DirAccess.dir_exists_absolute(_components_path):
			_remove_components(_components_path)
	
	#await EditorInterface.get_base_control().get_tree().create_timer(0.1).timeout
	EditorInterface.get_resource_filesystem().scan()
	
	# Make a copy of the selected GUI template (.tscn) and save it in
	# res://game/graphic_interface/graphic_interface.tscn ------------------------------------------
	var gi_scene := load(scene_path).duplicate(true)
	
	return ResourceSaver.save(gi_scene, PopochiuResources.GUI_GAME_SCENE)


static func _remove_components(dir_path: String) -> void:
	for dir_name: String in DirAccess.get_directories_at(dir_path):
		var sub_dir_path := dir_path + "/" + dir_name
		
		for file_name: String in DirAccess.get_files_at(sub_dir_path):
			DirAccess.remove_absolute(sub_dir_path + "/" + file_name)
			EditorInterface.get_resource_filesystem().scan()
		
		_remove_components(sub_dir_path)
	
	# Once the directory is empty, remove it
	DirAccess.remove_absolute(dir_path)
	EditorInterface.get_resource_filesystem().scan()


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
	
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(scene)
	
	return ResourceSaver.save(packed_scene, PopochiuResources.GUI_GAME_SCENE)


## Makes a copy of the components used by the original GUI template to the
## **res://game/graphic_interface/components/** folder so devs can play with those scenes without
## affecting the ones in the plugin's folder.
static func _copy_components(gui_template_scene_path: String) -> void:
	var dependencies_to_update: Array[Dictionary] = []
	
	# Create the res://game/graphic_interface/components folder ------------------------------------
	DirAccess.make_dir_recursive_absolute(_components_path)
	
	for dep: String in ResourceLoader.get_dependencies(gui_template_scene_path):
		var source_component_path := dep.get_slice("::", 2)
		
		if source_component_path.find(".tscn") == -1 and source_component_path.find(".png") == -1:
			continue
		
		# ---- Create the folder of the component --------------------------------------------------
		var file_name := source_component_path.get_file()
		var source_folder := source_component_path.get_base_dir()
		var target_folder_name := source_folder.split("/")[-1]
		var target_folder := "%s/%s" % [_components_path, target_folder_name]
		var target_component_path := "%s/%s" % [target_folder, file_name]
		
		DirAccess.make_dir_recursive_absolute(target_folder)
		
		# ---- Create a copy of the scene component ------------------------------------------------
		var component_resource := load(source_component_path).duplicate(true)
		var source_component_uid := ResourceUID.id_to_text(
			ResourceLoader.get_resource_uid(source_component_path)
		)
		
		if ResourceSaver.save(component_resource, target_component_path) != OK:
			DirAccess.remove_absolute(target_folder)
		
		# ---- Replace the UID and paths of the components in the graphic interface scene ----------
		var target_component_uid := ResourceUID.id_to_text(
			ResourceLoader.get_resource_uid(target_component_path)
		)
		
		EditorInterface.get_resource_filesystem().scan()
		
		prints({
			src_uid = source_component_uid,
			src_path = source_component_path,
			tar_uid = target_component_uid,
			tar_path = target_component_path
		})
		
		dependencies_to_update.append({
			src_uid = source_component_uid,
			src_path = source_component_path,
			tar_uid = target_component_uid,
			tar_path = target_component_path
		})
	
	# ---- Update the UID and paths of the copied components ---------------------------------------
	var file_read = FileAccess.open(PopochiuResources.GUI_GAME_SCENE, FileAccess.READ)
	var text = file_read.get_as_text()
	file_read.close()
	
	for dic: Dictionary in dependencies_to_update:
		text = text.replace(dic.src_uid, dic.tar_uid)
		text = text.replace(dic.src_path, dic.tar_path)
	
	var file_write = FileAccess.open(PopochiuResources.GUI_GAME_SCENE, FileAccess.WRITE)
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
