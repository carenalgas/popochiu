@tool
class_name DoMigration
extends Node


#region Public #####################################################################################
## While the user migration version is less than the popochiu migration version
## do the needed migrations in order.
static func do_migrations() -> void:
	if not PopochiuMigrationHelper.is_migration_needed():
		await PopochiuEditorHelper.wait_process_frame()
		return
	
	PopochiuUtils.print_normal("Processing Popochiu Migrations")
	while PopochiuMigrationHelper.is_migration_needed():
		var user_migration_version := PopochiuMigrationHelper.get_user_migration_version()
		
		# if this is < 0 then an error has occured so break out of the loop
		# if the user version is equal or higher then current version then an error has occured
		if (
			user_migration_version < 0
			or user_migration_version >= PopochiuMigrationHelper.version
		):
			break
		
		# adding 1 to user migration version to match with the migration that needs to be done
		var migration_version := user_migration_version + 1
		
		# This will match the versions that need a migration
		# Migration classes are located at "res://addons/popochiu/migration/migration_files/*.gd"
		var migration: PopochiuMigration = load(
			"res://addons/popochiu/migration/migration_files/popochiu_migration_%d.gd" %
			migration_version
		).new()
		
		if not migration.is_migration_needed():
			continue
		
		if not await PopochiuMigration.run_migration(migration, migration_version):
			break


#endregion
