@tool
extends AcceptDialog

signal move_requested(id)

const ImporterDefaults :=\
preload('res://addons/popochiu/engine/others/importer_defaults.gd')
const SCALE_MESSAGE :=\
'[center]▶ Base size = 320x180 | [b]scale = ( %.2f, %.2f )[/b] ◀[/center]\n' +\
'By default the GUI will scale to match your game size. ' +\
'You can change this in [img]%s[/img] [b]Settings[/b] with the' +\
' [code]"Scale Gui"[/code] checkbox.'

var es: EditorSettings = null

@onready var _welcome = %Welcome
@onready var _welcome_separator = %WelcomeSeparator
@onready var _game_width = %GameWidth
@onready var _game_height = %GameHeight
@onready var _scale_message = %ScaleMessage
@onready var _test_width = %TestWidth
@onready var _test_height = %TestHeight
@onready var _game_type = %GameType
@onready var _advanced = %Advanced
@onready var _btn_move_gi = %BtnMoveGI
@onready var _btn_move_tl = %BtnMoveTL
@onready var _btn_update_files = %BtnUpdateFiles


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	# Connect to signals
	confirmed.connect(_update_project_settings)
	close_requested.connect(_update_project_settings)
	_game_width.value_changed.connect(_update_scale)
	_game_height.value_changed.connect(_update_scale)
	_btn_move_gi.pressed.connect(_move_gi)
	_btn_move_tl.pressed.connect(_move_tl)
	_btn_update_files.pressed.connect(_update_imports)
	
	# Set default state
	_advanced.hide()
	_btn_move_gi.hide()
	_btn_move_tl.hide()
	_btn_update_files.hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func appear(show_welcome := false) -> void:
	_welcome.add_theme_font_override(
		'bold_font', get_theme_font('bold', 'EditorFonts')
	)
	_scale_message.add_theme_font_override(
		'normal_font', get_theme_font('main', 'EditorFonts')
	)
	_scale_message.add_theme_font_override(
		'bold_font', get_theme_font('bold', 'EditorFonts')
	)
	_scale_message.add_theme_font_override(
		'mono_font', get_theme_font('doc_source', 'EditorFonts')
	)
	_scale_message.modulate = Color(\
	'#000' if es.get_setting('interface/theme/preset').find('Light3D') > -1\
	else '#fff')
	_scale_message.modulate.a = 0.8

	if not show_welcome:
		_welcome.text =\
		'[center][shake][b]POPOCHIU \\( u )3(u)/[/b][/shake][/center]'
		update_state()
	
	# Set initial values for fields
	_game_width.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH)
	_game_height.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	_test_width.value = ProjectSettings.get_setting(PopochiuResources.TEST_WIDTH)
	_test_height.value = ProjectSettings.get_setting(PopochiuResources.TEST_HEIGHT)
	_scale_message.text = _get_scale_message()
	
	_game_type.selected = 0
	if ProjectSettings.get_setting(PopochiuResources.STRETCH_MODE) == 'canvas_items'\
	and ProjectSettings.get_setting(PopochiuResources.STRETCH_ASPECT) == 'keep':
		_game_type.selected = 1
		
		if ProjectSettings.get_setting(PopochiuResources.IMPORTER_TEXTURE)\
		and ProjectSettings.get_setting(PopochiuResources.IMPORTER_TEXTURE).values()\
		== ImporterDefaults.PIXEL_TEXTURES.values():
			_game_type.selected = 2
	
	if show_welcome:
		# Make Pixel the default game type checked during first run
		_game_type.selected = 2
	
	popup_centered_clamped(Vector2(480.0, 180.0), 0.5)
	get_ok_button().text = 'Close'


func update_state() -> void:
	_advanced.hide()
	_btn_move_gi.hide()

	if not PopochiuResources.get_data_value('setup', 'gi_moved', false):
		_advanced.show()
		_btn_move_gi.show()

	if not PopochiuResources.get_data_value('setup', 'tl_moved', false):
		_advanced.show()
		_btn_move_tl.show()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_project_settings() -> void:
	ProjectSettings.set_setting(
		PopochiuResources.DISPLAY_WIDTH,
		int(_game_width.value)
	)
	ProjectSettings.set_setting(
		PopochiuResources.DISPLAY_HEIGHT,
		int(_game_height.value)
	)
	ProjectSettings.set_setting(
		PopochiuResources.TEST_WIDTH,
		int(_test_width.value)
	)
	ProjectSettings.set_setting(
		PopochiuResources.TEST_HEIGHT,
		int(_test_height.value)
	)
	
	if _game_type.selected != 0:
		ProjectSettings.set_setting(PopochiuResources.STRETCH_MODE, 'canvas_items')
		ProjectSettings.set_setting(PopochiuResources.STRETCH_ASPECT, 'keep')
	else:
		ProjectSettings.set_setting(PopochiuResources.STRETCH_MODE, 'disabled')
		ProjectSettings.set_setting(PopochiuResources.STRETCH_ASPECT, 'ignore')
	
	assert(\
		ProjectSettings.save() == OK,\
		'[Popochiu] Could not save Project settings'\
	)


func _update_scale(_value: float) -> void:
	_scale_message.text = _get_scale_message()


func _get_scale_message() -> String:
	var scale :=\
	Vector2(_game_width.value, _game_height.value) / Vector2(320.0, 180.0)
	return SCALE_MESSAGE % [
		scale.x, scale.y,
		'res://addons/popochiu/editor/popups/setup/godot_tools_%s.png' %\
		('light' if es.get_setting('interface/theme/preset').find('Light') > -1\
		else 'dark'),
	]


func _move_gi() -> void:
	_btn_move_gi.disabled = true
	move_requested.emit(PopochiuResources.GI)


func _move_tl() -> void:
	_btn_move_tl.disabled = true
	move_requested.emit(PopochiuResources.TL)


func _update_imports() -> void:
	# TODO: Browse file system for .import files for images and update them to
	# match the current Game type selection
	pass
