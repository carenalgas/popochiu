tool
extends 'res://addons/Popochiu/Editor/Popups/CreationPopup.gd'
# Allows to create a new PopochiuRoom with the files required for its operation
# within Popochiu and to store its state:
#   Room???.tsn, Room???.gd, Room???.tres and Room???State.gd
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

const ROOM_STATE_TEMPLATE :=\
'res://addons/Popochiu/Engine/Templates/RoomStateTemplate.gd'
const ROOM_SCRIPT_TEMPLATE :=\
'res://addons/Popochiu/Engine/Templates/RoomTemplate.gd'
const BASE_ROOM_PATH :=\
'res://addons/Popochiu/Engine/Objects/Room/PopochiuRoom.tscn'
const Constants := preload('res://addons/Popochiu/PopochiuResources.gd')

var show_set_as_main := false setget _set_show_set_as_main

var _new_room_name := ''
var _new_room_path := ''
var _room_path_template := ''

onready var _set_as_main: PanelContainer = find_node('SetAsMainContainer')
onready var _set_as_main_check: CheckBox = _set_as_main.find_node('CheckBox')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	connect('about_to_show', self, '_check_if_first_room')
	
	_clear_fields()
	_set_as_main.hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func set_main_dock(node: PopochiuDock) -> void:
	.set_main_dock(node)
	
	# res://popochiu/Rooms
	_room_path_template = _main_dock.ROOMS_PATH + '%s/Room%s'


func create() -> void:
	if not _new_room_name:
		_error_feedback.show()
		return
	
	# TODO: Check that there is not a room in the same PATH.
	# TODO: Delete created files if creation is not complete.
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the room
	_main_dock.dir.make_dir_recursive(_main_dock.ROOMS_PATH + _new_room_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the state Resource for the room and a script so devs can add extra
	# properties to that state
	var state_template: Script = load(ROOM_STATE_TEMPLATE)
	if ResourceSaver.save(_new_room_path + 'State.gd', state_template) != OK:
		push_error('[Popochiu] Could not create room state script: %s' %\
		_new_room_name)
		# TODO: Show feedback in the popup
		return
	
	var room_resource: PopochiuRoomData = load(_new_room_path + 'State.gd').new()
	room_resource.script_name = _new_room_name
	room_resource.scene = _new_room_path + '.tscn'
	room_resource.resource_name = _new_room_name
	
	if ResourceSaver.save(_new_room_path + '.tres', room_resource) != OK:
		push_error('[Popochiu] Could not create PopochiuRoomData for room: %s' %\
		_new_room_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the room
	var room_template: Script = load(ROOM_SCRIPT_TEMPLATE)
	if ResourceSaver.save(_new_room_path + '.gd', room_template) != OK:
		push_error('[Popochiu] Could not create script: %s' %\
		_new_room_name)
		# TODO: Show feedback in the popup
		return
	
	# Assign the state to the room
	var room_script: Script = load(_new_room_path + '.gd')
	room_script.source_code = room_script.source_code.replace(
		'PopochiuRoomData = null',
		"PopochiuRoomData = preload('Room%s.tres')" % _new_room_name
	)
	ResourceSaver.save(_new_room_path + '.gd', room_script)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the room instance
	var new_room: PopochiuRoom = preload(BASE_ROOM_PATH).instance()
	# 	The script is assigned first so that other properties will not be
	# 	overwritten by that assignment.
	new_room.set_script(load(_new_room_path + '.gd'))
	new_room.script_name = _new_room_name
	new_room.name = 'Room' + _new_room_name
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Save the room scene (.tscn)
	var new_room_packed_scene: PackedScene = PackedScene.new()
	new_room_packed_scene.pack(new_room)
	if ResourceSaver.save(_new_room_path + '.tscn', new_room_packed_scene) != OK:
		push_error('[Popochiu] Could not create room: %s' % _new_room_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the created room to Popochiu's rooms list
	if _main_dock.add_resource_to_popochiu(
		'rooms', ResourceLoader.load(_new_room_path + '.tres')
	) != OK:
		push_error('[Popochiu] Could not add the created room to Popochiu: %s' %\
		_new_room_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of rooms in the dock
	var row := _main_dock.add_to_list(Constants.Types.ROOM, _new_room_name)
	
	# Establecer como la escena principal
	if _set_as_main_check.pressed:
		_main_dock.set_main_scene(room_resource.scene)
		row.is_main = true # Para que se vea el corazón
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open the scene in the editor
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.select_file(_new_room_path + '.tscn')
	_main_dock.ei.open_scene_from_path(_new_room_path + '.tscn')
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# That's all!
	hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	._update_name(new_text)

	if _name:
		_new_room_name = _name
		_new_room_path = _room_path_template % [_new_room_name, _new_room_name]

		_info.bbcode_text = (
			'In [b]%s[/b] the following files will be created:\n[code]%s, %s and %s[/code]' \
			% [
				_main_dock.ROOMS_PATH + _new_room_name,
				'Room' + _new_room_name + '.tscn',
				'Room' + _new_room_name + '.gd',
				'Room' + _new_room_name + '.tres'
			]
		)
	else:
		_info.clear()


func _clear_fields() -> void:
	._clear_fields()
	
	_new_room_name = ''
	_new_room_path = ''
	_set_as_main_check.pressed = false


func _check_if_first_room() -> void:
	# Mostrar una casilla de verificación para establecer la habitación a crear
	# como la escene principal del proyecto si se trata de la primera.
#	self.show_set_as_main = _main_dock.popochiu.rooms.empty()
	self.show_set_as_main = PopochiuResources.get_section('rooms').empty()


func _set_show_set_as_main(value: bool) -> void:
	show_set_as_main = value
	_set_as_main.visible = value
