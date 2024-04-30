@tool
class_name PopochiuMigration
extends Node
## This provides the core features needed to do a migration.
## 'res://addons/popochiu/migration/migration_files/*.gd' Migration files should extend this class.

var _version := -1

## Returns the current popochiu migration version.
## If the current popochiu version is greater than the user version then
## a migration needs to be done.
static func get_current_version() -> int:
    return PopochiuMigrationConfig.get_version()


## Returns the user project migration version.
## If the current popochiu version is greater than the user version then
## a migration needs to be done.
## If -1 gets returned then an error has occured.
static func get_user_version() -> int:
    return PopochiuMigrationHelper.get_user_migration_version()


## Returns true if the current popochiu migration version is newer
## than the user's project migration version.
## If this returns true then a migration is needed.
static func check_for_updates() -> bool:
    return get_current_version() > get_user_version()


## A helper function to display an error message in the output if there is an error doing the migration
## or a completed message if it is successful.
## Updates the popochiu_data.cfg file to have a new migration version if successful.
## [param migration] is an instansiated PopochiuMigration object 
## from 'res://addons/popochiu/migration/migration_files/*.gd'.
## [param version] is an integer for the migration version being run.
## This is intended to be called from 'res://addons/popochiu/migration/do_migration.gd'.
static func run_migration(migration: PopochiuMigration, version: int) -> bool:
    # the do_migration() method comes from the 'res://addons/popochiu/migration/migration_files/*.gd' files
    # that extends PopochiuMigration
    if not migration.do_migration():
        PopochiuUtils.print_error('An error has occured while doing migration ' + str(version))
        return false
    else:
        PopochiuMigrationHelper.update_user_migration_version(version)
        PopochiuUtils.print_normal('Migration ' + str(version) + ' completed')
        return true


## Sets the migration version for the migration script.
## [param version] is an integer value to set for the _version migration variable.
func set_migration_version(version: int) -> void:
    _version = version


## Makes sure that the user migration version is less than this migration version and the _version
## variable has been set to a value.
## Returns true if migration can be done.
func can_do_migration() -> bool:
    # if the user migration value is equal to or higher then _version then don't do the migration
    # if _version is less than 0 then version has not been set so do not do the migration
    if PopochiuMigrationHelper.get_user_migration_version() >= _version or _version < 0:
        return false
    else:
        return true