@tool
class_name MigrationsManager
extends Node

static var migrations_to_execute := []
static var migrations_panel: PopochiuEditorHelper.MigrationsPanel
static var migrations_popup: AcceptDialog


#region Public #####################################################################################
## If there are migrations available with a higher number then the last one
## applied to the project, apply them all in order.
static func do_migrations() -> void:
	if PopochiuMigrationHelper.is_empty_project():
		PopochiuMigrationHelper.update_user_migration_version(
			PopochiuMigrationHelper.get_migrations_count()
		)
		await PopochiuEditorHelper.frame_processed()
		return
	
	if not PopochiuMigrationHelper.is_migration_needed():
		await PopochiuEditorHelper.frame_processed()
		return
	
	migrations_panel = PopochiuEditorHelper.MIGRATIONS_PANEL_SCENE.instantiate()
	migrations_popup = await PopochiuEditorHelper.show_migrations(migrations_panel)
	migrations_popup.hide()
	
	# Get the list of migrations to apply
	for idx: int in PopochiuMigrationHelper.get_migrations_count():
		# Migration classes are located at "res://addons/popochiu/migration/migrations/*.gd"
		var migration: PopochiuMigration = load(
			PopochiuMigrationHelper.MIGRATIONS_PATH.path_join("popochiu_migration_%d.gd" % (idx + 1))
		).new()
		
		if not migration.is_migration_needed():
			continue
		
		migrations_to_execute.append(migration)
		await migrations_panel.add_migration(migration)
		
		migration.step_started.connect(migrations_panel.start_step)
		migration.step_completed.connect(migrations_panel.update_steps)
	
	if migrations_to_execute.is_empty():
		migrations_popup.free()
		return
	
	migrations_popup.get_ok_button().text = "Run migrations"
	migrations_popup.confirmed.connect(_run_migrations)
	migrations_popup.canceled.connect(
		func () -> void:
			PopochiuEditorHelper.signal_bus.migrations_done.emit()
			migrations_popup.queue_free()
	)
	migrations_popup.show()
	
	await PopochiuEditorHelper.signal_bus.migrations_done


#endregion

#region Private ####################################################################################
static func _run_migrations() -> void:
	migrations_popup.confirmed.disconnect(_run_migrations)
	migrations_popup.get_ok_button().text = "OK"
	migrations_popup.get_ok_button().disabled = true
	# Make the popup visible again so devs can see the progress on the migrations' steps
	migrations_popup.popup()
	
	PopochiuUtils.print_normal("Processing Popochiu Migrations")
	var should_reload := false
	for migration: PopochiuMigration in migrations_to_execute:
		var user_migration_version := PopochiuMigrationHelper.get_user_migration_version()
		# adding 1 to user migration version to match with the migration that needs to be done
		var migration_version := user_migration_version + 1
		if not await PopochiuMigration.run_migration(migration, migration_version):
			PopochiuUtils.print_error(
				"Something went wrong while executing Migration %d" % migration_version
			)
			break
		should_reload = should_reload or migration.is_reload_required()
		await migrations_popup.get_tree().create_timer(1.0).timeout
	
	if should_reload:
		migrations_panel.reload_label.show()
	
	migrations_popup.get_ok_button().disabled = false
	migrations_popup.confirmed.connect(
		func () -> void:
			if should_reload:
				EditorInterface.restart_editor(false)
			else:
				PopochiuEditorHelper.signal_bus.migrations_done.emit()
				migrations_popup.queue_free()
	)


#endregion
