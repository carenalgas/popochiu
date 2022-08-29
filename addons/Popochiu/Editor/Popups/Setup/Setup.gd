tool
extends AcceptDialog

const ImporterDefaults :=\
preload('res://addons/Popochiu/Engine/Others/ImporterDefaults.gd')

onready var _welcome: Label = find_node('Welcome')
onready var _game_width: SpinBox = find_node('GameWidth')
onready var _game_height: SpinBox = find_node('GameHeight')
onready var _test_width: SpinBox = find_node('TestWidth')
onready var _test_height: SpinBox = find_node('TestHeight')
onready var _game_type: OptionButton = find_node('GameType')
onready var _btn_update_imports: Button = find_node('BtnUpdateFiles')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	# Connect to signals
	connect('popup_hide', self, '_update_project_settings')
	_btn_update_imports.connect('pressed', self, '_update_imports')
	
	# Set default state
	_btn_update_imports.hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func appear(show_welcome := false) -> void:
	_welcome.hide()

	if show_welcome:
		_welcome.show()
	
	# Set initial values for fields
	_game_width.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH)
	_game_height.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	_test_width.value = ProjectSettings.get_setting(PopochiuResources.TEST_WIDTH)
	_test_height.value = ProjectSettings.get_setting(PopochiuResources.TEST_HEIGHT)
	
	_game_type.selected = 0
	if ProjectSettings.get_setting(PopochiuResources.STRETCH_MODE) == '2d'\
	and ProjectSettings.get_setting(PopochiuResources.STRETCH_ASPECT) == 'keep':
		_game_type.selected = 1
		
		if ProjectSettings.get_setting(PopochiuResources.IMPORTER_TEXTURE).values()\
		== ImporterDefaults.PIXEL_TEXTURES.values():
			_game_type.selected = 2
	
	popup_centered_minsize(Vector2(480.0, 180.0))
	get_ok().text = 'Close'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_project_settings() -> void:
	ProjectSettings.set_setting('display/window/size/width', int(_game_width.value))
	ProjectSettings.set_setting('display/window/size/height', int(_game_height.value))
	ProjectSettings.set_setting('display/window/size/test_width', int(_test_width.value))
	ProjectSettings.set_setting('display/window/size/test_height', int(_test_height.value))
	
	if _game_type.selected != 0:
		ProjectSettings.set_setting('display/window/stretch/mode', '2d')
		ProjectSettings.set_setting('display/window/stretch/aspect', 'keep')

		if _game_type.selected == 1:
			ProjectSettings.set_setting(
				'importer_defaults/texture',
				null
			)
		else:
			ProjectSettings.set_setting(
				'importer_defaults/texture',
				ImporterDefaults.PIXEL_TEXTURES
			)
	else:
		ProjectSettings.set_setting('display/window/stretch/mode', 'disabled')
		ProjectSettings.set_setting('display/window/stretch/aspect', 'ignore')
	
	assert(
		ProjectSettings.save() == OK,
		'[Popochiu] Could not save Project settings'
	)


func _update_imports() -> void:
	# TODO: Browse file system for .import files for images and update them to
	# match the current Game type selection
	pass
