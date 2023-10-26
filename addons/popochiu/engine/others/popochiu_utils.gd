# Utility functions for Popochiu.
@tool
extends Node
class_name PopochiuUtils

static var ei: EditorInterface = null


static func get_screen_coords_for(node: Node) -> Vector2:
	return node.get_viewport().canvas_transform * node.get_global_position()


# Gets a random element from an Array
static func get_random_array_element(arr: Array):
	randomize()
	var idx := randi() % arr.size()

	return arr[idx]


# Gets a random index from an Array
static func get_random_array_idx(arr: Array) -> int:
	randomize()
	var idx := randi() % arr.size()

	return idx


static func sort_by_file_name(a: String, b: String) -> bool:
	if a.get_file() < b.get_file():
		return true
	return false


static func override_font(node: Control, font_name: String, font: Font) -> void:
	node.add_theme_font_override(font_name, font)


static func select_node(node: Node) -> void:
	ei.get_selection().clear()
	ei.get_selection().add_node(node)


static func print_error(msg: String) -> void:
	print_rich("[bgcolor=c46c71][color=ffffff][b][Popochiu][/b] %s[/color][/bgcolor]" % msg)


static func print_warning(msg: String) -> void:
	print_rich("[bgcolor=edf171][color=4a4a4a][b][Popochiu][/b] %s[/color][/bgcolor]" % msg)
