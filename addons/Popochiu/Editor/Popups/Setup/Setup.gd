@tool
extends AcceptDialog

const ImporterDefaults :=\
preload('res://addons/Popochiu/Engine/Others/ImporterDefaults.gd')
const SCALE_MESSAGE :=\
'[center]▶ Base size = 320x180 | [b]scale = ( %.2f, %.2f )[/b] ◀[/center]\n' +\
'By default the GUI will scale to match your game size. ' +\
'You can change this in [img]%s[/img] [b]Settings[/b] with the' +\
' [code]"Scale Gui"[/code] checkbox.'

var es: EditorSettings = null

@onready var _welcome: RichTextLabel = find_child('Welcome')
@onready var _welcome_separator: HSeparator = find_child('WelcomeSeparator')
@onready var _game_width: SpinBox = find_child('GameWidth')
@onready var _scale_msg: RichTextLabel = find_child('ScaleMessage')
@onready var _game_height: SpinBox = find_child('GameHeight')
@onready var _test_width: SpinBox = find_child('TestWidth')
@onready var _test_height: SpinBox = find_child('TestHeight')
@onready var _game_type: OptionButton = find_child('GameType')
@onready var _btn_update_imports: Button = find_child('BtnUpdateFiles')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	# Connect to signals
	confirmed.connect(_update_project_settings)
	close_requested.connect(_update_project_settings)
	_game_width.value_changed.connect(_update_scale)
	_game_height.value_changed.connect(_update_scale)
	_btn_update_imports.pressed.connect(_update_imports)
	
	# Set default state
	_btn_update_imports.hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func appear(show_welcome := false) -> void:
	_welcome.hide()
	_welcome_separator.hide()
	_welcome.add_theme_font_override(
		'bold_font', get_theme_font('bold', 'EditorFonts')
	)
	_scale_msg.add_theme_font_override(
		'normal_font', get_theme_font('main', 'EditorFonts')
	)
	_scale_msg.add_theme_font_override(
		'bold_font', get_theme_font('bold', 'EditorFonts')
	)
	_scale_msg.add_theme_font_override(
		'mono_font', get_theme_font('doc_source', 'EditorFonts')
	)
	_scale_msg.modulate = Color(\
	'#000' if es.get_setting('interface/theme/preset').find('Light3D') > -1\
	else '#fff')
	_scale_msg.modulate.a = 0.8

	if show_welcome:
		_welcome.show()
		_welcome_separator.show()
	
	# Set initial values for fields
	_game_width.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH)
	_game_height.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	_test_width.value = ProjectSettings.get_setting(PopochiuResources.TEST_WIDTH)
	_test_height.value = ProjectSettings.get_setting(PopochiuResources.TEST_HEIGHT)
	_scale_msg.text = _get_scale_msg()
	
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
	
	popup_centered_clamped(Vector2(480.0, 180.0))
	get_ok_button().text = 'Close'


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

#		if _game_type.selected == 1:
#			ProjectSettings.set_setting(
#				'importer_defaults/texture',
#				null
#			)
#		else:
#			ProjectSettings.set_setting(
#				'importer_defaults/texture',
#				ImporterDefaults.PIXEL_TEXTURES
#			)
	else:
		ProjectSettings.set_setting(PopochiuResources.STRETCH_MODE, 'disabled')
		ProjectSettings.set_setting(PopochiuResources.STRETCH_ASPECT, 'ignore')
	
	assert(\
		ProjectSettings.save() == OK,\
		'[Popochiu] Could not save Project settings'\
	)


func _update_scale(_value: float) -> void:
	_scale_msg.text = _get_scale_msg()


func _get_scale_msg() -> String:
	var scale :=\
	Vector2(_game_width.value, _game_height.value) / Vector2(320.0, 180.0)
	return SCALE_MESSAGE % [
		scale.x, scale.y,
		'res://addons/Popochiu/Editor/Popups/Setup/godot_tools_%s.png' %\
		('light' if es.get_setting('interface/theme/preset').find('Light3D') > -1\
		else 'dark'),
	]


func _update_imports() -> void:
	# TODO: Browse file system for .import files for images and update them to
	# match the current Game type selection
	pass
