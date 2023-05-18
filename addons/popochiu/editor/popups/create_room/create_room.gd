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

const ROOM_STATE_TEMPLATE :=\
'res://addons/popochiu/engine/templates/room_state_template.gd'
const ROOM_SCRIPT_TEMPLATE :=\
'res://addons/popochiu/engine/templates/room_template.gd'
const BASE_ROOM_PATH :=\
'res://addons/popochiu/engine/objects/room/popochiu_room.tscn'
const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const PopochiuDock :=\
preload('res://addons/popochiu/editor/main_dock/popochiu_dock.gd')

var show_set_as_main := false : set = _set_show_set_as_main

var _room_name := ''
var _room_path := ''
var _room_path_template := ''
var _pascal_name := ''

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
	if _room_name.is_empty():
		_error_feedback.show()
		return
	
	# TODO: Check that there is not a room in the same PATH.
	# TODO: Delete created files if creation is not complete.
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the room
	DirAccess.make_dir_absolute(_main_dock.ROOMS_PATH + _room_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the state Resource for the room and a script so devs can add extra
	# properties to that state
	var state_template: Script = load(ROOM_STATE_TEMPLATE)
	if ResourceSaver.save(state_template, _room_path + '_state.gd') != OK:
		push_error('[Popochiu] Could not create room state script: %s' %\
		_room_name)
		# TODO: Show feedback in the popup
		return
	
	var room_resource: PopochiuRoomData = load(_room_path + '_state.gd').new()
	room_resource.script_name = _pascal_name
	room_resource.scene = _room_path + '.tscn'
	room_resource.resource_name = _pascal_name
	
	if ResourceSaver.save(room_resource, _room_path + '.tres') != OK:
		push_error(
			"[Popochiu] Couldn't create PopochiuRoomData for room: %s" %\
			_room_name
		)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the room
	var room_script: Script = load(ROOM_SCRIPT_TEMPLATE)
	var new_code := room_script.source_code
	
	room_script.source_code = ''
	
	if ResourceSaver.save(room_script, _room_path + '.gd') != OK:
		push_error("[Popochiu] Couldn't create script: %s" % _room_name)
		# TODO: Show feedback in the popup
		return
	
	new_code = new_code.replace(
		'room_state_template',
		'room_%s_state' % _room_name
	)
	
	new_code = new_code.replace(
		'Data = null',
		"Data = load('%s.tres')" % _room_path
	)
	
	room_script = load(_room_path + '.gd')
	room_script.source_code = new_code
	
	if ResourceSaver.save(room_script, _room_path + '.gd') != OK:
		push_error('[Popochiu] Could not update script: %s' %\
		_room_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the room instance
	var new_room: PopochiuRoom = preload(BASE_ROOM_PATH).instantiate()
	# 	The script is assigned first so that other properties will not be
	# 	overwritten by that assignment.
	new_room.set_script(load(_room_path + '.gd'))
	
	new_room.name = 'Room' + _pascal_name
	new_room.script_name = _pascal_name
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Save the room scene (.tscn)
	var new_room_packed_scene: PackedScene = PackedScene.new()
	new_room_packed_scene.pack(new_room)
	if ResourceSaver.save(new_room_packed_scene, _room_path + '.tscn') != OK:
		push_error("[Popochiu] Couldn't create room: %s" % _room_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the created room to Popochiu's rooms list
	if _main_dock.add_resource_to_popochiu(
		'rooms', ResourceLoader.load(_room_path + '.tres')
	) != OK:
		push_error(
			"[Popochiu] Couldn't add the created room to Popochiu: %s" %\
			_room_name
		)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the room to the R singleton
	PopochiuResources.update_autoloads(true)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of rooms in the dock
	var row := (_main_dock as PopochiuDock).add_to_list(
		Constants.Types.ROOM, _pascal_name
	)
	
	# Establecer como la escena principal
	if _set_as_main_check.pressed:
		_main_dock.set_main_scene(room_resource.scene)
		row.is_main = true # Para que se vea el corazón
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open the scene in the editor
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.select_file(_room_path + '.tscn')
	_main_dock.ei.open_scene_from_path(_room_path + '.tscn')
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# That's all!
	hide()


func _clear_fields() -> void:
	_room_name = ''
	_room_path = ''
	_set_as_main_check.button_pressed = false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_main_dock(node: Panel) -> void:
	super(node)
	
	if not _main_dock: return
	
	# res://popochiu/rooms
	_room_path_template = _main_dock.ROOMS_PATH + '%s/room_%s'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_room_name = _name.to_snake_case()
		_pascal_name = _name
		_room_path = _room_path_template % [_room_name, _room_name]

		_info.text = (
			'In [b]%s[/b] the following files will be created:\
			\n[code]%s, %s and %s[/code]' \
			% [
				_main_dock.ROOMS_PATH + _room_name,
				'room_' + _room_name + '.tscn',
				'room_' + _room_name + '.gd',
				'room_' + _room_name + '.tres'
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
