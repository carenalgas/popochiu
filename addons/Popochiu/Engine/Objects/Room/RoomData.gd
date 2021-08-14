class_name PopochiuRoomData, 'res://addons/Popochiu/icons/room.png'
extends Resource

export var script_name := ''
export(String, FILE, "*.tscn") var scene = ''

var visited := false
var visited_first_time := false
var visited_times := 0
