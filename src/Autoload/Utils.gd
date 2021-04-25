# Script en el que se pueden guardar funciones de uso transversal entre todos
# los nodos y scripts del proyecto
extends Node

func get_screen_coords_for(node: Node) -> Vector2:
	return node.get_viewport().canvas_transform * node.get_global_position()


static func run(instructions: Array) -> void:
	var idx := 0
	for instruction in instructions:
		if instruction is String:
			var i: String = instruction
			var char_talk: int = i.find(':')
			if char_talk:
				var char_name: String = i.substr(0, char_talk)
				if not C.is_valid_character(char_name): continue
				var char_line: String = i.substr(char_talk + 1)
				yield(C.character_say(char_name, char_line), 'completed')
		elif instruction is GDScriptFunctionState and instruction.is_valid():
			instruction.resume()
			yield(instruction, 'completed')
	G.done()
