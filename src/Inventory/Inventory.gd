extends Node

signal item_added(item)
signal item_add_done

var _item_instances := []

var active: Item

export(Array, PackedScene) var inventory_items
export var items := []

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	if not inventory_items.empty():
		for ii in inventory_items:
			var item_instance: Item = ii.instance()
			_item_instances.append({
				script_name = item_instance.script_name,
				node = item_instance
			})


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func add_item(item_name: String) -> void:
	for ii in _item_instances:
		var ii_name: String = ii.script_name
		if ii_name.to_lower() == item_name.to_lower():
			emit_signal('item_added', ii.node)
			yield(self, 'item_add_done')
			break


func add_item_as_active() -> void:
	pass


func set_active(item: Item) -> void:
	active = item
	Cursor.set_item_cursor((item.get_node('Icon') as TextureRect).texture)


#func set_item(item_index, item):
#	var previousItem = items[item_index]
#	items[item_index] = item
#	emit_signal("items_changed", [item_index])
#	return previousItem


func remove_item(item_index):
	var previousItem = items[item_index]
	items[item_index] = null
	emit_signal("items_changed", [item_index])
	return previousItem


#func make_items_unique():
#	var unique_items = []
#	for item in items:
#		if item is Item:
#			unique_items.append(item.duplicate())
#		else:
#			unique_items.append(null)
#	items = unique_items
