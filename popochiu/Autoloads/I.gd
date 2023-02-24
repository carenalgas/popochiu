@tool
extends "res://addons/Popochiu/Engine/Interfaces/IInventory.gd"

# classes ----
const PIIToyCar := preload('res://popochiu/InventoryItems/ToyCar/InventoryToyCar.gd')
# ---- classes

# nodes ----
var ToyCar: PIIToyCar : get = get_ToyCar
# ---- nodes

# functions ----
func get_ToyCar() -> PIIToyCar: return super._get_item_instance('ToyCar')
# ---- functions

