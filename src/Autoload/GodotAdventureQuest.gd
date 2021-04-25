extends Node
# El núcleo de Godot Adventure Quest

signal inline_dialog_requested(options)

var in_run := false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
# Detiene una cadena de ejecución
func break_run() -> void:
	pass


func run(instructions: Array) -> void:
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
	
	if not D.active: G.done()


# Retorna la opción seleccionada en el diálogo creado en tiempo de ejecución.
# NOTA: El flujo del juego se pausa hasta que el jugador seleccione una opción.
func show_inline_dialog(opts: Array) -> String:
	emit_signal('inline_dialog_requested', opts)
	return yield(D, 'option_selected')
