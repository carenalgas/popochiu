@tool
extends AcceptDialog

signal move_requested(id)
signal gui_selected(gui_name)

const ImporterDefaults :=\
preload('res://addons/popochiu/engine/others/importer_defaults.gd')
const SCALE_MESSAGE :=\
'[center]▶ Base size = 320x180 | [b]scale = ( %.2f, %.2f )[/b] ◀[/center]\n' +\
'By default the GUI will scale to match your game size. ' +\
'You can change this in [img]%s[/img] [b]Settings[/b] with the' +\
' [code]"Scale Gui"[/code] checkbox.'
const GUITemplateButton := preload("res://addons/popochiu/editor/popups/setup/gui_template_button.gd")

var es: EditorSettings = null
var _selected_template: GUITemplateButton

@onready var dflt_size := size
@onready var welcome = %Welcome
@onready var game_width = %GameWidth
@onready var game_height = %GameHeight
@onready var scale_message = %ScaleMessage
@onready var test_width = %TestWidth
@onready var test_height = %TestHeight
@onready var game_type = %GameType
@onready var advanced = %Advanced
@onready var btn_move_gi = %BtnMoveGI
@onready var btn_move_tl = %BtnMoveTL
@onready var btn_update_files = %BtnUpdateFiles
@onready var gui_templates: GridContainer = %GUITemplates
@onready var gui_templates_title: Label = %GUITemplatesTitle
@onready var gui_templates_description: Label = %GUITemplatesDescription
@onready var template_description_container: PanelContainer = %TemplateDescriptionContainer
@onready var template_description: RichTextLabel = %TemplateDescription


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	welcome.add_theme_font_override(
		'bold_font', get_theme_font('bold', 'EditorFonts')
	)
	scale_message.add_theme_font_override(
		'normal_font', get_theme_font('main', 'EditorFonts')
	)
	scale_message.add_theme_font_override(
		'bold_font', get_theme_font('bold', 'EditorFonts')
	)
	scale_message.add_theme_font_override(
		'mono_font', get_theme_font('doc_source', 'EditorFonts')
	)
	gui_templates_title.add_theme_font_override(
		"font", get_theme_font('bold', 'EditorFonts')
	)
	gui_templates_description.add_theme_font_override(
		"font", get_theme_font('doc_source', 'EditorFonts')
	)
	template_description.add_theme_font_override(
		'bold_font', get_theme_font('bold', 'EditorFonts')
	)
	
	# Connect to signals
	confirmed.connect(_on_close)
	close_requested.connect(_on_close)
	game_width.value_changed.connect(_update_scale)
	game_height.value_changed.connect(_update_scale)
	btn_move_gi.pressed.connect(_move_gi)
	btn_move_tl.pressed.connect(_move_tl)
	btn_update_files.pressed.connect(_update_imports)
	
	# Set default state
	advanced.hide()
	btn_move_gi.hide()
	btn_move_tl.hide()
	btn_update_files.hide()
	template_description_container.hide()
	template_description.text = ""


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func appear(show_welcome := false) -> void:
	scale_message.modulate = Color(
		'#000' if es.get_setting('interface/theme/preset').find('Light3D') > -1\
		else '#fff'
	)
	scale_message.modulate.a = 0.8

	if not show_welcome:
		welcome.text =\
		'[center][shake][b]POPOCHIU \\( u )3(u)/[/b][/shake][/center]'
		update_state()
	
	# ---- Set initial values for fields ---------------------------------------
	game_width.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH)
	game_height.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	test_width.value = ProjectSettings.get_setting(PopochiuResources.TEST_WIDTH)
	test_height.value = ProjectSettings.get_setting(PopochiuResources.TEST_HEIGHT)
	scale_message.text = _get_scale_message()
	
	game_type.selected = 0
	
	if ProjectSettings.get_setting(PopochiuResources.STRETCH_MODE) == 'canvas_items':
		match ProjectSettings.get_setting(PopochiuResources.STRETCH_ASPECT):
			'expand':
				game_type.selected = 1
			'keep':
				game_type.selected = 2
	
	_select_config_template()
	
	if show_welcome:
		# Make Pixel the default game type checked during first run
		game_type.selected = 2
	
	get_ok_button().text = 'Close'
	
	popup_centered_clamped(dflt_size, 0.5)
	
	if PopochiuResources.GRAPHIC_INTERFACE_POPOCHIU in PopochiuUtils.ei.get_open_scenes():
		_show_gui_warning()
		for btn in gui_templates.get_children():
			btn.disabled = true
		template_description_container.hide()


func update_state() -> void:
	advanced.hide()
	btn_move_gi.hide()

