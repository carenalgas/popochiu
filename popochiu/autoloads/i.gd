@tool
extends "res://addons/popochiu/engine/interfaces/i_inventory.gd"

# classes ----
const PIIToyCar := preload('res://popochiu/inventory_items/toy_car/item_toy_car.gd')
# ---- classes

# nodes ----
var ToyCar: PIIToyCar : get = get_ToyCar
# ---- nodes

# functions ----
func get_ToyCar() -> PIIToyCar: return super._get_item_instance('ToyCar')
# ---- functions

