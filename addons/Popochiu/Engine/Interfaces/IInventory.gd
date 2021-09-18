extends Node
# (I) Para hacer cosas con el inventario

signal item_added(item)
signal item_add_done(item)
signal item_removed(item)
signal item_remove_done(item)

export var always_visible := false

var _item_instances := []

var active: InventoryItem
var show_anims := true

export(Array, PackedScene) var inventory_items
export var items := []


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	if not inventory_items.empty():
		for ii in inventory_items:
			var item_instance: InventoryItem = ii.instance()
			_item_instances.append({
				script_name = item_instance.script_name,
				node = item_instance
			})


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func add_item(item_name: String, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	var i: InventoryItem = _get_item_instance(item_name)
	if is_instance_valid(i) and not i.in_inventory:
		i.in_inventory = true
		
		emit_signal('item_added', i)
		
		return yield(self, 'item_add_done')
	
	yield(get_tree(), 'idle_frame')


func add_item_as_active(item_name: String, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	var item: InventoryItem = yield(add_item(item_name, false), 'completed')
	
	if is_instance_valid(item):
		set_active_item(item)


func set_active_item(item: InventoryItem = null) -> void:
	if item:
		active = item
		Cursor.set_item_cursor((item.get_node('Icon') as TextureRect).texture)
	else:
		active = null
		Cursor.remove_item_cursor()


func remove_item(item_name: String, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	var i: InventoryItem = _get_item_instance(item_name)
	if is_instance_valid(i):
		i.in_inventory = false
		
		set_active_item(null)
		emit_signal('item_removed', i)
		
		yield(self, 'item_remove_done')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _get_item_instance(item_name: String) -> InventoryItem:
	for ii in _item_instances:
		var ii_name: String = ii.script_name
		if ii_name.to_lower() == item_name.to_lower():
			return ii as InventoryItem
	
	# Si el ítem no está en la lista de ítems, entonces hay que intentar
	# instanciarlo en base a la lista de ítems de Popochiu
	var new_intentory_item: InventoryItem = E.get_inventory_item_instance(
		item_name
	)
	if new_intentory_item:
		_item_instances.append(new_intentory_item)
		return new_intentory_item
	
	return null
