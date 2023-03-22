# Utility functions for Popochiu.
@tool
extends Node
class_name PopochiuUtils


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


# https://gist.github.com/me2beats/443b40ba79d5b589a96a16c565952419 ============
# Formats `string` from the_name to theName
static func snake2camel(string:String)->String:
	var result = PackedStringArray()
	var prev_is_underscore = false
	for ch in string:
		if ch=='_':
			prev_is_underscore = true
		else:
			if prev_is_underscore:
				result.append(ch.to_upper())
			else:
				result.append(ch)
			prev_is_underscore = false


	return ''.join(result)


# Formats `string` from the_name to TheName
static func snake2pascal(string:String)->String:
	var result = snake2camel(string)
	result[0] = result[0].to_upper()
	return result


# Formats `string` from theName to the_name
static func camel2snake(string:String)->String:
	var result = PackedStringArray()
	for ch in string:
		if ch == ch.to_lower():
			result.append(ch)
		else:
			result.append('_' + ch.to_lower())

	return ''.join(result)


# Formats `string` from TheName to the_name
static func pascal2snake(string:String)->String:
	var result = PackedStringArray()
	var idx := 0
	for ch in string:
		# FIX: The second condition solves strings that start with a number
		if ch == ch.to_lower() and not (idx == 0 and ch.is_valid_int()):
			result.append(ch)
		else:
			result.append('_' + ch.to_lower())
		idx += 1
	result[0] = result[0][1]
	return ''.join(result)
# ==============================================================================
