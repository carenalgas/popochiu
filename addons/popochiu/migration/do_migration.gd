@tool
class_name DoMigration
extends Node

## While the user migration version is less than the popochiu migration version
## do the needed migrations in order.
static func do_migrations() -> void:
    if PopochiuMigration.check_for_updates():
        PopochiuUtils.print_normal('Processing Popochiu Migrations')
    else:
        return
    
    while PopochiuMigration.check_for_updates():
        # if this is < 0 then an error has occured so break out of the loop
        # if the user version is equal or higher then current version then an error has occured
        if PopochiuMigration.get_user_version() < 0 or \
            PopochiuMigration.get_user_version() >= PopochiuMigration.get_current_version():
                break

        # adding 1 to user migration version to match with the migration that needs to be done
        var migration_version := PopochiuMigration.get_user_version() + 1

        # This will match the versions that need a migration
        # The migration classes are located at 'res://addons/popochiu/migration/migration_files/*.gd'
        match migration_version:
            1: # Migrate the project to the popochiu 2.0 project structure
                if not PopochiuMigration.run_migration(PopochiuMigration1.new(), migration_version):
                    break
            # Add new migrations here


