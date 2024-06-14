@tool
class_name DoMigration
extends Node


#region Public #####################################################################################
## While the user migration version is less than the popochiu migration version
## do the needed migrations in order.
static func do_migrations() -> void:
	if not PopochiuMigrationHelper.is_migration_needed():
		PopochiuUtils.print_normal("No Migrations needed")
		await PopochiuEditorHelper.wait_process_frame()
		return
	
	var migrations_panel := PopochiuEditorHelper.MIGRATIONS_PANEL_SCENE.instantiate()
	var migrations_popup := await PopochiuEditorHelper.show_migrations(migrations_panel)
	migrations_popup.get_ok_button().disabled = true
	
	prints(">>>>>>>>>>> migrations_panel", migrations_panel)
	PopochiuUtils.print_normal("Processing Popochiu Migrations")
	while PopochiuMigrationHelper.is_migration_needed():
		var user_migration_version := PopochiuMigrationHelper.get_user_migration_version()
		
		# if this is < 0 then an error has occured so break out of the loop
		# if the user version is equal or higher then current version then an error has occured
		if (
			user_migration_version < 0
			or user_migration_version >= PopochiuMigrationHelper.get_migrations_count()
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
		
		prints("::::::: migration", migration)
		await migrations_panel.add_migration(migration)
		
		migration.step_started.connect(migrations_panel.start_step)
		migration.step_completed.connect(migrations_panel.update_steps)
		if not await PopochiuMigration.run_migration(migration, migration_version):
			PopochiuUtils.print_error(
				"Something went wrong while executing Migration %d" % migration_version
			)
			break
	
	migrations_popup.get_ok_button().disabled = false
	migrations_popup.confirmed.connect(EditorInterface.restart_editor.bind(false))


#endregion
