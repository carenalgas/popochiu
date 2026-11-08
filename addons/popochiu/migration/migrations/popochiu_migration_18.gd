@tool
class_name PopochiuMigration18
extends PopochiuMigration

const VERSION = 18
const DESCRIPTION = (
	"Remove object descriptors and state scripts; use .tscn paths and object-owned state"
)
const STEPS = [
	"Point rooms, characters, and inventory items to their .tscn files",
	"Move custom state from *_state.gd scripts to the object scripts",
	"Rewrite <.state.> references to direct object properties",
	"Delete obsolete descriptor and state files",
	"Report state code that needs manual migration",
]
const OBJECT_SECTIONS := ["rooms", "characters", "inventory_items"]
const STATE_REFERENCE_PATTERNS := [
	r"\b(R|C|I)\.([A-Za-z_]\w*)\.state\.",
	r"\b(R|C|I)\.(player|current)\.state\.",
	r"\b(PopochiuUtils\.(?:r|c|i))\.([A-Za-z_]\w*)\.state\.",
	r"\b(PopochiuUtils\.(?:r|c|i))\.(player|current)\.state\.",
]

var _objects: Array[Dictionary] = []
var _unmerged_state_scripts: Array[String] = []
var _collision_in_current_state := false


#region Virtual ####################################################################################
func _is_migration_needed() -> bool:
	return not _find_legacy_objects().is_empty()


func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_rewrite_config_entries,
			_migrate_state_script_content,
			_rewrite_state_references,
			_delete_obsolete_files,
			_report_manual_steps,
		]
	)


#endregion

#region Private ####################################################################################
## Returns the configured objects that still use a descriptor or a state script.
func _find_legacy_objects() -> Array[Dictionary]:
	var objects: Array[Dictionary] = []

	for section: String in OBJECT_SECTIONS:
		for key: String in PopochiuResources.get_section_keys(section):
			var configured_path: String = PopochiuResources.get_data_value(section, key, "")
			var object := _describe_object(section, key, configured_path)
			if object.descriptor_path.is_empty() and object.state_script_path.is_empty():
				continue
			objects.append(object)

	return objects


func _describe_object(section: String, key: String, configured_path: String) -> Dictionary:
	var descriptor_path := ""
	var scene_path := configured_path
	var state_script_path := ""

	if configured_path.get_extension() == "tres":
		descriptor_path = configured_path
		var descriptor = load(configured_path)
		var descriptor_scene = descriptor.get("scene") if is_instance_valid(descriptor) else null
		scene_path = descriptor_scene if descriptor_scene is String and (
			not descriptor_scene.is_empty()
		) else configured_path.get_basename() + ".tscn"
		if is_instance_valid(descriptor) and descriptor.get_script():
			state_script_path = descriptor.get_script().resource_path

	# A partially migrated project may already point to the scene while keeping
	# the descriptor.
	if descriptor_path.is_empty():
		var sibling_descriptor := scene_path.get_basename() + ".tres"
		if FileAccess.file_exists(sibling_descriptor):
			descriptor_path = sibling_descriptor

	if not descriptor_path.is_empty() and state_script_path.is_empty():
		var descriptor = load(descriptor_path)
		if is_instance_valid(descriptor) and descriptor.get_script():
			state_script_path = descriptor.get_script().resource_path

	if state_script_path.is_empty():
		var sibling_state := scene_path.get_basename() + "_state.gd"
		if FileAccess.file_exists(sibling_state):
			state_script_path = sibling_state

	return {
		section = section,
		key = key,
		scene_path = scene_path,
		object_script_path = scene_path.get_basename() + ".gd",
		descriptor_path = descriptor_path,
		state_script_path = state_script_path,
		merged = false,
	}


## Rewrites popochiu_data.cfg entries so rooms, characters, and inventory items point to scenes.
func _rewrite_config_entries() -> Completion:
	_objects = _find_legacy_objects()
	if _objects.is_empty():
		return Completion.IGNORED

	var changed := false
	for object: Dictionary in _objects:
		var current_path: String = PopochiuResources.get_data_value(
			object.section, object.key, ""
		)
		if current_path == object.scene_path:
			continue

		if PopochiuResources.set_data_value(
			object.section, object.key, object.scene_path
		) == OK:
			changed = true
		else:
			PopochiuUtils.print_error(
				"Migration %d: Couldn't point %s to %s"
				% [VERSION, object.key, object.scene_path]
			)

	return Completion.DONE if changed else Completion.IGNORED


