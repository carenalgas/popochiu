@tool
extends RefCounted

# Largest sheet side we let a grid layout reach before adding more columns.
# Matches the usual texture limit Godot targets on desktop.
const MAX_SHEET_DIMENSION := 16384

# Aseprite executable path, resolved on the main thread before dispatching a task.
# Worker threads must not read the EditorSettings singleton, so the blocking
# helpers use this cached value instead of querying the settings themselves.
var _command: String = PopochiuEditorHelper.EMPTY_STRING

# Frame layout cached per source file, so importing many tags from one sheet only
# probes it once. Entries carry the file's modified time and size for validation.
var _sheet_layout_cache: Dictionary = {}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func export_file(file_name: String, output_folder: String, options: Dictionary) -> Dictionary:
	return await _dispatch(
		_export_file_blocking.bind(file_name, output_folder, options)
	)


func _export_file_blocking(
	file_name: String, output_folder: String, options: Dictionary
) -> Dictionary:
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

	_add_sheet_type_arguments(file_name, arguments, options)

	_add_ignore_layer_arguments(file_name, arguments, exception_pattern)

	var exit_code = _execute(arguments, output)
	if exit_code != 0:
		printerr('[Popochiu] Aseprite: failed to export spritesheet')
		printerr(output)
		return {}

	return _export_result(data_file, sprite_sheet)


func export_layers(file_name: String, output_folder: String, options: Dictionary) -> Array:
	return await _dispatch(
		_export_layers_blocking.bind(file_name, output_folder, options)
	)


func _export_layers_blocking(
	file_name: String, output_folder: String, options: Dictionary
) -> Array:
	var exception_pattern = options.get('exception_pattern', PopochiuEditorHelper.EMPTY_STRING)
	var only_visible_layers = options.get('only_visible_layers', false)
	var layers = _list_layers_blocking(file_name, only_visible_layers)
	var exception_regex = _compile_regex(exception_pattern)

	var output = []

	for layer in layers:
		if (
			layer != PopochiuEditorHelper.EMPTY_STRING
			and (not exception_regex or exception_regex.search(layer) == null)
		):
			output.push_back(_export_layer_blocking(file_name, layer, output_folder, options))

	return output


func export_layer(
	file_name: String, layer_name: String, output_folder: String, options: Dictionary
) -> Dictionary:
	return await _dispatch(
		_export_layer_blocking.bind(file_name, layer_name, output_folder, options)
	)


func _export_layer_blocking(
	file_name: String, layer_name: String, output_folder: String, options: Dictionary
) -> Dictionary:
	return _export_with_selector(
		["--layer", layer_name], layer_name, file_name, output_folder, options
	)


# IMPROVE: See if we can extract JSON data limited to the single tag
# (so we don't have to reckon offset framerange)
func export_tag(
	file_name: String, tag_name: String, output_folder: String, options: Dictionary
) -> Dictionary:
	return await _dispatch(
		_export_tag_blocking.bind(file_name, tag_name, output_folder, options)
	)


func _export_tag_blocking(
	file_name: String, tag_name: String, output_folder: String, options: Dictionary
) -> Dictionary:
	return _export_with_selector(
		["--tag", tag_name], tag_name, file_name, output_folder, options
	)


# Exports the frames inside the given [from, to] range into a single spritesheet.
# Used to import a "group tag": one prop with several animations, where the
# spritesheet only contains the frames covered by the group's range.
func export_frame_range(
	file_name: String, name: String, from: int, to: int, output_folder: String, options: Dictionary
) -> Dictionary:
	return await _dispatch(
		_export_frame_range_blocking.bind(file_name, name, from, to, output_folder, options)
	)


func _export_frame_range_blocking(
	file_name: String, name: String, from: int, to: int, output_folder: String, options: Dictionary
) -> Dictionary:
	return _export_with_selector(
		["--frame-range", "%d,%d" % [from, to]], name, file_name, output_folder, options
	)


func list_layers(file_name: String, only_visible: bool = false) -> Array:
	return await _dispatch(_list_layers_blocking.bind(file_name, only_visible))


func _list_layers_blocking(file_name: String, only_visible: bool = false) -> Array:
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
	return await _dispatch(_list_tags_blocking.bind(file_name))


func _list_tags_blocking(file_name: String) -> Array:
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
	return await _dispatch(_list_tags_with_ranges_blocking.bind(file_name))


func _list_tags_with_ranges_blocking(file_name: String) -> Array:
	var tags := _fetch_tags_with_ranges(file_name)

	# Fallback: if we couldn't get the frame ranges, at least return the tag
	# names so the importer still works (groups just won't be detected).
	if tags.is_empty():
		var names := _list_tags_blocking(file_name)
		if not names.is_empty():
			PopochiuUtils.print_error('Aseprite: could not read tag frame ranges; groups will not be detected')
		for name: String in names:
			if not name.is_empty():
				tags.push_back({ "tag_name": name })

	return tags


