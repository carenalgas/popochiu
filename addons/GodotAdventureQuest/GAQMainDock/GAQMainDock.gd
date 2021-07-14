tool
extends Panel

signal room_created(room_name)

export var rooms_path := 'res://src/Rooms/'

var editor_interface: EditorInterface

var _new_room_name := ''
var _new_room_path := ''
var _dir := Directory.new()

onready var _btn_create_room: Button = find_node('BtnCreateRoom')
onready var _create_room_popup: ConfirmationDialog = find_node('PopupCreateRoom')
onready var _create_room_popup_input: LineEdit = _create_room_popup.find_node('Input')
onready var _create_room_popup_required: Label = _create_room_popup.find_node('Required')
onready var _create_room_popup_path: Label = _create_room_popup.find_node('Path')
onready var _room_path_template := rooms_path + '%s/Room%s'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_create_room_popup.register_text_enter(_create_room_popup_input)

	# Creación de habitaciones
	_btn_create_room.connect('pressed', self, '_show_create_room_popup')
	_create_room_popup.connect('confirmed', self, '_create_room')
	_create_room_popup_input.connect('text_changed', self, '_update_room_path')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _show_create_room_popup() -> void:
	_create_room_popup.popup_centered()


func _create_room() -> void:
	if not _new_room_name:
		_create_room_popup_required.show()
		return
	
	# TODO: Verificar si no hay ya una habitación en el mismo PATH.
	# TODO: Mover esto a otro script para la organización de la vida.
	
	# Crear el directorio donde se guardará la nueva habitación.
	_dir.make_dir(rooms_path + _new_room_name)

	# Crear el script de la nueva habitación.
	var room_template = load("res://script_templates/RoomTemplate.gd")
	var new_room_script = room_template.new()
	
	if ResourceSaver.save(_new_room_path + '.gd', room_template) != OK:
		push_error('No se pudo crear el script de la habitación: %s' % _new_room_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return

	# Crear la instancia de la nueva habitación y asignarle el script creado.
	var new_room: Room = preload('res://src/Nodes/Room/Room.tscn').instance()
	new_room.set_script(load(_new_room_path + '.gd'))
	new_room.script_name = _new_room_name
	
	# Crear el archivo de la escena
	var new_room_packed_scene: PackedScene = PackedScene.new()
	new_room_packed_scene.pack(new_room)

	if ResourceSaver.save(_new_room_path + '.tscn', new_room_packed_scene) != OK:
		push_error('No se pudo crear la habitación: %s' % _new_room_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# TODO: Abrir la escena creada en el editor

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
	_create_room_popup_path.text = _new_room_path
