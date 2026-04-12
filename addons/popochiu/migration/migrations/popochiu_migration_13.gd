@tool
class_name PopochiuMigration13
extends PopochiuMigration

const VERSION = 13
const DESCRIPTION = "Update inventory item method signatures for quantity support (refs #349)"
const STEPS = [
	"Update add() calls: move animate to second argument position",
	"Update remove() calls: move animate to second argument position",
	"Update add_as_active() calls: move animate to second argument position",
	"Update queue_add() calls: move animate to second argument position",
	"Update queue_remove() calls: move animate to second argument position",
	"Update queue_add_as_active() calls: move animate to second argument position",
	"Replace deprecated in_inventory = true/false assignments with method calls",
]


#region Virtual ####################################################################################
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_update_add_calls,
			_update_remove_calls,
			_update_add_as_active_calls,
			_update_queue_add_calls,
			_update_queue_remove_calls,
			_update_queue_add_as_active_calls,
			_replace_in_inventory_assignments,
		]
	)


#endregion

#region Private ####################################################################################
## Update .add(false) and .add(true) calls: the animate argument has moved from first to second
## position since quantity is now the first parameter. Bare .add() calls need no change.
func _update_add_calls() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = ".add(false)", to = ".add(1, false)"},
		{from = ".add(true)", to = ".add(1, true)"},
	], ["autoloads"]) else Completion.IGNORED


## Update .remove(false) and .remove(true) calls: the animate argument has moved from first to
## second position since quantity is now the first parameter. Bare .remove() calls need no change.
func _update_remove_calls() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = ".remove(false)", to = ".remove(0, false)"},
		{from = ".remove(true)", to = ".remove(0, true)"},
	], ["autoloads"]) else Completion.IGNORED


## Update .add_as_active() calls: animate moves from first to second position.
func _update_add_as_active_calls() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = ".add_as_active(false)", to = ".add_as_active(1, false)"},
		{from = ".add_as_active(true)", to = ".add_as_active(1, true)"},
	], ["autoloads"]) else Completion.IGNORED


## Update .queue_add() calls: animate moves from first to second position.
func _update_queue_add_calls() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = ".queue_add(false)", to = ".queue_add(1, false)"},
		{from = ".queue_add(true)", to = ".queue_add(1, true)"},
	], ["autoloads"]) else Completion.IGNORED


## Update .queue_remove() calls: animate moves from first to second position.
func _update_queue_remove_calls() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = ".queue_remove(false)", to = ".queue_remove(0, false)"},
		{from = ".queue_remove(true)", to = ".queue_remove(0, true)"},
	], ["autoloads"]) else Completion.IGNORED


## Update .queue_add_as_active() calls: animate moves from first to second position.
func _update_queue_add_as_active_calls() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = ".queue_add_as_active(false)", to = ".queue_add_as_active(1, false)"},
		{from = ".queue_add_as_active(true)", to = ".queue_add_as_active(1, true)"},
	], ["autoloads"]) else Completion.IGNORED


## Replace the deprecated in_inventory assignments with the proper method calls.
## in_inventory = true  → await add(1, false)  (background add, matching old direct-assign behaviour)
## in_inventory = false → await remove(0, false) (background full removal, matching old behaviour)
## Note: the replacements use await because add() and remove() are coroutines. If the calling
## function is not already async, Godot will issue a warning, but the call will still work.
func _replace_in_inventory_assignments() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = "in_inventory = true", to = "await add(1, false)"},
		{from = "in_inventory = false", to = "await remove(0, false)"},
	], ["autoloads"]) else Completion.IGNORED


#endregion
