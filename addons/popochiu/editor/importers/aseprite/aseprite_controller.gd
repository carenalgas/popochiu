@tool
extends RefCounted


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func export_file(file_name: String, output_folder: String, options: Dictionary) -> Dictionary:
	var exception_pattern = options.get('exception_pattern', PopochiuEditorHelper.EMPTY_STRING)
	var only_visible_layers = options.get('only_visible_layers', false)
	var output_name = (
		file_name if options.get('output_filename') == PopochiuEditorHelper.EMPTY_STRING
		else options.get('output_filename', file_name)
	)
	var basename = _get_file_basename(output_name)
	var output_dir = output_folder.replace("res://", "./")
	var data_file = "%s/%s.json" % [output_dir, basename]
	var sprite_sheet = "%s/%s.png" % [output_dir, basename]
	var output = []
	var arguments = _export_command_common_arguments(file_name, data_file, sprite_sheet)

	if not only_visible_layers:
		arguments.push_front("--all-layers")

	_add_sheet_type_arguments(arguments, options)

	_add_ignore_layer_arguments(file_name, arguments, exception_pattern)

	var exit_code = _execute(arguments, output)
	if exit_code != 0:
		printerr('[Popochiu] Aseprite: failed to export spritesheet')
		printerr(output)
		return {}

	return {
		'data_file': data_file.replace("./", "res://"),
		"sprite_sheet": sprite_sheet.replace("./", "res://")
	}


func export_layers(file_name: String, output_folder: String, options: Dictionary) -> Array:
	var exception_pattern = options.get('exception_pattern', PopochiuEditorHelper.EMPTY_STRING)
	var only_visible_layers = options.get('only_visible_layers', false)
	var basename = _get_file_basename(file_name)
	var layers = list_layers(file_name, only_visible_layers)
	var exception_regex = _compile_regex(exception_pattern)

	var output = []

	for layer in layers:
		if layer != PopochiuEditorHelper.EMPTY_STRING and (not exception_regex or exception_regex.search(layer) == null):
			output.push_back(export_layer(file_name, layer, output_folder, options))

	return output


func export_layer(file_name: String, layer_name: String, output_folder: String, options: Dictionary) -> Dictionary:
	var output_prefix = options.get('output_filename', PopochiuEditorHelper.EMPTY_STRING).strip_edges()
	var output_dir = output_folder.replace("res://", "./").strip_edges()
	var data_file = "%s/%s%s.json" % [output_dir, output_prefix, layer_name]
	var sprite_sheet = "%s/%s%s.png" % [output_dir, output_prefix, layer_name]
	var output = []
	var arguments = _export_command_common_arguments(file_name, data_file, sprite_sheet)
	arguments.push_front(layer_name)
	arguments.push_front("--layer")
	
	_add_sheet_type_arguments(arguments, options)

	var exit_code = _execute(arguments, output)
	if exit_code != 0:
		printerr('[Popochiu] Aseprite: Failed to export layer spritesheet. Command output follows:')
		print(output)
		return {}

	return {
		'data_file': data_file.replace("./", "res://"),
		"sprite_sheet": sprite_sheet.replace("./", "res://")
	}


# IMPROVE: See if we can extract JSON data limited to the single tag
# (so we don't have to reckon offset framerange)
func export_tag(file_name: String, tag_name: String, output_folder: String, options: Dictionary) -> Dictionary:
	var output_prefix = options.get('output_filename', PopochiuEditorHelper.EMPTY_STRING).strip_edges()
	var output_dir = output_folder.replace("res://", "./").strip_edges()
	var data_file = "%s/%s%s.json" % [output_dir, output_prefix, tag_name]
	var sprite_sheet = "%s/%s%s.png" % [output_dir, output_prefix, tag_name]
	var output = []
	var arguments = _export_command_common_arguments(file_name, data_file, sprite_sheet)
	arguments.push_front(tag_name)
	arguments.push_front("--tag")

	_add_sheet_type_arguments(arguments, options)

	var exit_code = _execute(arguments, output)
	if exit_code != 0:
		printerr('[Popochiu] Aseprite: Failed to export tag spritesheet. Command output follows:')
		print(output)
		return {}

	return {
		'data_file': data_file.replace("./", "res://"),
		"sprite_sheet": sprite_sheet.replace("./", "res://")
	}


