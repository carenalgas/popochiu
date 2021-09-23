tool
extends CreationPopup
# Permite crear un nuevo Hotspot para una habitación.

const SCRIPT_TEMPLATE := 'res://addons/Popochiu/Engine/Templates/HotspotTemplate.gd'
const HOTSPOT_SCENE := 'res://addons/Popochiu/Engine/Objects/Hotspot/Hotspot.tscn'

var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_hotspot_name := ''
var _new_hotspot_path := ''
var _hotspot_path_template: String
var _room_path: String
var _room_dir: String


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func set_main_dock(node: PopochiuDock) -> void:
	.set_main_dock(node)


func room_opened(r: Node2D) -> void:
	_room = r
	_room_path = _room.filename
	_room_dir = _room_path.get_base_dir()
	_hotspot_path_template = _room_dir + '/Hotspots/Hotspot%s'


func create() -> void:
	if not _new_hotspot_name:
		_error_feedback.show()
		return
	
	# TODO: Verificar si no hay ya una hotspot en el mismo PATH.
	# TODO: Eliminar archivos creados si la creación no se completa.
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el directorio donde se guardará el hotspot
	if not _main_dock.dir.dir_exists(_room_dir + '/Hotspots'):
		if _main_dock.dir.make_dir(_room_dir + '/Hotspots') != OK:
			push_error('No se pudo crear el directorio de Hotspots de ' +\
			_room_path.get_file())
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el script de el hotspot (si tiene interacción)
	var hotspot_template := load(SCRIPT_TEMPLATE)
	if ResourceSaver.save(_new_hotspot_path + '.gd', hotspot_template) != OK:
		push_error('No se pudo crear el script: %s.gd' % _new_hotspot_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el hotspot a agregar a la habitación
	var hotspot: Hotspot = ResourceLoader.load(HOTSPOT_SCENE).instance()
	hotspot.set_script(ResourceLoader.load(_new_hotspot_path + '.gd'))
	hotspot.name = _new_hotspot_name
	hotspot.script_name = _new_hotspot_name
	hotspot.description = _new_hotspot_name
	hotspot.cursor = Cursor.Type.ACTIVE
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Agregar el hotspot a su habitación
	_room.get_node('Hotspots').add_child(hotspot)
	hotspot.owner = _room
	_main_dock.ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Actualizar la lista de hotspots de la habitación
	room_tab.add_to_list(room_tab.Types.HOTSPOT, _new_hotspot_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir las propiedades del hotspot creado en el Inspector
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.edit_node(hotspot)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Fin
	hide()

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _update_name(new_text: String) -> void:
	._update_name(new_text)

	if _name:
		_new_hotspot_name = _name
		_new_hotspot_path = _hotspot_path_template % _new_hotspot_name

		_info.bbcode_text = (
			'En [b]%s[/b] se creará el archivo: [code]%s[/code]' \
			% [
				_room_dir + '/Hotspots',
				'Hotspot' + _new_hotspot_name + '.gd'
			]
		)
	else:
		_info.clear()


func _clear_fields() -> void:
	._clear_fields()
	
	_new_hotspot_name = ''
	_new_hotspot_path = ''
