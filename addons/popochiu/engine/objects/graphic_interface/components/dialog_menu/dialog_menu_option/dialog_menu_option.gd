class_name PopochiuDialogMenuOption
extends PanelContainer

signal pressed(node: PopochiuDialogOption)

var option: PopochiuDialogOption : set = set_dialog_option
var text := "" : set = set_text
var used := false : set = set_used
var normal_color := Color.WHITE
var normal_used_color := normal_color
var hover_color := Color.WHITE
var hover_used_color := hover_color
var pressed_color := Color.WHITE
var pressed_used_color := pressed_color

var _state := "normal" : set = set_state

@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var handler: Button = %Handler


#region Godot ######################################################################################
func _ready() -> void:
	handler.pressed.connect(_on_pressed)
	handler.mouse_entered.connect(_on_mouse_entered)
	handler.mouse_exited.connect(_on_mouse_exited)
	handler.button_down.connect(_on_button_down)
	handler.button_up.connect(_on_button_up)
	
	_update_font_color()


#endregion

#region Virtual ####################################################################################

#endregion

#region Public #####################################################################################

#endregion

#region SetGet #####################################################################################
func set_dialog_option(value: PopochiuDialogOption) -> void:
	option = value
	if PopochiuConfig.should_dialog_options_be_gibberish():
		text = D.create_gibberish(option.text)
	else:
		text = option.text 
	
	used = option.used and not option.always_on


func set_text(value: String) -> void:
	text = value
	rich_text_label.text = value


func set_used(value: bool) -> void:
	used = value
	_update_font_color()


func set_state(value: String) -> void:
	_state = value
	_update_font_color()


#endregion

#region Private ####################################################################################
func _on_pressed() -> void:
	_state = "pressed"
	pressed.emit(option)


func _on_mouse_entered() -> void:
	_state = "hover"


func _on_mouse_exited() -> void:
	_state = "normal"


func _on_button_down() -> void:
	_state = "pressed"


func _on_button_up() -> void:
	_state = "hover" if handler.is_hovered() else "normal"


func _update_font_color() -> void:
	rich_text_label.add_theme_color_override(
		"default_color",
		get("%s_color" % (_state + ("_used" if used else "")))
	)


#endregion
