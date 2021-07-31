extends Node
# (E) El núcleo de Godot Adventure Quest

signal inline_dialog_requested(options)
signal text_speed_changed(idx)
signal language_changed

export(Array, Resource) var rooms = []
export(Array, Resource) var characters = []
export(Array, Resource) var inventory_items = []
export(Array, Resource) var dialog_trees = []
export var skip_cutscene_time := 0.2
export var text_speeds := [0.1, 0.01, 0.0]
export var text_speed_idx := 0 setget _set_text_speed_idx
export var languages := ['es_CO', 'es', 'en']
export(int, 'co', 'es', 'en') var language_idx := 0 setget _set_language_idx
export var use_translations := false

var in_run := false
# Se usa para que no se pueda cambiar de escena si está se ha cargado por completo,
# esto es que ya ha ejecutado la lógica de Room.on_room_transition_finished
var in_room := false setget _set_in_room
var current_room: Room = null
var clicked: Node
var cutscene_skipped := false
var rooms_states := {}

# TODO: Estas podrían no estar aquí sino en un nodo de VFX que tenga la escena
var _is_camera_shaking := false
var _camera_shake_amount := 15.0
var _shake_timer := 0.0
# TODO: Esta podría no ser sólo un boolean, sino que podría haber un arreglo que
# ponga los llamados a run en una cola y los vaya ejecutando en orden. O tal vez
# podría ser algo que permita más dinamismo, como poner a ejecutar un run durante
# la ejecución de otro.
var _running := false
var _use_transition_on_room_change := true

onready var game_width := get_viewport().get_visible_rect().end.x
onready var game_height := get_viewport().get_visible_rect().end.y
onready var half_width := game_width / 2.0
onready var half_height := game_height / 2.0
onready var main_camera: Camera2D = find_node('MainCamera')
onready var _defaults := {
	camera_limits = {
		left = main_camera.limit_left,
		right = main_camera.limit_right,
		top = main_camera.limit_top,
		bottom = main_camera.limit_bottom
	}
}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func _ready() -> void:
	# TODO: Asignar habitaciones, personajes, ítems y árboles de conversación a
	# las respectivas interfaces
	
	# Por defecto se asume que el personaje jugable es el primero en la lista
	# de personajes
	if not characters.empty():
		var pc: Character = load((characters[0] as GAQCharacter).scene).instance()
		C.player = pc
		C.characters.append(pc)
	
	set_process_input(false)


func _process(delta: float) -> void:
	if not Engine.editor_hint and is_instance_valid(C.player):
		main_camera.position = C.player.position


func _input(event: InputEvent) -> void:
	if event.is_action_released('skip'):
		cutscene_skipped = true
		$TransitionLayer.play_transition('pass_down_in', skip_cutscene_time)
		yield($TransitionLayer, 'transition_finished')
		G.emit_signal('continue_clicked')


func _unhandled_key_input(event: InputEventKey) -> void:
	# Aquí se pueden capturar teclas para hacer debug o disparar eventos del
	# juego que faciliten hacer pruebas.
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func wait(time := 1.0, is_in_queue := true) -> void:
	if is_in_queue: yield()
	if cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return
	yield(get_tree().create_timer(time), 'timeout')


# Detiene una cadena de ejecución
func break_run() -> void:
	pass


func run(instructions: Array, show_gi := true) -> void:
	if _running:
		yield(get_tree(), 'idle_frame')
		return run(instructions, show_gi)

	_running = true

	G.block()
	
	for idx in instructions.size():
		var instruction = instructions[idx]

		if instruction is String:
			yield(_eval_string(instruction as String), 'completed')
		elif instruction is Dictionary:
			if instruction.has('dialog'):
				_eval_string(instruction.dialog)
				yield(self.wait(instruction.time, false), 'completed')
				G.emit_signal('continue_clicked')
		elif instruction is GDScriptFunctionState and instruction.is_valid():
			instruction.resume()
			yield(instruction, 'completed')
	
	if not D.active and show_gi:
		G.done()
	
	_running = false


# Es como run, pero salta la secuencia de acciones si se presiona la acción 'skip'.
func run_cutscene(instructions: Array) -> void:
	set_process_input(true)
	yield(run(instructions), 'completed')
	set_process_input(false)
	
	if cutscene_skipped:
		$TransitionLayer.play_transition('pass_down_out', skip_cutscene_time)
		yield($TransitionLayer, 'transition_finished')

	cutscene_skipped = false


# Retorna la opción seleccionada en el diálogo creado en tiempo de ejecución.
# NOTA: El flujo del juego se pausa hasta que el jugador seleccione una opción.
func show_inline_dialog(opts: Array) -> String:
	emit_signal('inline_dialog_requested', opts)
	return yield(D, 'option_selected')