func is_valid_spritesheet(content: Dictionary) -> bool:
	return content.has("frames") and content.has("meta") and content.meta.has('image')


func get_content_frames(content: Dictionary) -> Array:
	return content.frames if typeof(content.frames) == TYPE_ARRAY else content.frames.values()


func get_content_meta_tags(content: Dictionary) -> Array:
	return content.meta.frameTags if content.meta.has("frameTags") else []


func check_command_path() -> bool:
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


func test_command() -> bool:
	return OS.execute(_get_aseprite_command(), ['--version'], [], true) == 0



# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
# Runs an Aseprite export that targets part of the file (a layer, a tag or a
# frame range), writing the spritesheet to files named after [param output_name],
# and returns the {'data_file', 'sprite_sheet'} dictionary (or {} on failure).
# [param selector_args] are prepended to the Aseprite command, e.g.
# ["--tag", "Run"].
func _export_with_selector(
	selector_args: Array,
	output_name: String,
	file_name: String,
	output_folder: String,
	options: Dictionary
) -> Dictionary:
	var output_prefix: String = options.get(
		'output_filename', PopochiuEditorHelper.EMPTY_STRING
	).strip_edges()
	var output_dir := output_folder.replace("res://", "./").strip_edges()
	var data_file := "%s/%s%s.json" % [output_dir, output_prefix, output_name]
	var sprite_sheet := "%s/%s%s.png" % [output_dir, output_prefix, output_name]
	var output := []
	var arguments := selector_args + _export_command_common_arguments(
		file_name, data_file, sprite_sheet
	)

	_add_sheet_type_arguments(file_name, arguments, options)

	var exit_code := _execute(arguments, output)
	if exit_code != 0:
		PopochiuUtils.print_error(
			'Aseprite: failed to export spritesheet for "%s". Command output follows:'
			% output_name
		)
		print(output)
		return {}

	return _export_result(data_file, sprite_sheet)


# Builds the dictionary returned by the export functions from the generated
# data and sprite sheet files (paths are converted back to res://).
func _export_result(data_file: String, sprite_sheet: String) -> Dictionary:
	return {
		'data_file': data_file.replace("./", "res://"),
		"sprite_sheet": sprite_sheet.replace("./", "res://")
	}


func _add_ignore_layer_arguments(
	file_name: String, arguments: Array, exception_pattern: String
) -> void:
	var layers = _get_exception_layers(file_name, exception_pattern)
	if not layers.is_empty():
		for l in layers:
			arguments.push_front(l)
			arguments.push_front('--ignore-layer')


func _add_sheet_type_arguments(file_name: String, arguments: Array, options: Dictionary) -> void:
	var column_count := _resolve_column_count(file_name, options)

	if column_count > 0:
		arguments.push_back("--merge-duplicates") # Yes, this is undocumented
		arguments.push_back("--sheet-columns")
		arguments.push_back(column_count)
	else:
		# Fallback: Aseprite's bin packer is valid but can take minutes on sheets
		# with many frames. Only used when the frame layout can't be determined.
		arguments.push_back("--sheet-pack")


# Returns the number of columns for the grid layout. Callers can force one via the
# "column_count" option; otherwise it is derived from the source's frame count and
# frame size so the sheet stays roughly square and within MAX_SHEET_DIMENSION.
func _resolve_column_count(file_name: String, options: Dictionary) -> int:
	var configured: int = options.get("column_count", 0)
	if configured > 0:
		return configured

	var layout := _fetch_sheet_layout(file_name)
	return _compute_column_count(
		layout.get("frame_count", 0),
		layout.get("frame_width", 0),
		layout.get("frame_height", 0)
	)


func _compute_column_count(frame_count: int, frame_width: int, frame_height: int) -> int:
	if frame_count <= 0 or frame_width <= 0 or frame_height <= 0:
		return 0

	# Aim for a roughly square sheet, then keep both sides within the limit.
	var aspect := float(frame_width) / float(frame_height)
	var columns := int(ceil(sqrt(float(frame_count) * aspect)))
	columns = mini(columns, floori(float(MAX_SHEET_DIMENSION) / frame_width))

	var max_rows := floori(float(MAX_SHEET_DIMENSION) / frame_height)
	columns = maxi(columns, int(ceil(float(frame_count) / float(max_rows))))

	return clampi(columns, 1, frame_count)


func _get_exception_layers(file_name: String, exception_pattern: String) -> Array:
	var layers = _list_layers_blocking(file_name)
	var regex = _compile_regex(exception_pattern)
	if regex == null:
		return []

	var exception_layers = []
	for layer in layers:
		if regex.search(layer) != null:
			exception_layers.push_back(layer)

	return exception_layers