#	if not PopochiuResources.get_data_value('setup', 'gi_moved', false):
#		advanced.show()
#		btn_move_gi.show()
#
#	if not PopochiuResources.get_data_value('setup', 'tl_moved', false):
#		advanced.show()
#		btn_move_tl.show()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _on_close() -> void:
	ProjectSettings.set_setting(
		PopochiuResources.DISPLAY_WIDTH,
		int(game_width.value)
	)
	ProjectSettings.set_setting(
		PopochiuResources.DISPLAY_HEIGHT,
		int(game_height.value)
	)
	ProjectSettings.set_setting(
		PopochiuResources.TEST_WIDTH,
		int(test_width.value)
	)
	ProjectSettings.set_setting(
		PopochiuResources.TEST_HEIGHT,
		int(test_height.value)
	)
	
	var settings := PopochiuResources.get_settings()
	settings.is_pixel_art_game = false
	
	match game_type.selected:
		1:
			ProjectSettings.set_setting(PopochiuResources.STRETCH_MODE, 'canvas_items')
			ProjectSettings.set_setting(PopochiuResources.STRETCH_ASPECT, 'expand')
		2:
			ProjectSettings.set_setting(PopochiuResources.STRETCH_MODE, 'canvas_items')
			ProjectSettings.set_setting(PopochiuResources.STRETCH_ASPECT, 'keep')
			
			settings.is_pixel_art_game = true
	
	PopochiuResources.save_settings(settings)
	
	# Check if the GUI template changed and ask the dev if she is sure of the
	# change
	if PopochiuResources.get_data_value("setup", "done", false) == true and\
	 _selected_template.name != PopochiuResources.get_data_value(
		"ui", "template", ""
	):
		_show_template_change_confirmation()
	else:
		gui_selected.emit(_selected_template.name)
		_save_settings()


func _save_settings() -> void:
	assert(\
		ProjectSettings.save() == OK,\
		'[Popochiu] Could not save Project settings'\
	)


func _update_scale(_value: float) -> void:
	scale_message.text = _get_scale_message()


func _get_scale_message() -> String:
	var scale :=\
	Vector2(game_width.value, game_height.value) / Vector2(320.0, 180.0)
	return SCALE_MESSAGE % [
		scale.x, scale.y,
		'res://addons/popochiu/editor/popups/setup/godot_tools_%s.png' %\
		('light' if es.get_setting('interface/theme/preset').find('Light') > -1\
		else 'dark'),
	]


func _move_gi() -> void:
	btn_move_gi.disabled = true
	move_requested.emit(PopochiuResources.GI)


func _move_tl() -> void:
	btn_move_tl.disabled = true
	move_requested.emit(PopochiuResources.TL)


func _on_gui_template_selected(button: GUITemplateButton) -> void:
	for btn in gui_templates.get_children():
		if not btn is GUITemplateButton: continue
		
		(btn as GUITemplateButton).set_pressed_no_signal(false)
	
	button.set_pressed_no_signal(true)
	_selected_template = button
	
	template_description.text = button.description
	template_description_container.show()


func _select_config_template() -> void:
	for btn in gui_templates.get_children():
		if not btn is GUITemplateButton: continue
		
		btn.disabled = false
		
		if not btn.pressed.is_connected(_on_gui_template_selected):
			btn.pressed.connect(_on_gui_template_selected.bind(btn))
		
		if PopochiuResources.get_data_value("ui", "template", "") == btn.name:
			_on_gui_template_selected(btn)
	
	if not _selected_template:
		_selected_template = gui_templates.get_child(0)


func _update_imports() -> void:
	# TODO: Browse file system for .import files for images and update them to
	# match the current Game type selection
	pass


func _show_gui_warning() -> void:
	var warning_dialog := AcceptDialog.new()
	warning_dialog.title = "GUI template warning"
	warning_dialog.dialog_text = "The GUI scene (graphic_interface) is currently\
 opened in the Editor.\nIn order to change the GUI template please close that\
 scene first."
	
	add_child.call_deferred(warning_dialog)
	
	warning_dialog.popup_centered.call_deferred()


func _show_template_change_confirmation() -> void:
	var confirmation_dialog := ConfirmationDialog.new()
	confirmation_dialog.title = "Confirm GUI template change"
	confirmation_dialog.dialog_text = "You changed the GUI template.\
 Making this will override any changes you made to the files in res://popochiu/\
graphic_interface/.\nAre you sure you want to make the change?"
	
	confirmation_dialog.confirmed.connect(
		func():
			confirmation_dialog.queue_free()
			gui_selected.emit(_selected_template.name)
			_save_settings()
	)
	
	get_parent().add_child.call_deferred(confirmation_dialog)
	
	confirmation_dialog.popup_centered.call_deferred()
