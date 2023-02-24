@tool
extends "res://addons/Popochiu/Engine/Interfaces/IRoom.gd"

# classes ----
const PR101 := preload('res://popochiu/Rooms/101/Room101.gd')
const PROutside := preload('res://popochiu/Rooms/Outside/RoomOutside.gd')
const PRMap := preload('res://popochiu/Rooms/Map/RoomMap.gd')
# ---- classes

# nodes ----
var R101: PR101 : get = get_101
var Outside: PROutside : get = get_Outside
var Map: PRMap : get = get_Map
# ---- nodes

# functions ----
func get_101() -> PR101: return super.get_runtime_room('101')
func get_Outside() -> PROutside: return super.get_runtime_room('Outside')
func get_Map() -> PRMap: return super.get_runtime_room('Map')
# ---- functions

