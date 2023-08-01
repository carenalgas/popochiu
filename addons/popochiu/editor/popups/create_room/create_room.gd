# Creates a PopochiuRoom.
# 
# It creates all the necessary files to make a PopochiuRoom to work and
# to store its state:
# - RoomXXX.tsn
# - RoomXXX.gd
# - RoomXXX.tres
# - RoomXXXState.gd
@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'

# TODO: Giving a proper class name to PopochiuDock eliminates the need to preload it
# and to cast it as the right type later in code.
const PopochiuDock := preload('res://addons/popochiu/editor/main_dock/popochiu_dock.gd')

var show_set_as_main := false : set = _set_show_set_as_main

var _new_room_name := ''
var _factory: PopochiuRoomFactory

@onready var _set_as_main: PanelContainer = find_child('SetAsMainContainer')
@onready var _set_as_main_check: CheckBox = _set_as_main.find_child('CheckBox')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	about_to_popup.connect(_check_if_first_room)
	
	PopochiuUtils.override_font(
		_set_as_main.find_child('RichTextLabel'),
		'normal_font', get_theme_font("main", "EditorFonts")
	)
	PopochiuUtils.override_font(
		_set_as_main.find_child('RichTextLabel'),
		'bold_font', get_theme_font("bold", "EditorFonts")
	)
	
	_clear_fields()
	_set_as_main.hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _create() -> void:
	if _new_room_name.is_empty():
		_error_feedback.show()
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Setup the prop helper and use it to create the prop
	_factory = PopochiuRoomFactory.new(_main_dock)

	var room_scene = _factory.create(_new_room_name, _set_as_main_check.button_pressed)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open the scene in the editor
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.select_file(room_scene.scene_file_path)
	_main_dock.ei.open_scene_from_path(room_scene.scene_file_path)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# That's all!
	clear_fields()
	hide()


func _clear_fields() -> void:
	_new_room_name = ''
	_set_as_main_check.button_pressed = false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_main_dock(node: Panel) -> void:
	super(node)
	
	if not _main_dock: return
	

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_room_name = _name.to_snake_case()

		_info.text = (
			'In [b]%s[/b] the following files will be created:\
			\n[code]%s, %s and %s[/code]' \
			% [
				_main_dock.ROOMS_PATH + _new_room_name,
				'room_' + _new_room_name + '.tscn',
				'room_' + _new_room_name + '.gd',
				'room_' + _new_room_name + '.tres'
			]
		)
		_info.show()
	else:
		_info.clear()
		_info.hide()


func _check_if_first_room() -> void:
	# Mostrar una casilla de verificación para establecer la habitación a crear
	# como la escene principal del proyecto si se trata de la primera.
#	self.show_set_as_main = _main_dock.popochiu.rooms.is_empty()
	self.show_set_as_main = PopochiuResources.get_section('rooms').is_empty()


func _set_show_set_as_main(value: bool) -> void:
	show_set_as_main = value
	
	if not _set_as_main: return
	
	_set_as_main.visible = value
