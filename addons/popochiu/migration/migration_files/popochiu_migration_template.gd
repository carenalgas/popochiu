@tool
class_name PopochiuMigrationX # Change X to be the correct version number for migration
extends PopochiuMigration

# Update constant values to be correct for your migration
const VERSION = -1
const DESCRIPTION = "short description of migration goes here"


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	# Your migration code goes here.
	return false


#endregion

#region Public #####################################################################################
## Attempts to do the migration. Returns [code]true[/code] if successful.
func do_migration() -> bool:
	set_migration_version(VERSION)

	# Make sure the user migration version is less then this migration version
	if not can_do_migration():
		return false
	
	PopochiuUtils.print_normal("Performing Migration %s: %s" % [str(VERSION), DESCRIPTION])
	
	return _do_migration()


#endregion
