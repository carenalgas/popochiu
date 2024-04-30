@tool
class_name PopochiuMigrationX # Change X to be the correct version number for migration
extends PopochiuMigration

# Update constant values to be correct for your migration
const _VERSION := -1
const _DESCRIPTION := 'short description of migration goes here'


## This is code specific for this migration.
## This should return true if the migration is successful.
## This is called from do_migration() which checks to make sure the migration should be done 
## before calling this.
func _do_migration() -> bool:
    # Your migration code goes here.
    return false


# Code below this point should not need to be changed and is templated to be consistent
# between migrations.

## Attempts to do the migration
## Returns true if successful.
func do_migration() -> bool:
    set_migration_version(_VERSION)

    # Make sure the user migration version is less then this migration version
    if not can_do_migration():
        return false
    
    PopochiuUtils.print_normal('Performing Migration ' + str(_VERSION) + ': ' + _DESCRIPTION)
    
    return _do_migration()
    
