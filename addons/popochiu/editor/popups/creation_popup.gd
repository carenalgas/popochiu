extends ConfirmationDialog

var _name := ''
var _main_dock: Panel : set = set_main_dock

@onready var _input: LineEdit = find_child('Input')
@onready var _error_feedback: Label = find_child('ErrorFeedback')
@onready var _info: RichTextLabel = find_child('Info')


#region Godot ######################################################################################
func _ready() -> void:
	register_text_enter(_input)
	
	# Connect to own signals
	confirmed.connect(_create)
	canceled.connect(clear_fields)
	close_requested.connect(clear_fields)
	about_to_popup.connect(on_about_to_popup)
	
	# Connect to childs' signals
	_input.text_changed.connect(_update_name)


#endregion

#region Virtual ####################################################################################
func _create() -> void:
	pass


func _clear_fields() -> void:
	pass


func _on_about_to_popup() -> void:
	pass


#endregion

#region Public #####################################################################################
func clear_fields() -> void:
	_input.clear()
	_error_feedback.hide()
	_info.clear()
	_info.size = _info.custom_minimum_size
	_clear_fields()


func on_about_to_popup() -> void:
	PopochiuUtils.override_font(
		_info, 'normal_font', get_theme_font("main", "EditorFonts")
	)
	PopochiuUtils.override_font(
		_info, 'bold_font', get_theme_font("bold", "EditorFonts")
	)
	PopochiuUtils.override_font(
		_info, 'mono_font', get_theme_font("source", "EditorFonts")
	)
	
	_on_about_to_popup()


#endregion

#region SetGet #####################################################################################
func set_main_dock(value: Panel) -> void:
	_main_dock = value


#endregion

#region Private ####################################################################################
func _update_name(new_text: String) -> void:
	if _error_feedback.visible:
		_error_feedback.hide()
	
	_name = new_text.to_pascal_case()


func _update_size_and_position() -> void:
	reset_size()
	move_to_center()


#endregion
