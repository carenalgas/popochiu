@tool
extends PopochiuPopup

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
	text_speed.value = 0.1 - PopochiuUtils.e.text_speed
	text_speed_label.text = "%.2fx" % PopochiuUtils.e.text_speed
	
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
	PopochiuUtils.e.text_speed = 0.1 - value
	text_speed_label.text = "%.2fx" % PopochiuUtils.e.text_speed


#endregion
