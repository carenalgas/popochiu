@tool
extends PopochiuPopup

## The base speed at which the text is rendered.
const BASE_SPEED = 0.1
## The format to use when displaying the text speed.
const TWO_DECIMAL_SPEED_FORMAT = "%.2fx"

@onready var save: Button = %Save
@onready var load: Button = %Load
@onready var history: Button = %History
@onready var quit: Button = %Quit
@onready var text_speed: HSlider = %TextSpeed
@onready var text_speed_label: Label = %TextSpeedLabel


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	if Engine.is_editor_hint(): return
	
	# Set default values
	text_speed.value = BASE_SPEED - PopochiuUtils.e.text_speed
	text_speed_label.text = TWO_DECIMAL_SPEED_FORMAT % PopochiuUtils.e.text_speed
	
	# Connect to children signals
	save.pressed.connect(_on_save_pressed)
	load.pressed.connect(_on_load_pressed)
	history.pressed.connect(_on_history_pressed)
	quit.pressed.connect(_on_quit_pressed)
	text_speed.value_changed.connect(_on_text_speed_changed)


#endregion

#region Private ####################################################################################
func _on_save_pressed() -> void:
	PopochiuUtils.g.popup_requested.emit("SavePopup")


func _on_load_pressed() -> void:
	PopochiuUtils.g.popup_requested.emit("LoadPopup")


func _on_history_pressed() -> void:
	PopochiuUtils.g.popup_requested.emit("HistoryPopup")


func _on_quit_pressed() -> void:
	PopochiuUtils.g.popup_requested.emit("QuitPopup")


func _on_text_speed_changed(value: float) -> void:
	PopochiuUtils.e.text_speed = BASE_SPEED - value
	text_speed_label.text = TWO_DECIMAL_SPEED_FORMAT % PopochiuUtils.e.text_speed


#endregion
