tool
extends CreationPopup
# Permite crear una nueva Region para una habitación.

const SCRIPT_TEMPLATE := 'res://addons/Popochiu/Engine/Templates/RegionTemplate.gd'
const REGION_SCENE := 'res://addons/Popochiu/Engine/Objects/Region/Region.tscn'

var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_region_name := ''
var _new_region_path := ''
var _region_path_template: String
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
	_region_path_template = _room_dir + '/Regions/Region%s'


func create() -> void:
	if not _new_region_name:
		_error_feedback.show()
		return
	
	# TODO: Verificar si no hay ya una Region en el mismo PATH.
	# TODO: Eliminar archivos creados si la creación no se completa.
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el directorio donde se guardará la región
	if not _main_dock.dir.dir_exists(_room_dir + '/Regions'):
		if _main_dock.dir.make_dir(_room_dir + '/Regions') != OK:
			push_error('No se pudo crear el directorio de Regions de ' +\
			_room_path.get_file())
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el script de la región
	var region_template := load(SCRIPT_TEMPLATE)
	if ResourceSaver.save(_new_region_path + '.gd', region_template) != OK:
		push_error('No se pudo crear el script: %s.gd' % _new_region_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear la región a agregar a la habitación
	var region: Region = ResourceLoader.load(REGION_SCENE).instance()
	region.set_script(ResourceLoader.load(_new_region_path + '.gd'))
	region.name = _new_region_name
	region.script_name = _new_region_name
	region.description = _new_region_name
	
	var collision_shape: CollisionPolygon2D = CollisionPolygon2D.new()
	region.add_child(collision_shape)
	collision_shape.owner = region
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Agregar la región a su habitación
	_room.get_node('Regions').add_child(region)
	region.owner = _room
	_main_dock.ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Actualizar la lista de regiones de la habitación
	room_tab.add_to_list(room_tab.Types.REGION, _new_region_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir las propiedades de la región creada en el Inspector
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.edit_node(region)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Fin
	hide()

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _update_name(new_text: String) -> void:
	._update_name(new_text)

	if _name:
		_new_region_name = _name
		_new_region_path = _region_path_template % _new_region_name

		_info.bbcode_text = (
			'En [b]%s[/b] se creará el archivo: [code]%s[/code]' \
			% [
				_room_dir + '/Regions',
				'Region' + _new_region_name + '.gd'
			]
		)
	else:
		_info.clear()


func _clear_fields() -> void:
	._clear_fields()
	
	_new_region_name = ''
	_new_region_path = ''
