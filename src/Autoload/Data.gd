extends Node

var player := ''
var clicked: Node

onready var game_width: float = get_viewport().get_visible_rect().end.x
onready var game_height: float = get_viewport().get_visible_rect().end.y