# Exports the frames inside the given [from, to] range into a single spritesheet.
# Used to import a "group tag": one prop with several animations, where the
# spritesheet only contains the frames covered by the group's range.
func export_frame_range(
	file_name: String, name: String, from: int, to: int, output_folder: String, options: Dictionary
) -> Dictionary:
	var output_prefix = options.get('output_filename', PopochiuEditorHelper.EMPTY_STRING).strip_edges()
	var output_dir = output_folder.replace("res://", "./").strip_edges()
	var data_file = "%s/%s%s.json" % [output_dir, output_prefix, name]
	var sprite_sheet = "%s/%s%s.png" % [output_dir, output_prefix, name]
	var output = []
	var arguments = _export_command_common_arguments(file_name, data_file, sprite_sheet)
	arguments.push_front("%d,%d" % [from, to])
	arguments.push_front("--frame-range")

	_add_sheet_type_arguments(arguments, options)

	var exit_code = _execute(arguments, output)
	if exit_code != 0:
		printerr('[Popochiu] Aseprite: Failed to export frame range spritesheet. Command output follows:')
		print(output)
		return {}

	return {
		'data_file': data_file.replace("./", "res://"),
		"sprite_sheet": sprite_sheet.replace("./", "res://")
	}


func list_layers(file_name: String, only_visible = false) -> Array:
	var output = []
	var arguments = ["-b", "--list-layers", file_name]

	if not only_visible:
		arguments.push_front("--all-layers")

	var exit_code = _execute(arguments, output)

	if exit_code != 0:
		printerr('[Popochiu] Aseprite: failed listing layers')
		printerr(output)
		return []

	return _sanitize_list_output(output)


func list_tags(file_name: String) -> Array:
	var output = []
	var arguments = ["-b", "--list-tags", file_name]

	var exit_code = _execute(arguments, output)

	if exit_code != 0:
		printerr('[Popochiu] Aseprite: failed listing tags')
		printerr(output)
		return []

	return _sanitize_list_output(output)


# Lists the tags of a file together with their frame ranges and direction.
# `--list-tags` alone only prints tag names, so we export a throwaway spritesheet
# and read the `meta.frameTags` from its JSON. This is what the importer dock
# needs to detect "group tags".
# Falls back to name-only tags whenever the ranges can't be obtained, so the
# scan always shows the tag list.
func list_tags_with_ranges(file_name: String) -> Array:
	var tags := _fetch_tags_with_ranges(file_name)

	# Fallback: if we couldn't get the frame ranges, at least return the tag
	# names so the importer still works (groups just won't be detected).
	if tags.is_empty():
		var names := list_tags(file_name)
		if not names.is_empty():
			printerr('[Popochiu] Aseprite: could not read tag frame ranges; groups will not be detected')
		for name in names:
			if not name.is_empty():
				tags.push_back({ "tag_name": name })

	return tags


func is_valid_spritesheet(content):
	return content.has("frames") and content.has("meta") and content.meta.has('image')


func get_content_frames(content):
	return content.frames if typeof(content.frames) == TYPE_ARRAY  else content.frames.values()


func get_content_meta_tags(content):
	return content.meta.frameTags if content.meta.has("frameTags")  else []


func check_command_path():
	# On Linux, MacOS or other *nix platforms, nothing to do
	if not OS.get_name() in ["Windows", "UWP"]:
		return true
	
	# On Windows, OS.Execute() calls trigger an uncatchable
	# internal error if the invoked executable is not found.
	# Since the error is unclear, we have to check that the aseprite
	# command is given as a full path and return an error if it's not.
	var regex = RegEx.new()
	regex.compile("^[A-Z|a-z]:[\\\\|\\/].+\\.exe$")
	return \
		regex.search(_get_aseprite_command()) \
		and \
		FileAccess.file_exists(_get_aseprite_command())