func goto_room(path := '', use_transition := true) -> void:
# warning-ignore:return_value_discarded
	if not in_room: return
	self.in_room = false

	G.block()
	G.blocked = true

	_use_transition_on_room_change = use_transition
	if use_transition:
		$TransitionLayer.play_transition('fade_in')
		yield($TransitionLayer, 'transition_finished')
	
	C.player.last_room = current_room.script_name
	
	# Guardar el estado de la habitación
	rooms_states[current_room.script_name] = current_room.state
	
	# Sacar los personajes de la habitación para que no sean eliminados
	current_room.on_room_exited()
	
	# Tal vez esto podría estar en un script propio de la cámara... lo mismo
	# el shake
	# Reiniciar la configuración de la cámara
	main_camera.limit_left = _defaults.camera_limits.left
	main_camera.limit_right = _defaults.camera_limits.right
	main_camera.limit_top = _defaults.camera_limits.top
	main_camera.limit_bottom = _defaults.camera_limits.bottom
	
	for r in rooms:
		var room = r as GAQRoom
		if room.id.to_lower() == path.to_lower():
			get_tree().change_scene(room.path)
			return
	
	printerr('No se encontró la Room %s' % path)


func room_readied(room: Room) -> void:
	current_room = room
	
	# Cargar el estado de la habitación
	if rooms_states.has(room.script_name):
		room.state = rooms_states[room.script_name]
	
	room.is_current = true
	room.visited = true
	room.visited_first_time = true if room.visited_times == 0 else false
	room.visited_times += 1
	
	# Agregar a la habitación los personajes que tiene configurados
	for c in room.characters:
		var chr: Character = C.get_character(c.script_name)
		if chr:
			chr.position = c.position
#			chr.walk_to_point += chr.position
			room.add_character(chr)
	if room.has_player:
		room.add_character(C.player)
		yield(C.player.idle(false), 'completed')

	room.on_room_entered()

	if _use_transition_on_room_change:
		$TransitionLayer.play_transition('fade_out')
		yield($TransitionLayer, 'transition_finished')
		yield(wait(0.3, false), 'completed')
	else:
		yield(get_tree(), 'idle_frame')

	if not room.hide_gi:
		G.done()

	G.blocked = false
	self.in_room = true

	# Esto también hace que la habitación empiece a escuchar eventos de Input
	room.on_room_transition_finished()


func tween_zoom(target: Vector2, duration := 1.0, is_in_queue := true) -> void:
	if is_in_queue: yield()
	$Tween.interpolate_property(
		main_camera, 'zoom',
		main_camera.zoom, target,
		duration, Tween.TRANS_SINE, Tween.EASE_OUT
	)
	$Tween.start()
	yield($Tween, 'tween_all_completed')


func shake_camera(props := {}) -> void:
	if props.has('strength'):
		_camera_shake_amount = props.strength
	if props.has('duration'):
		_shake_timer = props.duration
	_is_camera_shaking = true


func get_text(msg: String) -> String:
	return tr(msg) if use_translations else msg


func get_character_instance(id: String) -> Character:
	for c in characters:
		var gaq_character: GAQCharacter = c
		if gaq_character.id == id:
			return load(gaq_character.scene).instance()
	return null


func get_inventory_item_instance(id: String) -> InventoryItem:
	for ii in inventory_items:
		var gaq_inventory_item: GAQInventoryItem = ii
		if gaq_inventory_item.id == id:
			return load(gaq_inventory_item.scene).instance()
	return null


func get_dialog_tree(script_name: String) -> DialogTree:
	for dt in dialog_trees:
		var tree: DialogTree = dt
		if tree.script_name.to_lower() == script_name.to_lower():
			return tree

	# Por si no se encuentra el diálogo
	return null


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _eval_string(text: String) -> void:
	match text:
		'..':
			yield(wait(0.5, false), 'completed')
		'...':
			yield(wait(1.0, false), 'completed')
		'....':
			yield(wait(2.0, false), 'completed')
		_:
			var char_talk: int = text.find(':')
			if char_talk:
				var char_name: String = text.substr(0, char_talk)
				if char_name.to_lower() == 'player':
					var char_line: String = text.substr(char_talk + 1).trim_prefix(' ')
					yield(C.player_say(char_line, false), 'completed')
				if C.is_valid_character(char_name):
					var char_line: String = text.substr(char_talk + 1).trim_prefix(' ')
					yield(C.character_say(char_name, char_line, false), 'completed')
				else:
					yield(get_tree(), 'idle_frame')
			else:
				yield(get_tree(), 'idle_frame')


func _set_in_room(value: bool) -> void:
	in_room = value
	Cursor.toggle_visibility(in_room)


func _set_text_speed_idx(value: int) -> void:
	text_speed_idx = value
	emit_signal('text_speed_changed', text_speed_idx)


func _set_language_idx(value: int) -> void:
	language_idx = value
	TranslationServer.set_locale(languages[value])
	emit_signal('language_changed')