## Moves custom variables and methods from each state script into its object script.
func _migrate_state_script_content() -> Completion:
	var changed := false

	for object: Dictionary in _objects:
		var state_script_path: String = object.state_script_path
		if state_script_path.is_empty() or not FileAccess.file_exists(state_script_path):
			object.merged = true
			continue

		if not FileAccess.file_exists(object.object_script_path):
			_unmerged_state_scripts.append(state_script_path)
			PopochiuUtils.print_warning(
				"Migration %d: Couldn't find %s to receive the state from %s"
				% [VERSION, object.object_script_path, state_script_path]
			)
			continue

		var state_text := _read_file(state_script_path)
		var object_text := _read_file(object.object_script_path)
		object_text = _remove_state_declarations(object_text)

		_collision_in_current_state = false
		var migrated_body := _extract_state_body(state_text, object_text)
		var updated_text := object_text
		if not _collision_in_current_state and not migrated_body.is_empty():
			var note := "# Custom state migrated from %s.\n" % state_script_path.get_file()
			updated_text = object_text.rstrip("\n") + "\n\n\n" + note + migrated_body + "\n"

		if not _write_file(object.object_script_path, updated_text):
			object.merged = false
			_unmerged_state_scripts.append(state_script_path)
			continue

		if _collision_in_current_state:
			object.merged = false
			_unmerged_state_scripts.append(state_script_path)
			continue

		object.merged = true
		changed = true
		_reload_needed = true

	return Completion.DONE if changed else Completion.IGNORED


## Rewrites R.X.state.foo, C.X.state.foo, and I.X.state.foo to direct property access.
func _rewrite_state_references() -> Completion:
	var replacements: Array[Dictionary] = []
	for pattern: String in STATE_REFERENCE_PATTERNS:
		replacements.append({ pattern = pattern, to = "$1.$2." })

	var replaced := PopochiuMigrationHelper.replace_regex_in_scripts(
		replacements, ["autoloads"]
	)

	if replaced:
		_reload_needed = true

	return Completion.DONE if replaced else Completion.IGNORED


## Deletes the obsolete descriptor and state files after a successful merge.
func _delete_obsolete_files() -> Completion:
	var deleted := false

	for object: Dictionary in _objects:
		if not object.descriptor_path.is_empty() and FileAccess.file_exists(
			object.descriptor_path
		):
			DirAccess.remove_absolute(object.descriptor_path)
			deleted = true

		if not object.merged:
			continue

		var state_script_path: String = object.state_script_path
		if state_script_path.is_empty() or not FileAccess.file_exists(state_script_path):
			continue

		DirAccess.remove_absolute(state_script_path)
		var uid_path := state_script_path + ".uid"
		if FileAccess.file_exists(uid_path):
			DirAccess.remove_absolute(uid_path)
		deleted = true

	_reload_needed = deleted
	return Completion.DONE if deleted else Completion.IGNORED


## Reports leftover state references and state scripts that could not be migrated automatically.
func _report_manual_steps() -> Completion:
	var files_with_state_references := _get_files_with_state_references()

	if not files_with_state_references.is_empty():
		var files_list := ""
		for file_path: String in files_with_state_references:
			files_list += "\n- %s" % file_path

		PopochiuUtils.print_warning(
			"Migration %d: Found state references that need manual review:%s\n"
			% [VERSION, files_list]
			+ "Custom state now lives on the object script. Replace <object>.state.<property> "
			+ "with <object>.<property>."
		)

	if not _unmerged_state_scripts.is_empty():
		var scripts_list := ""
		for file_path: String in _unmerged_state_scripts:
			scripts_list += "\n- %s" % file_path

		PopochiuUtils.print_warning(
			"Migration %d: These state scripts couldn't be migrated automatically:%s\n"
			% [VERSION, scripts_list]
			+ "Move their custom variables and methods to the matching object script, then "
			+ "delete the state file. Descriptor .tres files were already removed."
		)

	if files_with_state_references.is_empty() and _unmerged_state_scripts.is_empty():
		return Completion.IGNORED

	return Completion.DONE


# Removes the legacy state declaration from the object script.
func _remove_state_declarations(object_text: String) -> String:
	var data_const := RegEx.new()
	data_const.compile("(?m)^const Data := preload\\(['\"][^'\"]*_state\\.gd['\"]\\)\\n?")
	object_text = data_const.sub(object_text, "", true)

	var state_var := RegEx.new()
	state_var.compile("(?m)^var state: Data\\s*=.*\\n?")
	object_text = state_var.sub(object_text, "", true)

	return object_text.rstrip("\n") + "\n"


