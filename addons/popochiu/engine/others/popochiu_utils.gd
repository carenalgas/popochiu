@tool
class_name PopochiuUtils
extends Node
## Utility functions for Popochiu.

## Used for setting the double click delay. Windows default is 500 miliseconds.
static var double_click_delay: float = 0.35 # 0.5 felt like too long of a delay before acting
## Used for tracking if a double click has occured.
static var has_double_click: bool = false


## Used by the GUI to get the position of [param node] in the scene transformed to the space of the
## [CanvasLayer] where it is is rendered.
static func get_screen_coords_for(node: Node) -> Vector2:
	return node.get_viewport().canvas_transform * node.get_global_position()


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
	if (event is InputEventMouseButton and not event.double_click) or (event is InputEventScreenTouch and not event.double_tap):
		await E.wait(double_click_delay) # This delay is need to prevent a single click being detected before double click
		
		if not has_double_click:
			return (event is InputEventMouseButton or event is InputEventScreenTouch)

	return false


## Checks if [param event] is an [InputEventMouseButton] or [InputEventScreenTouch] event and if
## it is pressed.
static func is_click_or_touch_pressed(event: InputEvent) -> bool:
	# Fix #183 by including `event is InputEventScreenTouch` validation
	if not has_double_click:
		return await is_click_or_touch(event) and event.pressed
	else:
		return false


## Returns the index of [param event] when it is an [InputEventMouseButton] or
## [InputEventScreenTouch] event. For a click, [member InputEventMouseButton.button_index] is
## returned. For a touch, [member InputEventScreenTouch.index] is returned. Returns [code]0[/code]
## if the event isn't pressed or is not neither a click or a touch.
static func get_click_or_touch_index(event: InputEvent) -> int:
	var index := 0
	
	if await is_click_or_touch_pressed(event):
		if event is InputEventMouseButton:
			index = event.button_index
		elif event is InputEventScreenTouch:
			index = event.index
	
	return index


## Checks if [param event] is a double click or double tap event.
static func is_double_click_or_tap(event: InputEvent) -> bool:
	if (event is InputEventMouseButton and event.double_click) or (event is InputEventScreenTouch and event.double_tap):
		has_double_click = true
		
		if event is InputEventMouseButton:
			return event.double_click
		elif event is InputEventScreenTouch:
			return event.double_tap
	return false

## Resets the double click status to false by default
static func reset_double_click(double_click: bool = false) -> void:
	await E.wait(double_click_delay) # this delay is needed to prevent single click being detected after double click event
	has_double_click = double_click

