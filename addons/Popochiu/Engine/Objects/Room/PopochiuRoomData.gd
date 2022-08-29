class_name PopochiuRoomData, 'res://addons/Popochiu/icons/room.png'
extends Resource

export var script_name := ''
export(String, FILE, "*.tscn") var scene = ''

export var visited := false
export var visited_first_time := false
export var visited_times := 0