func test_command():
	var exit_code = OS.execute(_get_aseprite_command(), ['--version'], [], true)
	return exit_code == 0



# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _add_ignore_layer_arguments(file_name: String, arguments: Array, exception_pattern: String) -> void:
	var layers = _get_exception_layers(file_name, exception_pattern)
	if not layers.is_empty():
		for l in layers:
			arguments.push_front(l)
			arguments.push_front('--ignore-layer')


func _add_sheet_type_arguments(arguments: Array, options : Dictionary) -> void:
	var column_count : int = options.get("column_count", 0)
	if column_count > 0:
		arguments.push_back("--merge-duplicates") # Yes, this is undocumented
		arguments.push_back("--sheet-columns")
		arguments.push_back(column_count)
	else:
		arguments.push_back("--sheet-pack")


func _get_exception_layers(file_name: String, exception_pattern: String) -> Array:
	var layers = list_layers(file_name)
	var regex = _compile_regex(exception_pattern)
	if regex == null:
		return []

	var exception_layers = []
	for layer in layers:
		if regex.search(layer) != null:
			exception_layers.push_back(layer)

	return exception_layers


func _sanitize_list_output(output) -> Array:
	if output.is_empty():
		return output
	
	var raw = output[0].split('\n')
	var sanitized = []
	for s in raw:
		sanitized.append(s.strip_edges())
	return sanitized


func _export_command_common_arguments(source_name: String, data_path: String, spritesheet_path: String) -> Array:
	return [
		"-b",
		"--list-tags",
		"--data",
		data_path,
		"--format",
		"json-array",
		"--sheet",
		spritesheet_path,
		source_name
	]


func _execute(arguments, output) -> int:
	return OS.execute(_get_aseprite_command(), arguments, output, true, true)


func _get_aseprite_command() -> String:
	return PopochiuEditorConfig.get_command()


func _get_file_basename(file_path: String) -> String:
	return file_path.get_file().trim_suffix('.%s' % file_path.get_extension())


func _compile_regex(pattern):
	if pattern == PopochiuEditorHelper.EMPTY_STRING:
		return

	var rgx = RegEx.new()
	if rgx.compile(pattern) == OK:
		return rgx

	printerr('[Popochiu] exception regex error')


# Exports only the sprite metadata (no sheet, so it is fast) and reads the tag
# frame ranges from it. Returns an empty array on any failure.
# The export is written to the project folder using relative paths (the same
# style as the working import exports), because some sandboxed Aseprite
# installs cannot write to the OS temp directory.
func _fetch_tags_with_ranges(file_name: String) -> Array:
	var temp_name := "popochiu_tags_%d_%d" % [Time.get_ticks_msec(), randi()]
	var data_file := "res://%s.json" % temp_name
	var output := []
	var arguments := [
		"-b",
		"--list-tags",
		"--data",
		"./%s.json" % temp_name,
		"--format",
		"json-array",
		file_name,
	]

	var tags := []
	var exit_code := _execute(arguments, output)
	if exit_code != 0:
		printerr('[Popochiu] Aseprite: failed to export tags metadata (exit code %d)' % exit_code)
		printerr(output)
	elif not FileAccess.file_exists(data_file):
		printerr('[Popochiu] Aseprite: export succeeded but no JSON data file was produced at %s' % data_file)
	elif FileAccess.file_exists(data_file):
		var file := FileAccess.open(data_file, FileAccess.READ)
		if file != null:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				for ft in json.data.get("meta", {}).get("frameTags", []):
					tags.push_back({
						"tag_name": ft.name,
						"from": ft.from,
						"to": ft.to,
						"direction": ft.direction,
					})
				if tags.is_empty():
					printerr('[Popochiu] Aseprite: no frame tags found in the exported metadata')
			else:
				printerr('[Popochiu] Aseprite: could not parse the exported JSON metadata')
			file.close()

	# Always clean up the throwaway file
	if FileAccess.file_exists(data_file):
		DirAccess.remove_absolute(data_file)
	return tags

