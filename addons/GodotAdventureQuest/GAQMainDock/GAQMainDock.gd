tool
extends Panel
# Define un conjunto de botones y otros elementos para centralizar la configuración
# de los diferentes nodos que conforman el juego:
#	Rooms (Props, Hotspots, Regions), Characters, Inventory items, Dialog trees,
#	Interfaz gráfica.

# ------------------------------------------------------------------------------
# TODO: Definir más propiedades en el popup de creación de la habitación: p. ej.
#		si va a tener al player, o los límites de la cámara. Aunque eso ya se
#		puede hacer una vez se abra el .tscn.

signal room_created(room_name)

const GAQ_PATH := 'res://src/Autoload/GodotAdventureQuest.tscn'

export var rooms_path := 'res://src/Rooms/'

var ei: EditorInterface
var fs: EditorFileSystem

var _new_room_name := ''
var _new_room_path := ''
var _dir := Directory.new()
var _rooms_root: TreeItem


onready var _rooms: Container = find_node('Rooms')
onready var _btn_create_room: Button = find_node('BtnCreateRoom')
onready var _create_room_popup: ConfirmationDialog = find_node('PopupCreateRoom')
onready var _create_room_popup_input: LineEdit = _create_room_popup.find_node('Input')
onready var _create_room_popup_required: Label = _create_room_popup.find_node('Required')
onready var _create_room_popup_scene_path: Label = _create_room_popup.find_node('ScenePath')
onready var _create_room_popup_script_path: Label = _create_room_popup.find_node('ScriptPath')
onready var _room_path_template := rooms_path + '%s/Room%s'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_create_room_popup.register_text_enter(_create_room_popup_input)

	# Creación de habitaciones
	_btn_create_room.connect('pressed', self, '_show_create_room_popup')
	_create_room_popup.connect('confirmed', self, '_create_room')
	_create_room_popup.connect('popup_hide', self, '_clear_room_fields')
	_create_room_popup_input.connect('text_changed', self, '_update_room_path')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func fill_data() -> void:
	# Llenar la lista de habitaciones
	var rooms_dir: EditorFileSystemDirectory = fs.get_filesystem_path(rooms_path)
	for d in rooms_dir.get_subdir_count():
		var dir: EditorFileSystemDirectory = rooms_dir.get_subdir(d)
		for f in dir.get_file_count():
			var path = dir.get_file_path(f)

			if not fs.get_file_type(path) == "Resource":
				continue
			
			var room: GAQRoom = ResourceLoader.load(path) as GAQRoom

			var room_lbl: Label = Label.new()
			room_lbl.text = room.id

			_rooms.add_child(room_lbl)

	_rooms.move_child(_btn_create_room, _rooms.get_child_count())


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _show_create_room_popup() -> void:
	_create_room_popup.popup_centered()


func _create_room() -> void:
	if not _new_room_name:
		_create_room_popup_required.show()
		return
	
	# TODO: Verificar si no hay ya una habitación en el mismo PATH.
	# TODO: Mover esto a otro script para la organización de la vida.
	
	# Crear el directorio donde se guardará la nueva habitación ----------------
	_dir.make_dir(rooms_path + _new_room_name)

	# Crear el script de la nueva habitación -----------------------------------
	var room_template := load('res://script_templates/RoomTemplate.gd')
	if ResourceSaver.save(_new_room_path + '.gd', room_template) != OK:
		push_error('No se pudo crear el script de la habitación: %s' % _new_room_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return

	# Crear la instancia de la nueva habitación y asignarle el script creado ---
	var new_room: Room = preload('res://src/Nodes/Room/Room.tscn').instance()
	#	Primero se asigna el script para que no se vayan a sobrescribir otras
	#	propiedades por culpa de esa asignación.
	new_room.set_script(load(_new_room_path + '.gd'))
	new_room.script_name = _new_room_name
	new_room.name = 'Room' + _new_room_name
	
	# Crear el archivo de la escena --------------------------------------------
	var new_room_packed_scene: PackedScene = PackedScene.new()
	new_room_packed_scene.pack(new_room)
	if ResourceSaver.save(_new_room_path + '.tscn', new_room_packed_scene) != OK:
		push_error('No se pudo crear la habitación: %s' % _new_room_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# Crear el Resource de la habitación ---------------------------------------
	var room_resource: GAQRoom = GAQRoom.new()
	room_resource.id = _new_room_name
	room_resource.path = _new_room_path + '.tscn'
	room_resource.resource_name = _new_room_name
	if ResourceSaver.save(_new_room_path + '.tres', room_resource) != OK:
		push_error('No se pudo crear el GAQRoom de la habitación: %s' % _new_room_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return

	# Agregar la habitación al Godot Adventure Quest ---------------------------
	var gaq: Node = ResourceLoader.load(GAQ_PATH).instance()
	gaq.rooms.append(ResourceLoader.load(_new_room_path + '.tres'))
	var new_gaq: PackedScene = PackedScene.new()
	new_gaq.pack(gaq)
	if ResourceSaver.save(GAQ_PATH, new_gaq) != OK:
		push_error('No se pudo agregar la habitación a GAQ: %s' % _new_room_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	ei.reload_scene_from_path(GAQ_PATH)
	
	# Actualizar la lista de habitaciones en el Dock ---------------------------
	var new_room_lbl: Label = Label.new()
	new_room_lbl.text = _new_room_name
	_rooms.add_child(new_room_lbl)
	_rooms.move_child(_btn_create_room, _rooms.get_child_count())

	# Abrir la escena creada en el editor --------------------------------------
	ei.open_scene_from_path(_new_room_path + '.tscn')
	ei.select_file(_new_room_path + '.tscn')
#	ei.get_file_system_dock().navigate_to_path(_new_room_path + '.tscn')
	
	# Fin
	_create_room_popup.hide()


func _update_room_path(new_text: String) -> void:
	if _create_room_popup_required.visible:
		_create_room_popup_required.hide()
	
	var casted_name := PoolStringArray()
	for idx in new_text.length():
		if idx == 0:
			casted_name.append(new_text[idx].to_upper())
		else:
			casted_name.append(new_text[idx].to_lower())

	_new_room_name = casted_name.join('')
	_new_room_path = _room_path_template % [_new_room_name, _new_room_name]

	_create_room_popup_scene_path.text = _new_room_path + '.tscn'
	_create_room_popup_script_path.text = _new_room_path + '.gd'


func _clear_room_fields() -> void:
	_create_room_popup_scene_path.text = ''
	_create_room_popup_script_path.text = ''
