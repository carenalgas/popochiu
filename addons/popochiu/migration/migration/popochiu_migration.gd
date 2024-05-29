@tool
class_name PopochiuMigration
extends Node
## This provides the core features needed to do a migration.
##
## Migration files in [code]res://addons/popochiu/migration/migration_files/*.gd[/code] should
## extend this class.

var _version := -1


#region Virtual ####################################################################################
func _do_migration() -> bool:
	return false


#endregion

#region Public #####################################################################################
## Returns the current migration version. If the current Popochiu version is greater than the user's
## version, then a migration needs to be done.
static func get_current_version() -> int:
	return PopochiuMigrationHelper.version


## Returns the user migration version. If the current Popochiu version is greater than the user's
## version, then a migration needs to be done. If [code]-1[/code] is returned, then an error has
## occurred.
static func get_user_version() -> int:
	return PopochiuMigrationHelper.get_user_migration_version()


## Returns [true] if the current Popochiu migration version is newer than the user's migration
## version, which means a migration is needed.
static func is_migration_needed() -> bool:
	return get_current_version() > get_user_version()


## A helper function to display an error message in the [b]Output[/b] if there is an error doing 
## the migration, or a message if it is successful. This updates the [code]popochiu_data.cfg[/code]
## file to have a new migration version if successful. [param migration] is an instansiated
## [PopochiuMigration] from [code]res://addons/popochiu/migration/migration_files/*.gd[/code].
## [param version] is an integer for the migration version being run. This is intended to be called
## [DoMigration].
static func run_migration(migration: PopochiuMigration, version: int) -> bool:
	if not migration.do_migration():
		PopochiuUtils.print_error("An error has occured while doing migration " + str(version))
		return false
	else:
		PopochiuMigrationHelper.update_user_migration_version(version)
		PopochiuUtils.print_normal("Migration " + str(version) + " completed")
		return true


## Sets [param version] as the migration version for the migration script.
func set_migration_version(version: int) -> void:
	_version = version


## Makes sure that the user migration version is less than the current migration version and the
## [_version] variable has been set to a value. Returns [code]true[/code] if migration can be done.
func can_do_migration() -> bool:
	# If the user migration version is equal to, or higher than [_version], ignore the migration.
	# If [_version] is less than 0, then version has not been set so do not do the migration
	if PopochiuMigrationHelper.get_user_migration_version() >= _version or _version < 0:
		return false
	else:
		return true


## Attempts to do the migration. Returns [code]true[/code] if successful.
func do_migration() -> bool:
	set_migration_version(get("VERSION"))

	# Make sure the user migration version is less then this migration version
	if not can_do_migration():
		return false
	
	PopochiuUtils.print_normal("Performing Migration %s: %s" % [
		str(get("VERSION")), get("DESCRIPTION")
	])
	
	return _do_migration()


#endregion
