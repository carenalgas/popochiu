@tool
class_name PopochiuMigration16
extends PopochiuMigration

const VERSION = 16
const DESCRIPTION = "Add _on_restore_from_savegame() hook to room scripts"
const STEPS = [
	"Add _on_restore_from_savegame() stub to existing room scripts",
]


#region Virtual ####################################################################################
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_add_restore_hooks_to_rooms,
		]
	)


#endregion

#region Private ####################################################################################
func _add_restore_hooks_to_rooms() -> Completion:
	PopochiuUtils.print_normal("Migration %d: Adding restore hook to room scripts" % VERSION)
	var any_script_updated := false
	var room_tres_paths := PopochiuResources.get_section("rooms")

	for tres_path in room_tres_paths:
		var gd_path: String= tres_path.replace(".tres", ".gd")
		if _add_hook_to_file(gd_path):
			any_script_updated = true

	if any_script_updated:
		PopochiuUtils.print_normal(
			"Migration %d: _on_restore_from_savegame() added to room scripts." % VERSION
		)
	else:
		PopochiuUtils.print_normal(
			"Migration %d: No room scripts needed updating." % VERSION
		)

	PopochiuUtils.print_warning(
		(
			"Migration %d: WARNING — Room variables 'state.visited' and 'state.visited_first_time' " +
			"are now read-only getters. Search your project for 'state.visited\\s*=' and " +
			"'state.visited_first_time\\s*=' and remove any assignments."
		) % VERSION
	)

	return Completion.DONE if any_script_updated else Completion.IGNORED


## Add _on_restore_from_savegame() stub to a single room script if missing.
func _add_hook_to_file(script_path: String) -> bool:
	var file := FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		PopochiuUtils.print_warning(
			"Migration %d: Could not read room script '%s'" % [VERSION, script_path]
		)
		return false

	var content := file.get_as_text()
	file.close()

	if "_on_restore_from_savegame" in content:
		return false

	var exited_pos := content.find("func _on_room_exited")
	if exited_pos == -1:
		PopochiuUtils.print_warning(
			"Migration %d: Skipping '%s' — _on_room_exited not found" % [VERSION, script_path]
		)
		return false

	var endregion_pos := content.find("#endregion", exited_pos)
	if endregion_pos == -1:
		PopochiuUtils.print_warning(
			"Migration %d: Skipping '%s' — no #endregion found after _on_room_exited" % [
				VERSION, script_path
			]
		)
		return false

	var stub := (
		"\n\n# Called after loading a saved game. The state of the room and all its objects is\n"
		+ "# completely restored at this point. Use this to resume ongoing events,\n"
		+ "# re-establish connections, or restart ambient audio.\n"
		+ "# NOTE: `_on_room_transition_finished()` is NOT called when loading a savegame.\n"
		+ "func _on_restore_from_savegame() -> void:\n"
		+ "\tpass"
	)

	content = content.substr(0, endregion_pos) + stub + "\n" + content.substr(endregion_pos)

	file = FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		PopochiuUtils.print_error(
			"Migration %d: Could not write to room script '%s'" % [VERSION, script_path]
		)
		return false

	file.store_string(content)
	file.close()

	return true


#endregion
