@tool
extends AcceptDialog

signal move_requested(id)
signal gui_selected(gui_name)

const ImporterDefaults := preload("res://addons/popochiu/engine/others/importer_defaults.gd")
const SCALE_MESSAGE :=\
"[center]▶ Base size = 320x180 | [b]scale = ( %.2f, %.2f )[/b] ◀[/center]\n" +\
"By default the GUI will scale to match your game size. " +\
"You can change this in [img]%s[/img] [b]Settings[/b] with the" +\
" [code]Scale Gui[/code] checkbox."
const GUITemplateButton := preload(
	"res://addons/popochiu/editor/popups/setup/gui_template_button.gd"
)

var es: EditorSettings = null

var _selected_template: GUITemplateButton
var _is_closing := false

@onready var welcome: RichTextLabel = %Welcome
@onready var game_width: SpinBox = %GameWidth
@onready var game_height: SpinBox = %GameHeight
@onready var scale_message: RichTextLabel = %ScaleMessage
@onready var test_width: SpinBox = %TestWidth
@onready var test_height: SpinBox = %TestHeight
@onready var game_type: OptionButton = %GameType
# GUI templates section
@onready var gui_templates: GridContainer = %GUITemplates
@onready var gui_templates_title: Label = %GUITemplatesTitle
@onready var gui_templates_description: Label = %GUITemplatesDescription
@onready var template_description_container: PanelContainer = %TemplateDescriptionContainer
@onready var template_description: RichTextLabel = %TemplateDescription
@onready var btn_change_template: Button = %BtnChangeTemplate


#region Godot ######################################################################################
func _ready() -> void:
	# Connect to own signals
	confirmed.connect(_on_close)
	close_requested.connect(_on_close)
	about_to_popup.connect(_on_about_to_popup)
	
	# Connect to child signals
	game_width.value_changed.connect(_update_scale)
	game_height.value_changed.connect(_update_scale)
	btn_change_template.pressed.connect(_show_template_change_confirmation)
	
	# Set default state
	template_description_container.hide()
	template_description.text = ""
	
	hide()


#endregion

#region Public #####################################################################################
func appear(show_welcome := false) -> void:
	_is_closing = false
	_selected_template = null
	btn_change_template.hide()
	
	scale_message.modulate = Color(
		"#000" if es.get_setting("interface/theme/preset").find("Light3D") > -1 else "#fff"
	)
	scale_message.modulate.a = 0.8

	if not show_welcome:
		welcome.text =\
		"[center][shake][b]POPOCHIU \\( u )3(u)/[/b][/shake][/center]"
		btn_change_template.disabled = true
		btn_change_template.show()
	
	# ---- Set initial values for fields ---------------------------------------
	game_width.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH)
	game_height.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	test_width.value = ProjectSettings.get_setting(PopochiuResources.TEST_WIDTH)
	test_height.value = ProjectSettings.get_setting(PopochiuResources.TEST_HEIGHT)
	scale_message.text = _get_scale_message()
	
	game_type.selected = 0
	
	if ProjectSettings.get_setting(PopochiuResources.STRETCH_MODE) == "canvas_items":
		match ProjectSettings.get_setting(PopochiuResources.STRETCH_ASPECT):
			"expand":
				game_type.selected = 1
			"keep":
				game_type.selected = 2
	
	# Load the list of templates
	await _load_templates()
	
	_select_config_template()
	
	if show_welcome:
		# Make Pixel the default game type checked during first run
		game_type.selected = 2
	
	popup_centered(min_size)
	
	if PopochiuResources.GUI_GAME_SCENE in EditorInterface.get_open_scenes():
		_show_gui_warning()
		
		for btn: Button in gui_templates.get_children():
			btn.disabled = true
		
		template_description_container.hide()
	
	await get_tree().process_frame
	reset_size()
	
	await get_tree().process_frame
	move_to_center()


#endregion

