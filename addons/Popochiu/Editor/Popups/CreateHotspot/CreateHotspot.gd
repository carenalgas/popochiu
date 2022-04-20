tool
extends 'res://addons/Popochiu/Editor/Popups/CreationPopup.gd'
# Permite crear un nuevo Hotspot para una habitación.

const SCRIPT_TEMPLATE := 'res://addons/Popochiu/Engine/Templates/HotspotTemplate.gd'
const HOTSPOT_SCENE := 'res://addons/Popochiu/Engine/Objects/Hotspot/PopochiuHotspot.tscn'
const CURSOR_TYPE := preload('res://addons/Popochiu/Engine/Cursor/Cursor.gd').Type
const Constants := preload('res://addons/Popochiu/Constants.gd')

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
	_hotspot_path_template = _room_dir + '/Hotspots/%s/Hotspot%s'


func create() -> void:
	if not _new_hotspot_name:
		_error_feedback.show()
		return
	
	# TODO: Check if another Hotspot was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	var script_path := _new_hotspot_path + '.gd'
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the Hotspot
	assert(
		_main_dock.dir.make_dir_recursive(_new_hotspot_path.get_base_dir()) == OK,
		'[Popochiu] Could not create Hotspot folder for ' + _new_hotspot_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el script de el hotspot (si tiene interacción)
	var hotspot_template := load(SCRIPT_TEMPLATE)
	if ResourceSaver.save(script_path, hotspot_template) != OK:
		push_error('[Popochiu] Could not create: %s.gd' % _new_hotspot_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el hotspot a agregar a la habitación
	var hotspot: PopochiuHotspot = ResourceLoader.load(HOTSPOT_SCENE).instance()
	hotspot.set_script(ResourceLoader.load(script_path))
	hotspot.name = _new_hotspot_name
	hotspot.script_name = _new_hotspot_name
	hotspot.description = _new_hotspot_name
	hotspot.cursor = CURSOR_TYPE.ACTIVE
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Agregar el hotspot a su habitación
	_room.get_node('Hotspots').add_child(hotspot)
	hotspot.owner = _room
	_main_dock.ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of Hotspots in the Room tab
	room_tab.add_to_list(
		Constants.Types.HOTSPOT,
		_new_hotspot_name,
		script_path
	)
	
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
		_new_hotspot_path = _hotspot_path_template %\
		[_new_hotspot_name, _new_hotspot_name]

		_info.bbcode_text = (
			'In [b]%s[/b] the following file will be created: [code]%s[/code]' \
			% [
				_new_hotspot_path.get_base_dir(),
				'Hotspot' + _new_hotspot_name + '.gd'
			]
		)
	else:
		_info.clear()


func _clear_fields() -> void:
	._clear_fields()
	
	_new_hotspot_name = ''
	_new_hotspot_path = ''
