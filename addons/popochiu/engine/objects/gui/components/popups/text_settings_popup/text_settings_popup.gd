@tool
extends PopochiuPopup

@onready var text_speed: HSlider = %TextSpeed
@onready var dialog_style: OptionButton = %DialogStyle
@onready var continue_mode: CheckButton = %ContinueMode


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	if Engine.is_editor_hint(): return
	
	text_speed.value = 0.1 - PopochiuUtils.e.text_speed
	dialog_style.selected = PopochiuUtils.e.settings.dialog_style
	continue_mode.button_pressed = PopochiuUtils.e.settings.auto_continue_text
	
	# Connect to child signals
	text_speed.value_changed.connect(_on_text_speed_changed)
	dialog_style.item_selected.connect(_on_dialog_style_selected)
	continue_mode.toggled.connect(_on_continue_mode_toggled)


#endregion

#region Private ####################################################################################
func _on_text_speed_changed(value: float) -> void:
	PopochiuUtils.e.text_speed = 0.1 - value


func _on_dialog_style_selected(idx: int) -> void:
	PopochiuUtils.e.current_dialog_style = dialog_style.get_item_id(idx)


func _on_continue_mode_toggled(toggled_on: bool) -> void:
	PopochiuUtils.e.settings.auto_continue_text = toggled_on


#endregion