#region Private ####################################################################################
func _on_close() -> void:
	if _is_closing:
		return
	
	for idx in range(1, gui_templates.get_child_count()):
		gui_templates.get_child(idx).queue_free()
	
	_is_closing = true
	
	ProjectSettings.set_setting(PopochiuResources.DISPLAY_WIDTH, int(game_width.value))
	ProjectSettings.set_setting(PopochiuResources.DISPLAY_HEIGHT, int(game_height.value))
	ProjectSettings.set_setting(PopochiuResources.TEST_WIDTH, int(test_width.value))
	ProjectSettings.set_setting(PopochiuResources.TEST_HEIGHT, int(test_height.value))
	
	var settings := PopochiuResources.get_settings()
	settings.is_pixel_art_game = false
	
	match game_type.selected:
		1:
			ProjectSettings.set_setting(PopochiuResources.STRETCH_MODE, "canvas_items")
			ProjectSettings.set_setting(PopochiuResources.STRETCH_ASPECT, "expand")
		2:
			ProjectSettings.set_setting(PopochiuResources.STRETCH_MODE, "canvas_items")
			ProjectSettings.set_setting(PopochiuResources.STRETCH_ASPECT, "keep")
			
			settings.is_pixel_art_game = true
	
	PopochiuResources.save_settings(settings)
	
	if PopochiuResources.get_data_value("setup", "done", false) == false:
		gui_selected.emit(_selected_template.name)
	
	_save_settings()


func _on_about_to_popup() -> void:
	welcome.add_theme_font_override(
		"bold_font", get_theme_font("bold", "EditorFonts")
	)
	scale_message.add_theme_font_override(
		"normal_font", get_theme_font("main", "EditorFonts")
	)
	scale_message.add_theme_font_override(
		"bold_font", get_theme_font("bold", "EditorFonts")
	)
	scale_message.add_theme_font_override(
		"mono_font", get_theme_font("doc_source", "EditorFonts")
	)
	gui_templates_title.add_theme_font_override(
		"font", get_theme_font("bold", "EditorFonts")
	)
	gui_templates_description.add_theme_font_override(
		"font", get_theme_font("doc_source", "EditorFonts")
	)
	template_description.add_theme_font_override(
		"bold_font", get_theme_font("bold", "EditorFonts")
	)


func _save_settings() -> void:
	assert(ProjectSettings.save() == OK, "[Popochiu] Could not save Project settings")


func _update_scale(_value: float) -> void:
	scale_message.text = _get_scale_message()


func _get_scale_message() -> String:
	var scale :=\
	Vector2(game_width.value, game_height.value) / Vector2(320.0, 180.0)
	return SCALE_MESSAGE % [
		scale.x, scale.y,
		"res://addons/popochiu/editor/popups/setup/godot_tools_%s.png" %\
		("light" if es.get_setting("interface/theme/preset").find("Light") > -1\
		else "dark"),
	]


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
		_on_gui_template_selected(gui_templates.get_child(0))


func _update_imports() -> void:
	# TODO: Browse file system for .import files for images and update them to
	# match the current Game type selection
	pass


func _show_gui_warning() -> void:
	var warning_dialog := AcceptDialog.new()
	_setup_inner_dialog(
		warning_dialog,
		"GUI template warning",
		"The GUI scene (graphic_interface) is currently opened in the Editor.\n\nIn order to change\
 the GUI template please close that scene first."
	)
	
	add_child(warning_dialog)
	warning_dialog.popup_centered()


func _show_template_change_confirmation() -> void:
	var confirmation_dialog := ConfirmationDialog.new()
	_setup_inner_dialog(
		confirmation_dialog,
		"Confirm GUI template change",
		"You changed the GUI template, making this will override any changes you made to the files\
 in res://game/graphic_interface/.\n\nAre you sure you want to make the change?"
	)
	
	confirmation_dialog.confirmed.connect(
		func():
			confirmation_dialog.queue_free()
			gui_selected.emit(_selected_template.name)
			_save_settings()
	)
	
	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()


func _setup_inner_dialog(dialog: Window, ttl: String, txt: String) -> void:
	dialog.title = ttl
	dialog.dialog_text = txt
	dialog.dialog_autowrap = true
	dialog.min_size.x = size.x - 64


func _load_templates() -> void:
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
		
		gui_templates.add_child(button)


#endregion
