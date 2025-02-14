extends Control

@onready var input_button: LinkButton = $InputButton
@onready var manual: Label = %Manual
@onready var continue_mode: CheckButton = %ContinueMode
@onready var auto: Label = %Auto


#region Godot ######################################################################################
func _ready() -> void:
	# Set default values
	input_button.button_pressed = PopochiuUtils.e.settings.auto_continue_text
	continue_mode.button_pressed = PopochiuUtils.e.settings.auto_continue_text
	_update_labels()
	
	# Connect to children signals
	input_button.toggled.connect(_on_toggled)


#endregion

#region Private ####################################################################################
func _update_labels() -> void:
	if input_button.button_pressed:
		manual.modulate.a = PopochiuGraphicInterface.UNSELECTED_ALPHA
		auto.modulate.a = PopochiuGraphicInterface.SELECTED_ALPHA
	else:
		manual.modulate.a = PopochiuGraphicInterface.SELECTED_ALPHA
		auto.modulate.a = PopochiuGraphicInterface.UNSELECTED_ALPHA


func _on_toggled(toggled_on: bool) -> void:
	PopochiuUtils.e.settings.auto_continue_text = toggled_on
	continue_mode.button_pressed = toggled_on
	_update_labels()


#endregion
