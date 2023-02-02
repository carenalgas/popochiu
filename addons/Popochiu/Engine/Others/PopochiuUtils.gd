tool
extends Node
# Utility functions for Popochiu
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓


func get_screen_coords_for(node: Node) -> Vector2:
	return node.get_viewport().canvas_transform * node.get_global_position()


# Gets a random element from an Array
func get_random_array_element(arr: Array):
	randomize()
	var idx := randi() % arr.size()

	return arr[idx]


# Gets a random index from an Array
func get_random_array_idx(arr: Array) -> int:
	randomize()
	var idx := randi() % arr.size()

	return idx


# https://gist.github.com/me2beats/443b40ba79d5b589a96a16c565952419 ❱❱❱❱❱❱❱❱❱❱❱❱❱❱❱❱
func snake2camel(string:String)->String:
	# the_name > theName
	var result = PoolStringArray()
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


	return result.join('')


func snake2pascal(string:String)->String:
	# the_name > TheName
	var result = snake2camel(string)
	result[0] = result[0].to_upper()
	return result


func camel2snake(string:String)->String:
	# theName > the_name
	var result = PoolStringArray()
	for ch in string:
		if ch == ch.to_lower():
			result.append(ch)
		else:
			result.append('_'+ch.to_lower())

	return result.join('')


func pascal2snake(string:String)->String:
	# TheName > the_name
	var result = PoolStringArray()
	for ch in string:
		if ch == ch.to_lower():
			result.append(ch)
		else:
			result.append('_'+ch.to_lower())
	result[0] = result[0][1]
	return result.join('')
# ❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰
