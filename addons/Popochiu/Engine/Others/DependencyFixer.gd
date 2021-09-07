tool
extends EditorScript


func _run():
	var interface = get_editor_interface()
	var filesys = interface.get_resource_filesystem()
	var dir = filesys.get_filesystem_path(get_editor_interface().get_selected_path())
	
	var res = filesys.get_filesystem()

	for f in dir.get_file_count():
		var path = dir.get_file_path(f)
		var dependencies = ResourceLoader.get_dependencies(path)
		var file = File.new()

		for d in dependencies:
			if file.file_exists(d):
				continue
			fix_dependency(d, res, path)

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
				fix_dependency(d, res, path)
	get_editor_interface().get_resource_filesystem().scan()


func fix_dependency(dependency, directory, resource_path):
	for subdir in directory.get_subdir_count():
		fix_dependency(dependency, directory.get_subdir(subdir), resource_path)

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
