@tool
extends "res://addons/popochiu/engine/interfaces/i_room.gd"

# classes ----
const PRHouse := preload('res://popochiu/rooms/house/room_house.gd')
# ---- classes

# nodes ----
var House: PRHouse : get = get_House
# ---- nodes

# functions ----
func get_House() -> PRHouse: return super.get_runtime_room('House')
# ---- functions

