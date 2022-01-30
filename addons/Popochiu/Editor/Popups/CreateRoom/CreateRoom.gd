tool
extends CreationPopup
# Permite crear una nueva habitación con los archivos necesarios para que funcione
# en el Popochiu: RoomRRR.tscn, RoomRRR.gd, RoomRRR.tres.

# TODO: Definir más propiedades en el popup de creación de la habitación: p. ej.
#		si va a tener al player, o los límites de la cámara. Aunque eso ya se
#		puede hacer una vez se abra el .tscn.

const ROOM_SCRIPT_TEMPLATE :=\
'res://addons/Popochiu/Engine/Templates/RoomTemplate.gd'
const BASE_ROOM_PATH :=\
'res://addons/Popochiu/Engine/Objects/Room/PopochiuRoom.tscn'

var show_set_as_main := false setget _set_show_set_as_main

var _new_room_name := ''
var _new_room_path := ''
var _room_path_template := ''

onready var _set_as_main: PanelContainer = find_node('SetAsMainContainer')
onready var _set_as_main_check: CheckBox = _set_as_main.find_node('CheckBox')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	connect('about_to_show', self, '_check_if_first_room')
	
	_clear_fields()
	_set_as_main.hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func set_main_dock(node: PopochiuDock) -> void:
	.set_main_dock(node)
	# Por defecto: res://popochiu/Rooms
	_room_path_template = _main_dock.ROOMS_PATH + '%s/Room%s'


func create() -> void:
	if not _new_room_name:
		_error_feedback.show()
		return
	
	# TODO: Verificar si no hay ya una habitación en el mismo PATH.
	# TODO: Eliminar archivos creados si la creación no se completa.
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el directorio donde se guardará la nueva habitación
	_main_dock.dir.make_dir_recursive(_main_dock.ROOMS_PATH + _new_room_name)

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el script de la nueva habitación
	var room_template := load(ROOM_SCRIPT_TEMPLATE)
	if ResourceSaver.save(_new_room_path + '.gd', room_template) != OK:
		push_error('[Popochiu] Could not create script: %s' %\
		_new_room_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear la instancia de la nueva habitación y asignarle el script creado
	var new_room: PopochiuRoom = preload(BASE_ROOM_PATH).instance()
	#	Primero se asigna el script para que no se vayan a sobrescribir otras
	#	propiedades por culpa de esa asignación.
	new_room.set_script(load(_new_room_path + '.gd'))
	new_room.script_name = _new_room_name
	new_room.name = 'Room' + _new_room_name
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el archivo de la escena
	var new_room_packed_scene: PackedScene = PackedScene.new()
	new_room_packed_scene.pack(new_room)
	if ResourceSaver.save(_new_room_path + '.tscn', new_room_packed_scene) != OK:
		push_error('[Popochiu] Could not create room: %s' % _new_room_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el Resource de la habitación
	var room_resource: PopochiuRoomData = PopochiuRoomData.new()
	room_resource.script_name = _new_room_name
	room_resource.scene = _new_room_path + '.tscn'
	room_resource.resource_name = _new_room_name
	if ResourceSaver.save(_new_room_path + '.tres', room_resource) != OK:
		push_error('[Popochiu] Could not create PopochiuRoomData for room: %s' %\
		_new_room_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Agregar la habitación al Popochiu
	if _main_dock.add_resource_to_popochiu(
		'rooms', ResourceLoader.load(_new_room_path + '.tres')
	) != OK:
		push_error('[Popochiu] Could not add the created room to Popochiu: %s' %\
		_new_room_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Actualizar la lista de habitaciones en el Dock
	var row := _main_dock.add_to_list(_main_dock.Types.ROOM, _new_room_name)
	
	# Establecer como la escena principal
	if _set_as_main_check.pressed:
		_main_dock.set_main_scene(room_resource.scene)
		row.is_main = true # Para que se vea el corazón
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir la escena creada en el editor
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.select_file(_new_room_path + '.tscn')
	_main_dock.ei.open_scene_from_path(_new_room_path + '.tscn')
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Fin
	hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
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
			])
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
	self.show_set_as_main = _main_dock.popochiu.rooms.empty()


func _set_show_set_as_main(value: bool) -> void:
	show_set_as_main = value
	_set_as_main.visible = value
