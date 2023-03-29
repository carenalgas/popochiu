tool
extends Node
class_name PopochiuUtils
# Utility functions for Popochiu
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓


# https://gist.github.com/me2beats/443b40ba79d5b589a96a16c565952419 ❱❱❱❱❱❱❱❱❱❱❱❱
static func snake2camel(string:String) -> String:
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


static func snake2pascal(string:String) -> String:
	# the_name > TheName
	var result = snake2camel(string)
	result[0] = result[0].to_upper()
	return result


static func camel2snake(string:String) -> String:
	# theName > the_name
	var result = PoolStringArray()
	for ch in string:
		if ch == ch.to_lower():
			result.append(ch)
		else:
			result.append('_'+ch.to_lower())

	return result.join('')


static func pascal2snake(string:String) -> String:
	# TheName > the_name
	var result = PoolStringArray()
	for ch in string:
		if ch == ch.to_lower():
			result.append(ch)
		else:
			result.append('_'+ch.to_lower())
	result[0] = result[0][1]
	return result.join('')
# ❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰❰


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


# `source` is one of the `_types` dictionaries in PopochiuDock, TabRoom and
# TabAudio
static func filter_rows(new_text: String, source: Dictionary) -> void:
	for type_dic in source.values():
		type_dic.group.show()
		
		var hidden_rows := 0
		# type_dic.group is a PopochiuGroup
		var rows: Array = type_dic.group.get_elements()
		
		for row in rows:
			row.show()
			
			if new_text.empty(): continue
			
			if (row as Control).name.findn(new_text) < 0:
				hidden_rows += 1
				row.hide()
		
		if hidden_rows == rows.size():
			type_dic.group.hide()
