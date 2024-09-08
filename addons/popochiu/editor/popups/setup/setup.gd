@tool
extends Control

signal template_copy_completed
signal size_calculated

enum GameTypes {
	CUSTOM,
	HD,
	RETRO_PIXEL,
}

const SCALE_MESSAGE =\
"[center]▶ Base size = 356x200 | [b]scale = ( %.2f, %.2f )[/b] ◀[/center]\n\
By default the GUI will match your native game resolution. You can change this with the\
 [code]Project Settings > Popochiu > GUI > Experimental Scale Gui[/code] checkbox."
const COPY_ALPHA = 0.1
const GUITemplateButton = preload(
	"res://addons/popochiu/editor/popups/setup/gui_template_button.gd"
)
const PopochiuGuiTemplatesHelper = preload(
	"res://addons/popochiu/editor/helpers/popochiu_gui_templates_helper.gd"
)

var _selected_template: GUITemplateButton
var _is_closing := false
var _es := EditorInterface.get_editor_settings()

@onready var welcome: RichTextLabel = %Welcome
@onready var game_width: SpinBox = %GameWidth
@onready var game_height: SpinBox = %GameHeight
@onready var scale_message: RichTextLabel = %ScaleMessage
@onready var test_width: SpinBox = %TestWidth
@onready var test_height: SpinBox = %TestHeight
@onready var game_type: OptionButton = %GameType
# ---- GUI templates section -----------------------------------------------------------------------
@onready var gui_templates: HBoxContainer = %GUITemplates
@onready var gui_templates_title: Label = %GUITemplatesTitle
@onready var gui_templates_description: Label = %GUITemplatesDescription
@onready var template_description_container: PanelContainer = %TemplateDescriptionContainer
@onready var template_description: RichTextLabel = %TemplateDescription
@onready var btn_change_template: Button = %BtnChangeTemplate
@onready var copy_process_container: MarginContainer = %CopyProcessContainer
@onready var copy_process_panel: PanelContainer = %CopyProcessPanel
@onready var copy_process_label: Label = %CopyProcessLabel
@onready var copy_process_bar: ProgressBar = %CopyProcessBar


#region Godot ######################################################################################
func _ready() -> void:
	# Connect to child signals
	game_width.value_changed.connect(_update_scale)
	game_height.value_changed.connect(_update_scale)
	btn_change_template.pressed.connect(_show_template_change_confirmation)
	
	# Set default state
	template_description_container.hide()
	template_description.text = ""


#endregion

#region Public #####################################################################################
func on_about_to_popup() -> void:
	welcome.add_theme_font_override("bold_font", get_theme_font("bold", "EditorFonts"))
	scale_message.add_theme_font_override("normal_font", get_theme_font("main", "EditorFonts"))
	scale_message.add_theme_font_override("bold_font", get_theme_font("bold", "EditorFonts"))
	scale_message.add_theme_font_override("mono_font", get_theme_font("doc_source", "EditorFonts"))
	gui_templates_title.add_theme_font_override("font", get_theme_font("bold", "EditorFonts"))
	gui_templates_description.add_theme_font_override(
		"font", get_theme_font("doc_source", "EditorFonts")
	)
	template_description.add_theme_font_override("bold_font", get_theme_font("bold", "EditorFonts"))


func on_close() -> void:
	if _is_closing:
		return
	
	_is_closing = true
	
	ProjectSettings.set_setting(PopochiuResources.DISPLAY_WIDTH, int(game_width.value))
	ProjectSettings.set_setting(PopochiuResources.DISPLAY_HEIGHT, int(game_height.value))
	ProjectSettings.set_setting(PopochiuResources.TEST_WIDTH, int(test_width.value))
	ProjectSettings.set_setting(PopochiuResources.TEST_HEIGHT, int(test_height.value))
	
	match game_type.selected:
		GameTypes.HD:
			ProjectSettings.set_setting(PopochiuResources.STRETCH_MODE, "canvas_items")
			ProjectSettings.set_setting(PopochiuResources.STRETCH_ASPECT, "expand")
			
			PopochiuConfig.set_pixel_art_textures(false)
		GameTypes.RETRO_PIXEL:
			ProjectSettings.set_setting(PopochiuResources.STRETCH_MODE, "canvas_items")
			ProjectSettings.set_setting(PopochiuResources.STRETCH_ASPECT, "keep")
			
			PopochiuConfig.set_pixel_art_textures(true)
	
	if not PopochiuResources.is_setup_done() or not PopochiuResources.is_gui_set():
		PopochiuResources.set_data_value("setup", "done", true)
		await _copy_template(true)
	
	get_parent().queue_free()


func define_content(show_welcome := false) -> void:
	_is_closing = false
	_selected_template = null
	btn_change_template.hide()
	copy_process_container.hide()
	
	scale_message.modulate = Color(
		"#000" if "Light3D" in _es.get_setting("interface/theme/preset") else "#fff"
	)
	scale_message.modulate.a = 0.8
	
	copy_process_panel.add_theme_stylebox_override(
		"panel", get_theme_stylebox("panel", "PopupPanel")
	)

	if not show_welcome:
		welcome.text = "[center][b]POPOCHIU [shake]\\( u )3(u)/[/shake][/b][/center]"
		btn_change_template.disabled = true
		btn_change_template.show()
	
	# ---- Set initial values for fields ---------------------------------------
	game_width.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH)
	game_height.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	test_width.value = ProjectSettings.get_setting(PopochiuResources.TEST_WIDTH)
	test_height.value = ProjectSettings.get_setting(PopochiuResources.TEST_HEIGHT)
	scale_message.text = _get_scale_message()
	
	game_type.selected = GameTypes.CUSTOM
	
	if ProjectSettings.get_setting(PopochiuResources.STRETCH_MODE) == "canvas_items":
		match ProjectSettings.get_setting(PopochiuResources.STRETCH_ASPECT):
			"expand":
				game_type.selected = GameTypes.HD
			"keep":
				game_type.selected = GameTypes.RETRO_PIXEL
	
	# Load the list of templates
	await _load_templates()
	
	_select_config_template()
	
	if show_welcome:
		# Make Pixel the default game type checked during first run
		game_type.selected = GameTypes.RETRO_PIXEL
	
	if PopochiuResources.GUI_GAME_SCENE in EditorInterface.get_open_scenes():
		_show_gui_warning()
		
		for btn: Button in gui_templates.get_children():
			btn.disabled = true
		
		template_description_container.hide()
	
	_update_size()


#endregion

#region Private ####################################################################################
func _update_scale(_value: float) -> void:
	scale_message.text = _get_scale_message()


func _get_scale_message() -> String:
	var scale := Vector2(game_width.value, game_height.value) / PopochiuResources.RETRO_RESOLUTION
	return SCALE_MESSAGE % [scale.x, scale.y]


func _on_gui_template_selected(button: GUITemplateButton) -> void:
	for btn in gui_templates.get_children():
		if not btn is GUITemplateButton: continue
		
		(btn as GUITemplateButton).set_pressed_no_signal(false)
	
	button.set_pressed_no_signal(true)
	_selected_template = button
	
	template_description.text = button.description
	template_description_container.show()
	
	if PopochiuResources.get_data_value("setup", "done", false) == true:
		btn_change_template.disabled = (
			_selected_template.name == PopochiuResources.get_data_value("ui", "template", "")
		)
	
	_update_size()


func _select_config_template() -> void:
	var current_template: String = PopochiuResources.get_data_value("ui", "template", "")
	
	for btn: Button in gui_templates.get_children():
		if not btn is GUITemplateButton: continue
		
		btn.disabled = false
		
		if not btn.pressed.is_connected(_on_gui_template_selected):
			btn.pressed.connect(_on_gui_template_selected.bind(btn))
		
		if current_template == btn.name:
			_on_gui_template_selected(btn)
	
	if not _selected_template:
		_on_gui_template_selected(gui_templates.get_child(3))


func _show_gui_warning() -> void:
	var warning_dialog := AcceptDialog.new()
	_setup_inner_dialog(
		warning_dialog,
		"GUI template warning",
		"The GUI scene (gui.tscn) is currently opened in the Editor.\n\n" +\
		"In order to change the GUI template please close that scene first."
	)
	
	add_child(warning_dialog)
	warning_dialog.popup_centered()


func _show_template_change_confirmation() -> void:
	var confirmation_dialog := ConfirmationDialog.new()
	_setup_inner_dialog(
		confirmation_dialog,
		"Confirm GUI template change",
		"You changed the GUI template, making this will override any changes you made to the files\
 in res://game/gui/.\n\nAre you sure you want to make the change?"
	)
	
	confirmation_dialog.confirmed.connect(
		func():
			confirmation_dialog.queue_free()
			_copy_template()
	)
	
	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()


func _setup_inner_dialog(dialog: Window, ttl: String, txt: String) -> void:
	dialog.title = ttl
	dialog.dialog_text = txt
	dialog.dialog_autowrap = true
	dialog.min_size.x = size.x - 64


func _load_templates() -> void:
	for idx in range(1, gui_templates.get_child_count()):
		gui_templates.get_child(idx).free()
	
	# This is better than awating for SceneTree.process_frame
	await get_tree().process_frame
	
	for dir_name: String in DirAccess.get_directories_at(PopochiuResources.GUI_TEMPLATES_FOLDER):
		var template_info: PopochiuGUIInfo = load(PopochiuResources.GUI_TEMPLATES_FOLDER.path_join(
			"%s/%s_gui_info.tres" % [dir_name, dir_name]
		))
		
		var button := GUITemplateButton.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2.ONE * 128.0
		button.name = dir_name.to_pascal_case()
		button.text = (
			dir_name.capitalize() if template_info.title.is_empty() else template_info.title
		)
		button.description = template_info.description
		button.icon = template_info.icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.expand_icon = true
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		gui_templates.add_child(button)


func _copy_template(is_first_copy := false) -> void:
	get_parent().get_ok_button().disabled = true
	
	$PanelContainer/VBoxContainer.modulate.a = COPY_ALPHA
	copy_process_label.text = ""
	copy_process_bar.value = 0
	
	PopochiuGuiTemplatesHelper.copy_gui_template(
		_selected_template.name, _template_copy_progressed, _template_copy_completed
	)
	
	copy_process_container.show()
	
	# if true, make the popup visible so devs can see the copy process feedback
	if is_first_copy:
		get_parent().visible = true
		await template_copy_completed


func _template_copy_progressed(value: int, message: String) -> void:
	copy_process_label.text = message
	copy_process_bar.value = value


func _template_copy_completed() -> void:
	get_parent().get_ok_button().disabled = false
	btn_change_template.disabled = true
	$PanelContainer/VBoxContainer.modulate.a = 1
	
	copy_process_container.hide()
	template_copy_completed.emit()


func _update_size() -> void:
	# Wait for the popup content to be rendered in order to get its size
	await get_tree().create_timer(0.05).timeout
	
	custom_minimum_size = get_child(0).size
	size_calculated.emit()


#endregion