# Extracts the reusable part of a state script, dropping its header and default save/load stubs.
func _extract_state_body(state_text: String, object_text: String) -> String:
	var lines := state_text.split("\n")
	var body_lines: Array[String] = []
	var idx := 0

	while idx < lines.size():
		var line: String = lines[idx]

		if line.begins_with("func "):
			var block_end := _find_block_end(lines, idx)
			var block := lines.slice(idx, block_end)
			var migrated_block := _migrate_function_block(block, object_text)
			if not migrated_block.is_empty():
				body_lines.append_array(migrated_block)
			idx = block_end
			continue

		if line.begins_with("@") and not line.begins_with("@tool"):
			var declaration_idx := idx + 1
			while (
				declaration_idx < lines.size()
				and _is_state_header_line(lines[declaration_idx])
			):
				declaration_idx += 1

			if (
				declaration_idx < lines.size()
				and (
					lines[declaration_idx].begins_with("var ")
					or lines[declaration_idx].begins_with("const ")
				)
			):
				var block_end := _find_block_end(lines, declaration_idx)
				var block := lines.slice(idx, block_end)
				if not _member_exists_in_object(lines[declaration_idx], object_text):
					body_lines.append_array(block)
				else:
					_report_member_collision(lines[declaration_idx])
				idx = block_end
				continue

		if _is_state_header_line(line):
			idx += 1
			continue

		if line.begins_with("var ") or line.begins_with("const ") or line.begins_with("enum "):
			var block_end := _find_block_end(lines, idx)
			var block := lines.slice(idx, block_end)
			if not _member_exists_in_object(block[0], object_text):
				body_lines.append_array(block)
			else:
				_report_member_collision(block[0])
			idx = block_end
			continue

		body_lines.append(line)
		idx += 1

	return "\n".join(body_lines).strip_edges()


func _is_state_header_line(line: String) -> bool:
	var stripped := line.strip_edges()
	return (
		stripped.is_empty()
		or stripped.begins_with("#")
		or stripped.begins_with("@tool")
		or stripped.begins_with("extends ")
	)


# Returns the index of the first line after the block that starts at [param start].
func _find_block_end(lines: PackedStringArray, start: int) -> int:
	for idx: int in range(start + 1, lines.size()):
		var line: String = lines[idx]
		if line.is_empty():
			continue
		if line[0] != "\t" and line[0] != " ":
			return idx

	return lines.size()


func _migrate_function_block(block: Array, object_text: String) -> Array[String]:
	var first_line: String = block[0]
	var function_name := _get_member_name(first_line)
	if function_name.is_empty():
		return []

	var is_save_hook := function_name in ["_on_save", "_on_load", "on_save", "on_load"]
	if is_save_hook and _is_default_state_hook(block):
		return []

	var migrated_first_line := first_line
	if is_save_hook:
		migrated_first_line = first_line.replace(function_name, function_name.trim_prefix("_"))

	if _member_exists_in_object(migrated_first_line, object_text):
		_report_member_collision(migrated_first_line)
		return []

	var result: Array[String] = []
	result.assign(block)
	result[0] = migrated_first_line

	return result


func _is_default_state_hook(block: Array) -> bool:
	var body_lines: Array[String] = []

	for idx: int in range(1, block.size()):
		var line: String = block[idx].strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		body_lines.append(line)

	if body_lines == ["return {}"] or body_lines == ["pass"]:
		return true

	if body_lines.size() == 1 and body_lines[0].begins_with("prints(data)"):
		return true

	return false


func _get_member_name(line: String) -> String:
	var match := RegEx.create_from_string(r"^(?:static\s+)?(?:var|const|func)\s+([A-Za-z_]\w*)")
	var result := match.search(line)
	return result.get_string(1) if result else ""


func _member_exists_in_object(line: String, object_text: String) -> bool:
	var member_name := _get_member_name(line)
	if member_name.is_empty():
		return false

	var member := RegEx.create_from_string(
		r"(?m)^[ \t]*(?:static\s+)?(?:var|const|func)\s+%s\b" % member_name
	)
	return member.search(object_text) != null


func _report_member_collision(line: String) -> void:
	var member_name := _get_member_name(line)
	if member_name.is_empty():
		return

	_collision_in_current_state = true
	PopochiuUtils.print_warning(
		(
			"Migration %d: Skipped '%s' from a state script because the object script already "
			+ "declares it."
		) % [VERSION, member_name]
	)


func _get_files_with_state_references() -> Array[String]:
	var files := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.GAME_PATH, ["gd"], ["autoloads"]
	)
	var matching_files: Array[String] = []
	var state_reference := RegEx.create_from_string(r"\.state\b")

	for file_path: String in files:
		var content := _read_file(file_path)
		if state_reference.search(content):
			matching_files.append(file_path)

	return matching_files


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	var content := file.get_as_text()
	file.close()
	return content


func _write_file(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		PopochiuUtils.print_error("Migration %d: Couldn't write %s" % [VERSION, path])
		return false

	file.store_string(content)
	file.close()
	return true


#endregion
