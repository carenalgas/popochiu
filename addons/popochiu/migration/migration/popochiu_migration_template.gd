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
