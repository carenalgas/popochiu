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
	"Replace deprecated in_inventory = true/false assignments with method calls",
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
			_replace_in_inventory_assignments,
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


## Replace the deprecated in_inventory assignments with the proper method calls.
## in_inventory = true  → await add()  (background add, matching old direct-assign behaviour)
## in_inventory = false → await remove() (background full removal, matching old behaviour)
## Note: the replacements use await because add() and remove() are coroutines. If the calling
## function is not already async, Godot will issue a warning, but the call will still work.
func _replace_in_inventory_assignments() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = "in_inventory = true", to = "await add()"},
		{from = "in_inventory = false", to = "await remove()"},
	], ["autoloads"]) else Completion.IGNORED


#endregion
