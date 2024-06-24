@tool
extends Control

const MIGRATION_TAB_SCENE = preload(
	"res://addons/popochiu/editor/popups/migrations_panel/migration_tab.tscn"
)
const MigrationTab = preload(
	"res://addons/popochiu/editor/popups/migrations_panel/migration_tab.gd"
)

@onready var tab_container: TabContainer = %TabContainer
@onready var reload_label: Label = %ReloadLabel


#region Godot ######################################################################################
func _ready() -> void:
	reload_label.hide()


#endregion

#region Public #####################################################################################
func add_migration(popochiu_migration: PopochiuMigration) -> void:
	var migration := MIGRATION_TAB_SCENE.instantiate()
	tab_container.add_child.call_deferred(migration)
	await migration.ready
	
	migration.name = popochiu_migration.get_migration_name()
	migration.anchors_preset = Control.PRESET_FULL_RECT
	migration.description.text = popochiu_migration.DESCRIPTION
	migration.set_steps(popochiu_migration.STEPS)


func start_step(popochiu_migration: PopochiuMigration, idx: int) -> void:
	var migration_tab: MigrationTab = tab_container.get_node(
		popochiu_migration.get_migration_name()
	)
	tab_container.current_tab = migration_tab.get_index()
	migration_tab.start_step(idx)


func update_steps(popochiu_migration: PopochiuMigration) -> void:
	var migration_tab: MigrationTab = tab_container.get_node(
		popochiu_migration.get_migration_name()
	)
	tab_container.current_tab = migration_tab.get_index()
	migration_tab.update_steps(popochiu_migration)


#endregion
