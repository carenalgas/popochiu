@tool
class_name PopochiuMigration
extends Node
## This provides the core features needed to do a migration.
##
## Migration files in [code]res://addons/popochiu/migration/migrations/*.gd[/code] should
## extend this class.

enum Completion {
	FAILED,
	DONE,
	IGNORED,
}

signal step_started(migration: PopochiuMigration, idx: int)
signal step_completed(migration: PopochiuMigration)

var _version := -1
var _reload_needed := false

## [Array] of completed steps
var completed := []
## [Array] of ignored steps
var ignored := []


#region Godot ######################################################################################
func _init() -> void:
	set_migration_version(get("VERSION"))


#endregion

#region Virtual ####################################################################################
func _do_migration() -> bool:
	return false


func _is_reload_required() -> bool:
	return _reload_needed


#endregion

#region Public #####################################################################################
## Sets [param version] as the migration version for the migration script.
func set_migration_version(version: int) -> void:
	_version = version


## Returns the [member _version] of this migration.
func get_version() -> int:
	return _version


func get_migration_name() -> String:
	return "Migration %d" % _version


## Returns [true] if the current Popochiu migration version is newer than the user's migration
## version, which means a migration is needed.
func is_migration_needed() -> bool:
	return _version > PopochiuMigrationHelper.get_user_migration_version()


## A helper function to display an error message in the [b]Output[/b] if there is an error doing 
## the migration, or a message if it is successful. This updates the [code]popochiu_data.cfg[/code]
## file to have a new migration version if successful. [param migration] is an instantiated
## [PopochiuMigration] from [code]res://addons/popochiu/migration/migrations/*.gd[/code].
## [param version] is an integer for the migration version being run. This is intended to be called
## [DoMigration].
static func run_migration(migration: PopochiuMigration, version: int) -> bool:
	if not await migration.do_migration():
		PopochiuUtils.print_error("Migration %d failed" % version)
		return false
	else:
		PopochiuMigrationHelper.update_user_migration_version(version)
		PopochiuUtils.print_normal("Migration %d completed" % version)
		return true


## Attempts to do the migration. Returns [code]true[/code] if successful.
func do_migration() -> bool:
	# Make sure the user migration version is less then this migration version
	if not can_do_migration():
		return false
	
	PopochiuUtils.print_normal("Performing Migration %s: %s" % [
		str(get("VERSION")), get("DESCRIPTION")
	])
	
	return await _do_migration()


## Makes sure that the user migration version is less than the current migration version and the
## [_version] variable has been set to a value. Returns [code]true[/code] if migration can be done.
func can_do_migration() -> bool:
	# If the user migration version is equal to, or higher than [_version], ignore the migration.
	# If [_version] is less than 0, then version has not been set so do not do the migration
	return PopochiuMigrationHelper.get_user_migration_version() < _version and _version >= 0


## Emits [signal step_started] sending the [param idx], which is the index of the migration step
## that just started.
func start_step(idx: int) -> void:
	step_started.emit(self, idx)


## Add the migration step ([param idx]) to its corresponding array depending on whether it was
## completed ([param type] == [constant Completion.DONE]) or ignored
## ([param type] == [constant Completion.IGNORED]). Then emits [signal step_completed] so the GUI
## provides feedback to the developer.
func step_finished(idx: int, type: Completion) -> void:
	match type:
		Completion.DONE:
			completed.append(idx)
		Completion.IGNORED:
			ignored.append(idx)
	
	step_completed.emit(self)


## Returns [code]true[/code] if this migration needs an Engine restart once applied.
func is_reload_required() -> bool:
	return _is_reload_required()


#endregion
