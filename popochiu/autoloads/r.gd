@tool
extends "res://addons/popochiu/engine/interfaces/i_room.gd"

# classes ----
const PRCasinoInterior := preload('res://popochiu/rooms/casino_interior/room_casino_interior.gd')
const PRHouse := preload('res://popochiu/rooms/house/room_house.gd')
# ---- classes

# nodes ----
var CasinoInterior: PRCasinoInterior : get = get_CasinoInterior
var House: PRHouse : get = get_House
# ---- nodes

# functions ----
func get_CasinoInterior() -> PRCasinoInterior: return super.get_runtime_room('CasinoInterior')
func get_House() -> PRHouse: return super.get_runtime_room('House')
# ---- functions
