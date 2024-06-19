@tool
extends PanelContainer

var _steps := []

@onready var description: Label = %Description
@onready var steps: VBoxContainer = %Steps


#region Public #####################################################################################
func set_steps(steps_texts: Array) -> void:
	for text: String in steps_texts:
		var check_box := CheckBox.new()
		steps.add_child(check_box)
		check_box.text = text.replace("[b]", "").replace("[/b]", "")
		check_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_box.modulate.a = 0.3
		check_box.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD
		PopochiuEditorHelper.override_font(check_box, "font", "source")


func start_step(idx: int) -> void:
	steps.get_child(idx).modulate.a = 0.6


func update_steps(popochiu_migration: PopochiuMigration) -> void:
	for idx: int in popochiu_migration.completed:
		var check_box: CheckBox = steps.get_child(idx)
		check_box.set_pressed_no_signal(true)
		check_box.modulate.a = 1.0
	
	for idx: int in popochiu_migration.ignored:
		var check_box: CheckBox = steps.get_child(idx)
		check_box.set_pressed_no_signal(false)
		check_box.disabled = true


#endregion
