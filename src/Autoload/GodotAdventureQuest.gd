extends Node
# (E) El núcleo de Godot Adventure Quest

signal inline_dialog_requested(options)

export(Array, String, FILE, "*.tscn") var  rooms = []
export(Array, String, FILE, "*.tscn") var  characters = []
export(Array, String, FILE, "*.tscn") var inventory_items = []
export(Array, Resource) var dialog_trees = []

var in_run := false

onready var _main_camera: Camera2D = find_node('MainCamera')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func _ready() -> void:
	# TODO: Asignar habitaciones, personajes, ítems y árboles de conversación a
	# las respectivas interfaces
	pass


func _process(delta: float) -> void:
	if C.player:
		_main_camera.position = C.player.position


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func wait(time := 1.0, is_in_queue := true) -> void:
	if is_in_queue: yield()
	yield(get_tree().create_timer(time), 'timeout')


# Detiene una cadena de ejecución
func break_run() -> void:
	pass


func run(instructions: Array) -> void:
	G.block()
	
	for instruction in instructions:
		if instruction is String:
			var i: String = instruction
			
			# TODO: Mover esto a una función que se encargue de evaluar cadenas
			# de texto
			if i == '...':
				yield(wait(1.0, false), 'completed')
			else:
				var char_talk: int = i.find(':')
				if char_talk:
					var char_name: String = i.substr(0, char_talk)
					if not C.is_valid_character(char_name): continue
					var char_line: String = i.substr(char_talk + 1)
					yield(C.character_say(char_name, char_line, false), 'completed')
		elif instruction is GDScriptFunctionState and instruction.is_valid():
			instruction.resume()
			yield(instruction, 'completed')
	
	if not D.active: G.done()


# Retorna la opción seleccionada en el diálogo creado en tiempo de ejecución.
# NOTA: El flujo del juego se pausa hasta que el jugador seleccione una opción.
func show_inline_dialog(opts: Array) -> String:
	emit_signal('inline_dialog_requested', opts)
	return yield(D, 'option_selected')


func goto_room(path := ''):
# warning-ignore:return_value_discarded
	G.block()

	$TransitionLayer.play_transition('fade_in')
	yield($TransitionLayer, 'transition_finished')

	match path.to_lower():
		'', 'main':
			get_tree().change_scene('res://src/Rooms/Main/Main.tscn')
		'forest':
			get_tree().change_scene('res://src/Rooms/Forest/Forest.tscn')
		_:
# warning-ignore:return_value_discarded
			get_tree().change_scene(path)


func room_readied(room: Room) -> void:
	G.done()
	room.on_room_entered()

	$TransitionLayer.play_transition('fade_out')
	yield($TransitionLayer, 'transition_finished')
	yield(wait(0.3, false), 'completed')

	room.on_room_transition_finished()
