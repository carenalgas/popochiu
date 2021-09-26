tool
extends CreationPopup
# Permite crear un nuevo ítem de inventario con los archivos necesarios para que
# funcione en el Popochiu: InventoryIII.tscn, InventoryIII.gd, InventoryIII.tres.

const INVENTORY_ITEM_SCRIPT_TEMPLATE := \
'res://addons/Popochiu/Engine/Templates/InventoryItemTemplate.gd'
const BASE_INVENTORY_ITEM_PATH := \
'res://addons/Popochiu/Engine/Objects/InventoryItem/PopochiuInventoryItem.tscn'

var _new_item_name := ''
var _new_item_path := ''
var _item_path_template: String


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func set_main_dock(node: PopochiuDock) -> void:
	.set_main_dock(node)
	# Por defecto: res://popochiu/InventoryItems/
	_item_path_template = _main_dock.INVENTORY_ITEMS_PATH + '%s/Inventory%s'


func create() -> void:
	if not _new_item_name:
		_error_feedback.show()
		return
	
	# TODO: Verificar si no hay ya un ítem en el mismo PATH.
	# TODO: Eliminar archivos creados si la creación no se completa.
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el directorio donde se guardará el nuevo ítem
	_main_dock.dir.make_dir(_main_dock.INVENTORY_ITEMS_PATH + _new_item_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el script del nuevo ítem
	var item_template := load(INVENTORY_ITEM_SCRIPT_TEMPLATE)
	if ResourceSaver.save(_new_item_path + '.gd', item_template) != OK:
		push_error('No se pudo crear el script: %s.gd' % _new_item_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear la instancia del nuevo ítem y asignarle el script creado
	var new_item: InventoryItem = preload(BASE_INVENTORY_ITEM_PATH).instance()
	#	Primero se asigna el script para que no se vayan a sobrescribir otras
	#	propiedades por culpa de esa asignación.
	new_item.set_script(load(_new_item_path + '.gd'))
	new_item.script_name = _new_item_name
	new_item.name = 'Inventory' + _new_item_name
	new_item.size_flags_horizontal = new_item.SIZE_EXPAND
	new_item.size_flags_vertical = new_item.SIZE_EXPAND
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el archivo de la escena
	var new_item_packed_scene: PackedScene = PackedScene.new()
	new_item_packed_scene.pack(new_item)
	if ResourceSaver.save(_new_item_path + '.tscn', new_item_packed_scene) != OK:
		push_error('No se pudo crear la escena: %s.tscn' % _new_item_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el Resource del ítem
	var item_resource: PopochiuInventoryItemData = PopochiuInventoryItemData.new()
	item_resource.script_name = _new_item_name
	item_resource.scene = _new_item_path + '.tscn'
	item_resource.resource_name = _new_item_name
	if ResourceSaver.save(_new_item_path + '.tres',\
	item_resource) != OK:
		push_error('No se pudo crear el PopochiuInventoryItemData del ítem: %s' %\
		_new_item_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Agregar el ítem al Popochiu
	if _main_dock.add_resource_to_popochiu(
		'inventory_items', ResourceLoader.load(_new_item_path + '.tres')
	) != OK:
		push_error('No se pudo agregar el objeto de inventario a Popochiu: %s' %\
		_new_item_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Actualizar la lista de habitaciones en el Dock
	_main_dock.add_to_list(_main_dock.Types.INVENTORY_ITEM, _new_item_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir la escena creada en el editor
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.select_file(_new_item_path + '.tscn')
	_main_dock.ei.open_scene_from_path(_new_item_path + '.tscn')
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Fin
	hide()

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _update_name(new_text: String) -> void:
	._update_name(new_text)

	if _name:
		_new_item_name = _name
		_new_item_path = _item_path_template %\
		[_new_item_name, _new_item_name]

		_info.bbcode_text = (
			'En [b]%s[/b] se crearán los archivos:\n[code]%s, %s y %s[/code]' \
			% [
				_main_dock.INVENTORY_ITEMS_PATH + _new_item_name,
				'Inventory' + _new_item_name + '.tscn',
				'Inventory' + _new_item_name + '.gd',
				'Inventory' + _new_item_name + '.tres'
			])
	else:
		_info.clear()


func _clear_fields() -> void:
	._clear_fields()
	
	_new_item_name = ''
	_new_item_path = ''
