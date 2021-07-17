class_name GAQRoom
extends Resource

export var id := ''
export(String, FILE, "*.tscn") var path = ''

var visited := false
var visited_first_time := false
var visited_times := 0
