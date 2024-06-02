@tool
extends Control

const MIGRATION_SCENE = preload("res://addons/popochiu/editor/popups/migrations/migration.tscn")
const Migration = preload("res://addons/popochiu/editor/popups/migrations/migration.gd")

@onready var tab_container: TabContainer = %TabContainer


#region Public #####################################################################################
func add_migration(popochiu_migration: PopochiuMigration) -> void:
	var migration := MIGRATION_SCENE.instantiate()
	migration.name = "Migration%d" % popochiu_migration.VERSION
	migration.description.text = popochiu_migration.DESCRIPTION
	migration.set_steps(popochiu_migration.STEPS)
	
	PopochiuEditorHelper.override_font(migration.steps, "normal_font", "main")
	PopochiuEditorHelper.override_font(migration.steps, "bold_font", "bold")
	PopochiuEditorHelper.override_font(migration.steps, "mono_font", "source")
	
	tab_container.add_child(migration)


func update_steps(popochiu_migration: PopochiuMigration) -> void:
	var migration: Migration = tab_container.get_child(popochiu_migration.version - 1)
	migration.mark_steps(popochiu_migration.completed)


#endregion