func _sanitize_list_output(output: Array) -> Array:
	if output.is_empty():
		return output

	var raw = output[0].split('\n')
	var sanitized = []
	for s in raw:
		sanitized.append(s.strip_edges())
	return sanitized


func _export_command_common_arguments(
	source_name: String, data_path: String, spritesheet_path: String
) -> Array:
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


# Resolves the Aseprite command on the main thread, then runs [param work] on a
# worker task. Every public method funnels through here so the blocking bodies
# never read the editor settings themselves.
func _dispatch(work: Callable) -> Variant:
	_command = _get_aseprite_command()
	return await PopochiuWorker.run(work)


func _execute(arguments: Array, output: Array) -> int:
	return OS.execute(_command, arguments, output, true, true)


func _get_aseprite_command() -> String:
	return PopochiuEditorConfig.get_command()


func _get_file_basename(file_path: String) -> String:
	return file_path.get_file().trim_suffix('.%s' % file_path.get_extension())


func _compile_regex(pattern: String) -> RegEx:
	if pattern == PopochiuEditorHelper.EMPTY_STRING:
		return null

	var rgx = RegEx.new()
	if rgx.compile(pattern) == OK:
		return rgx

	printerr('[Popochiu] exception regex error')
	return null


# Exports only the sprite metadata (no sheet, so it is fast) and reads the tag
# frame ranges from it. Returns an empty array on any failure.
func _fetch_tags_with_ranges(file_name: String) -> Array:
	var tags := []
	var content := _fetch_metadata(file_name)
	if content.is_empty():
		return tags

	for ft in content.get("meta", {}).get("frameTags", []):
		tags.push_back({
			"tag_name": ft.name,
			"from": ft.from,
			"to": ft.to,
			"direction": ft.direction,
		})

	if tags.is_empty():
		PopochiuUtils.print_error('Aseprite: no frame tags found in the exported metadata')
	return tags


# Returns the cached frame layout for the source file, probing it only when the
# file is new or changed. See _probe_sheet_layout.
func _fetch_sheet_layout(file_name: String) -> Dictionary:
	var entry: Dictionary = _sheet_layout_cache.get(file_name, {})
	if not entry.is_empty() and _is_layout_cache_valid(file_name, entry):
		return entry.layout

	var layout := _probe_sheet_layout(file_name)
	_sheet_layout_cache[file_name] = {
		"modified_time": FileAccess.get_modified_time(file_name),
		"file_size": _file_size(file_name),
		"layout": layout,
	}
	return layout


func _is_layout_cache_valid(file_name: String, entry: Dictionary) -> bool:
	if entry.get("modified_time", -1) != FileAccess.get_modified_time(file_name):
		return false

	return entry.get("file_size", -1) == _file_size(file_name)


func _file_size(file_name: String) -> int:
	var file := FileAccess.open(file_name, FileAccess.READ)
	if file == null:
		return -1

	return file.get_length()


# Reads the frame count and frame size from a metadata-only export, so the sheet
# can be laid out as a grid. Returns {} when the layout can't be determined.
func _probe_sheet_layout(file_name: String) -> Dictionary:
	var content := _fetch_metadata(file_name)
	var frames = content.get("frames", [])
	if not frames is Array or frames.is_empty():
		return {}

	var source_size: Dictionary = frames[0].get("sourceSize", {})
	return {
		"frame_count": frames.size(),
		"frame_width": int(source_size.get("w", 0)),
		"frame_height": int(source_size.get("h", 0)),
	}


# Runs a metadata-only export (no sheet, so it is fast) and returns the parsed
# JSON as a Dictionary, or {} on any failure. The export is written to the project
# folder using relative paths (the same style as the working import exports),
# because some sandboxed Aseprite installs cannot write to the OS temp directory.
func _fetch_metadata(file_name: String) -> Dictionary:
	var relative_data_file := "./popochiu_meta_%d_%d.json" % [Time.get_ticks_msec(), randi()]
	var data_file := relative_data_file.replace("./", "res://")
	var output := []
	var arguments := [
		"-b",
		"--list-tags",
		"--data",
		relative_data_file,
		"--format",
		"json-array",
		file_name,
	]

	var content := {}
	var exit_code := _execute(arguments, output)
	if exit_code != 0:
		PopochiuUtils.print_error('Aseprite: failed to export metadata (exit code %d)' % exit_code)
		printerr(output)
	elif not FileAccess.file_exists(data_file):
		printerr(
			'[Popochiu] Aseprite: export succeeded but no JSON data file was produced at %s'
			% data_file
		)
	else:
		var file := FileAccess.open(data_file, FileAccess.READ)
		if file != null:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				content = json.data
			else:
				PopochiuUtils.print_error('Aseprite: could not parse the exported JSON metadata')
			file.close()

	# Always clean up the throwaway file
	if FileAccess.file_exists(data_file):
		DirAccess.remove_absolute(data_file)
	return content

