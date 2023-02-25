@tool
extends "res://addons/Popochiu/Engine/Interfaces/IRoom.gd"

# classes ----
const PRHouse := preload('res://popochiu/Rooms/House/RoomHouse.gd')
# ---- classes

# nodes ----
var House: PRHouse : get = get_House
# ---- nodes

# functions ----
func get_House() -> PRHouse: return super.get_runtime_room('House')
# ---- functions

