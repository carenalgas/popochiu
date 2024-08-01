@tool
extends PanelContainer

const MIGRATION_STEP_SCENE = preload(
	"res://addons/popochiu/editor/popups/migrations_panel/migration_step.tscn"
)
const MigrationStep = preload(
	"res://addons/popochiu/editor/popups/migrations_panel/migration_step.gd"
)

@onready var description: Label = %Description
@onready var steps: VBoxContainer = %Steps


#region Public #####################################################################################
func set_steps(steps_texts: Array) -> void:
	for text: String in steps_texts:
		var step: MigrationStep = MIGRATION_STEP_SCENE.instantiate()
		steps.add_child(step)
		step.description.text = text


func start_step(idx: int) -> void:
	(steps.get_child(idx) as MigrationStep).start()


func update_steps(popochiu_migration: PopochiuMigration) -> void:
	for idx: int in popochiu_migration.completed:
		var step: MigrationStep = steps.get_child(idx)
		step.check_box.set_pressed_no_signal(true)
		step.stop()
	
	for idx: int in popochiu_migration.ignored:
		var step: MigrationStep = steps.get_child(idx)
		step.check_box.set_pressed_no_signal(false)
		step.modulate.a = 0.5
		step.stop()


func get_total_height() -> float:
	return description.size.y + steps.size.y


#endregion
