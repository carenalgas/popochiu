@tool
class_name PopochiuUtils
extends Node
## Utility functions for Popochiu.

#region Public #####################################################################################
## Used by the GUI to get the position of [param node] in the scene transformed to the space of the
## [CanvasLayer] where it is is rendered.
static func get_screen_coords_for(node: Node, offset: Vector2 = Vector2.ZERO) -> Vector2:
	return node.get_viewport().canvas_transform * (node.get_global_position() + offset)


## Gets a random index from [param array].
static func get_random_array_idx(array: Array) -> int:
	randomize()
	var idx := randi() % array.size()

	return idx


## Compares the name of files [param a] and [param b] to check which one comes first in alphabetical
## order.
static func sort_by_file_name(a: String, b: String) -> bool:
	if a.get_file() < b.get_file():
		return true
	return false


## Overrides the font [param font_name] in [param node] by [param font].
static func override_font(node: Control, font_name: String, font: Font) -> void:
	node.add_theme_font_override(font_name, font)


## Prints [param msg] with Popochiu's error style.
static func print_error(msg: String) -> void:
	print_rich("[bgcolor=c46c71][color=ffffff][b][Popochiu][/b] %s[/color][/bgcolor]" % msg)


## Prints [param msg] with Popochiu's warning style.
static func print_warning(msg: String) -> void:
	print_rich("[bgcolor=edf171][color=000000][b][Popochiu][/b] %s[/color][/bgcolor]" % msg)


## Prints [param msg] with Popochiu's normal style.
static func print_normal(msg: String) -> void:
	print_rich("[bgcolor=75cec8][color=000000][b][Popochiu][/b] %s[/color][/bgcolor]" % msg)


## Checks if [param event] is an [InputEventMouseButton] or [InputEventScreenTouch] event.
static func is_click_or_touch(event: InputEvent) -> bool:
	return (event is InputEventMouseButton or event is InputEventScreenTouch)


## Checks if [param event] is an [InputEventMouseButton] with [member InputEventMouseButton.double_click]
## as [code]true[/code], or an [InputEventScreenTouch] with [member InputEventScreenTouch.double_tap].
## as [code]true[/code].
static func is_double_click_or_double_tap(event: InputEvent) -> bool:
	return (
		(event is InputEventMouseButton and event.double_click)
		or (event is InputEventScreenTouch and not event.double_tap)
	)


## Checks if [param event] is an [InputEventMouseButton] or [InputEventScreenTouch] event and if
## it is pressed.
static func is_click_or_touch_pressed(event: InputEvent) -> bool:
	# Fix #183 by including `event is InputEventScreenTouch` validation
	return is_click_or_touch(event) and event.pressed


## Returns the index of [param event] when it is an [InputEventMouseButton] or
## [InputEventScreenTouch] event. For a click, [member InputEventMouseButton.button_index] is
## returned. For a touch, [member InputEventScreenTouch.index] is returned. Returns [code]0[/code]
## if the event isn't pressed or is not neither a click or a touch.
static func get_click_or_touch_index(event: InputEvent) -> int:
	var index := 0
	
	if is_click_or_touch_pressed(event):
		if event is InputEventMouseButton:
			index = event.button_index
		elif event is InputEventScreenTouch:
			index = event.index
	
	return index


## For each element in [param array] calls [param callback] passing the element as a parameter. If
## any of the calls returns [code]true[/code], then this function returns [code]true[/code],
## otherwise [code]false[/code] is returned.[br][br]
## This is an alternate version for [method Array.any] that doesn't stops execution even when one
## of the results is [code]true[/code].
static func any_exhaustive(array: Array, callback: Callable) -> bool:
	var any_updated := false
	for element in array:
		var updated: bool = callback.call(element)
		if updated:
			any_updated = true
	return any_updated


#endregion
