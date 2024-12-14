@tool
class_name PopochiuUtils
extends Node
## Utility functions for Popochiu.

static var e: Popochiu = null:
	get = get_popochiu
static var r: PopochiuIRoom = null:
	get = get_iroom
static var c: PopochiuICharacter = null:
	get = get_icharacter
static var i: PopochiuIInventory = null:
	get = get_iinventory
static var d: PopochiuIDialog = null:
	get = get_idialog
static var a: PopochiuIAudio = null:
	get = get_iaudio
static var g: PopochiuIGraphicInterface = null:
	get = get_igraphic_interface
static var cursor: PopochiuCursor = null:
	get = get_popochiu_cursor
static var globals: Node = null:
	get = get_popochiu_globals


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


## Returns a [Vector2] with the values of [param source]. If it is a [String], it will be unpacked
## using a regular expression. If it is a [Dictionary], it's [code]x[/code] and [code]y[/code] keys
## will be used. If it is a [Vector2], it will be returned as is. Otherwise [constant Vector2.ZERO]
## is returned.
static func unpack_vector_2(source) -> Vector2:
	if source is Dictionary:
		return Vector2(source.x, source.y)
	elif source is String:
		var regex = RegEx.new()
		regex.compile(r'(Vector2\(|\()\s*(?<x>-?\d+)\s*,\s*(?<y>-?\d+)\s*\)')
		var result := regex.search(source)
		if result:
			return Vector2(float(result.get_string("x")), float(result.get_string("y")))
	elif source is Vector2:
		return source
	return Vector2.ZERO


#endregion

#region SetGet #####################################################################################
static func get_popochiu() -> Popochiu:
	if not is_instance_valid(e):
		if Engine.get_singleton(&"E"):
			e = Engine.get_singleton(&"E")
		else:
			e = Popochiu.new()
	return e


static func get_iroom() -> PopochiuIRoom:
	if not is_instance_valid(r):
		if Engine.get_singleton(&"R"):
			r = Engine.get_singleton(&"R")
		else:
			r = PopochiuIRoom.new()
	return r


static func get_icharacter() -> PopochiuICharacter:
	if not is_instance_valid(c):
		if Engine.get_singleton(&"C"):
			c = Engine.get_singleton(&"C")
		else:
			c = PopochiuICharacter.new()
	return c


static func get_iinventory() -> PopochiuIInventory:
	if not is_instance_valid(i):
		if Engine.get_singleton(&"I"):
			i = Engine.get_singleton(&"I")
		else:
			i = PopochiuIInventory.new()
	return i


static func get_idialog() -> PopochiuIDialog:
	if not is_instance_valid(d):
		if Engine.get_singleton(&"D"):
			d = Engine.get_singleton(&"D")
		else:
			d = PopochiuIDialog.new()
	return d


static func get_iaudio() -> PopochiuIAudio:
	if not is_instance_valid(a):
		if Engine.get_singleton(&"A"):
			a = Engine.get_singleton(&"A")
		else:
			a = PopochiuIAudio.new()
	return a


static func get_igraphic_interface() -> PopochiuIGraphicInterface:
	if not is_instance_valid(g):
		if Engine.get_singleton(&"G"):
			g = Engine.get_singleton(&"G")
		else:
			g = PopochiuIGraphicInterface.new()
	return g


static func get_popochiu_cursor() -> PopochiuCursor:
	if not is_instance_valid(cursor):
		if Engine.get_singleton(&"Cursor"):
			cursor = Engine.get_singleton(&"Cursor")
		else:
			cursor = PopochiuCursor.new()
	return cursor


static func get_popochiu_globals() -> Node:
	if not is_instance_valid(globals):
		globals = e.get_node("/root/Globals")
	return globals


#endregion
