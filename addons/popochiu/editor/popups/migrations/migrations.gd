@tool
extends Control

const MIGRATION_SCENE = preload("res://addons/popochiu/editor/popups/migrations/migration_tab.tscn")
const MigrationTab = preload("res://addons/popochiu/editor/popups/migrations/migration_tab.gd")

@onready var tab_container: TabContainer = %TabContainer


#region Public #####################################################################################
func add_migration(popochiu_migration: PopochiuMigration) -> void:
	var migration := MIGRATION_SCENE.instantiate()
	migration.name = "Migration %d" % popochiu_migration.VERSION
	migration.anchors_preset = Control.PRESET_FULL_RECT
	tab_container.add_child.call_deferred(migration)
	await migration.ready
	
	migration.description.text = popochiu_migration.DESCRIPTION
	migration.set_steps(popochiu_migration.STEPS)
	await get_tree().process_frame
	
	custom_minimum_size = $PanelContainer.size
	(get_parent() as AcceptDialog).reset_size()
	(get_parent() as AcceptDialog).move_to_center()


func start_step(popochiu_migration: PopochiuMigration, idx: int) -> void:
	var migration_tab: MigrationTab = tab_container.get_child(popochiu_migration.VERSION - 1)
	migration_tab.start_step(idx)


func update_steps(popochiu_migration: PopochiuMigration) -> void:
	var migration_tab: MigrationTab = tab_container.get_child(popochiu_migration.VERSION - 1)
	migration_tab.update_steps(popochiu_migration)


#endregion
