@tool
extends "res://addons/popochiu/engine/interfaces/i_room.gd"

# classes ----
const PRCasinoInterior := preload('res://popochiu/rooms/casino_interior/room_casino_interior.gd')
# ---- classes

# nodes ----
var CasinoInterior: PRCasinoInterior : get = get_CasinoInterior
# ---- nodes

# functions ----
func get_CasinoInterior() -> PRCasinoInterior: return super.get_runtime_room('CasinoInterior')
# ---- functions
