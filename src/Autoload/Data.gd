extends Node

var player := ''
var clicked: Node

onready var game_width := get_viewport().get_visible_rect().end.x
onready var game_height := get_viewport().get_visible_rect().end.y
onready var half_width := game_width / 2.0
onready var half_height := game_height / 2.0
