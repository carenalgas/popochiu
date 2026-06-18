@tool
class_name PopochiuMigration13
extends PopochiuMigration

const VERSION = 13
const DESCRIPTION = "Update inventory item method signatures for quantity support (refs #349)"
const STEPS = [
	"Strip animate param from add()/add_as_active() calls",
	"Strip animate param from remove() calls",
	"Strip animate param from queue_add()/queue_add_as_active() calls",
	"Strip animate param from queue_remove() calls",
	"Strip animate param from discard()/queue_discard() calls",
	"Warn about deprecated in_inventory = true/false assignments that need manual migration",
]


#region Virtual ####################################################################################
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_strip_animate_from_add_calls,
			_strip_animate_from_remove_calls,
			_strip_animate_from_queue_add_calls,
			_strip_animate_from_queue_remove_calls,
			_strip_animate_from_discard_calls,
			_warn_about_in_inventory_assignments,
		]
	)


#endregion

#region Private ####################################################################################
## Strip the boolean animate param from .add() and .add_as_active() calls. The animate param has
## been removed: GUI components now check PopochiuIInventory.is_restoring instead.
func _strip_animate_from_add_calls() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = ".add(false)", to = ".add()"},
		{from = ".add(true)", to = ".add()"},
		{from = ".add_as_active(false)", to = ".add_as_active()"},
		{from = ".add_as_active(true)", to = ".add_as_active()"},
	], ["autoloads"]) else Completion.IGNORED


## Strip the boolean animate param from .remove() calls.
func _strip_animate_from_remove_calls() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = ".remove(false)", to = ".remove()"},
		{from = ".remove(true)", to = ".remove()"},
	], ["autoloads"]) else Completion.IGNORED


## Strip the boolean animate param from .queue_add() and .queue_add_as_active() calls.
func _strip_animate_from_queue_add_calls() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = ".queue_add(false)", to = ".queue_add()"},
		{from = ".queue_add(true)", to = ".queue_add()"},
		{from = ".queue_add_as_active(false)", to = ".queue_add_as_active()"},
		{from = ".queue_add_as_active(true)", to = ".queue_add_as_active()"},
	], ["autoloads"]) else Completion.IGNORED


## Strip the boolean animate param from .queue_remove() calls.
func _strip_animate_from_queue_remove_calls() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = ".queue_remove(false)", to = ".queue_remove()"},
		{from = ".queue_remove(true)", to = ".queue_remove()"},
	], ["autoloads"]) else Completion.IGNORED


## Strip the boolean animate param from .discard() and .queue_discard() calls.
func _strip_animate_from_discard_calls() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = ".discard(false)", to = ".discard()"},
		{from = ".discard(true)", to = ".discard()"},
		{from = ".queue_discard(false)", to = ".queue_discard()"},
		{from = ".queue_discard(true)", to = ".queue_discard()"},
	], ["autoloads"]) else Completion.IGNORED


## Warn about deprecated direct in_inventory assignments.
## Direct assignment now emits a runtime deprecation warning but still performs a silent state
## change. Rewriting it automatically to add()/remove() would change GUI timing and side effects,
## so this migration only reports the files that need manual review.
func _warn_about_in_inventory_assignments() -> Completion:
	var script_paths: Array = PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.GAME_PATH,
		["gd"],
		["autoloads"]
	)
	var matching_files: Array[String] = []

	for file_path: String in script_paths:
		if (
			PopochiuMigrationHelper.is_text_in_file("in_inventory = true", file_path)
			or PopochiuMigrationHelper.is_text_in_file("in_inventory = false", file_path)
		):
			matching_files.append(file_path)

	if matching_files.is_empty():
		return Completion.IGNORED

	var files_list := ""
	for file_path: String in matching_files:
		files_list += "\n- %s" % file_path

	PopochiuUtils.print_warning(
		"Migration %d: Found deprecated in_inventory assignments that require manual review.%s\n"
		+ "Direct assignment still works as a silent state change, while add()/remove() now run "
		+ "the full inventory GUI lifecycle. Replace each usage intentionally based on the "
		+ "desired behaviour."
		% [VERSION, files_list]
	)

	return Completion.DONE


#endregion
