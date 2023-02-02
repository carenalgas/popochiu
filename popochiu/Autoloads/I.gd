extends "res://addons/Popochiu/Engine/Interfaces/IInventory.gd"

# classes ----
const PIIToyCar := preload('res://popochiu/InventoryItems/ToyCar/InventoryToyCar.gd')
const PIIKey := preload('res://popochiu/InventoryItems/Key/InventoryKey.gd')
# ---- classes

# nodes ----
var ToyCar: PIIToyCar setget , get_ToyCar
var Key: PIIKey setget , get_Key
# ---- nodes

# functions ----
func get_ToyCar(): return ._get_item_instance('ToyCar')
func get_Key(): return ._get_item_instance('Key')
# ---- functions

