@tool
class_name PopochiuUtils
extends Node
## Utility functions for Popochiu.


## Used by the graphic interface to get the position of a `node` in the scene
## in the transform space of the CanvasLayer where it is is rendered.
static func get_screen_coords_for(node: Node) -> Vector2:
	return node.get_viewport().canvas_transform * node.get_global_position()


## Gets a random element from an Array.
static func get_random_array_element(arr: Array):
	randomize()
	var idx := randi() % arr.size()

	return arr[idx]


## Gets a random index from an Array.
static func get_random_array_idx(arr: Array) -> int:
	randomize()
	var idx := randi() % arr.size()

	return idx


## Compares the name of two files `a` and `b` to check which one comes first in
## alphabetical order.
static func sort_by_file_name(a: String, b: String) -> bool:
	if a.get_file() < b.get_file():
		return true
	return false


## Overrides the font with `font_name` in a Control `node` with the Font received
## in `font`.
static func override_font(node: Control, font_name: String, font: Font) -> void:
	node.add_theme_font_override(font_name, font)


## Prints the text in `msg` with the error style for Popochiu.
static func print_error(msg: String) -> void:
	print_rich("[bgcolor=c46c71][color=ffffff][b][Popochiu][/b] %s[/color][/bgcolor]" % msg)


## Prints the text in `msg` with the warning style for Popochiu.
static func print_warning(msg: String) -> void:
	print_rich("[bgcolor=edf171][color=000000][b][Popochiu][/b] %s[/color][/bgcolor]" % msg)


static func print_normal(msg: String) -> void:
	print_rich("[bgcolor=75cec8][color=000000][b][Popochiu][/b] %s[/color][/bgcolor]" % msg)
