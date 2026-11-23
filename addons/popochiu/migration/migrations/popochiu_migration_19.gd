@tool
class_name PopochiuMigration19
extends PopochiuMigration

const VERSION = 19
const DESCRIPTION = (
	"Move object persistence into PopochiuGameState and remove the per-object state containers"
)
const STEPS = [
	"Report removed state containers and state resources",
	"Report removed room state initialization APIs",
]


#region Virtual ####################################################################################
func _is_migration_needed() -> bool:
	# Always run so the migration version advances even when the project has no matches.
	return true


func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_report_removed_state_containers,
			_report_removed_state_initialization,
		]
	)


#endregion

#region Private ####################################################################################
## Reports the state containers and data resource classes that are no longer part of the engine.
func _report_removed_state_containers() -> Completion:
	var patterns: Array[String] = [
		"rooms_states",
		"characters_states",
		"items_states",
		"PopochiuRoomData",
		"PopochiuCharacterData",
		"PopochiuInventoryItemData",
	]
	var matches := _get_files_with_patterns(patterns)
	if matches.is_empty():
		return Completion.IGNORED

	var files_list := _format_file_list(matches)
	PopochiuUtils.print_warning(
		"Migration %d: Found removed state containers or state resource references:%s\n"
		% [VERSION, files_list]
		+ "R.rooms_states, C.characters_states, I.items_states, PopochiuRoomData, "
		+ "PopochiuCharacterData, and PopochiuInventoryItemData were removed. "
		+ "Read custom state from the live room, character, or item instance instead. "
		+ "PopochiuGameState now owns the snapshots used across room changes and save/load."
	)
	return Completion.DONE


## Reports calls to the removed room state initialization API.
func _report_removed_state_initialization() -> Completion:
	var patterns: Array[String] = ["store_states"]
	var matches := _get_files_with_patterns(patterns)
	if matches.is_empty():
		return Completion.IGNORED

	var files_list := _format_file_list(matches)
	PopochiuUtils.print_warning(
		"Migration %d: R.store_states() was removed:%s\n" % [VERSION, files_list]
		+ "PopochiuGameState captures rooms when they are unloaded and applies their snapshots "
		+ "when they are loaded again. Remove calls to R.store_states()."
	)
	return Completion.DONE


func _get_files_with_patterns(patterns: Array[String]) -> Array[String]:
	if not DirAccess.dir_exists_absolute(PopochiuResources.GAME_PATH):
		return []

	var files := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.GAME_PATH, ["gd"], ["autoloads"]
	)
	var matching_files: Array[String] = []

	for file_path: String in files:
		var content := _read_file(file_path)
		if content.is_empty():
			continue

		for pattern: String in patterns:
			var pattern_regex := RegEx.create_from_string(r"\b%s\b" % pattern)
			if pattern_regex.search(content):
				matching_files.append(file_path)
				break

	return matching_files


func _format_file_list(files: Array[String]) -> String:
	var files_list := ""
	for file_path: String in files:
		files_list += "\n- %s" % file_path

	return files_list


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	var content := file.get_as_text()
	file.close()
	return content


#endregion
