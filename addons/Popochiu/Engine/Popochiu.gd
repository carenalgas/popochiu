extends Node
# (E) Popochiu's core

signal inline_dialog_requested(options)
signal text_speed_changed(idx)
signal language_changed

export(Array, Resource) var rooms = []
export(Array, Resource) var characters = []
export(Array, Resource) var inventory_items = []
export(Array, Resource) var dialogs = []
export var skip_cutscene_time := 0.2
export var text_speeds := [0.1, 0.01, 0.0]
export var text_speed_idx := 0 setget _set_text_speed_idx
export var text_continue_auto := false
export var languages := ['es_CO', 'es', 'en']
export(int, 'co', 'es', 'en') var language_idx := 0 setget _set_language_idx
export var use_translations := false
export var items_on_start := []

var in_run := false
# Se usa para que no se pueda cambiar de escena si esta se ha cargado por completo,
# esto es que ya ha ejecutado la lógica de PopochiuRoom.on_room_transition_finished
var in_room := false setget _set_in_room
var current_room: PopochiuRoom = null
# Guarda la referencia del Clickable al que se hizo clic para facilitar el acceso
# al mismo desde cualquier nodo.
var clicked: Node
var cutscene_skipped := false
var rooms_states := {}
var history := []

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


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	# Por defecto se asume que el personaje jugable es el primero en la lista
	# de personajes.
	if not characters.empty():
		var pc: PopochiuCharacter = load(
			(characters[0] as PopochiuCharacterData).scene
		).instance()
		C.player = pc
		C.characters.append(pc)
	
	# Add inventory items on start (ignore animations (3rd parameter))
	for key in items_on_start:
		I.add_item(key, false, false)
	
	set_process_input(false)


func _process(delta: float) -> void:
	if not Engine.editor_hint and is_instance_valid(C.player):
		main_camera.position = C.player.position


func _input(event: InputEvent) -> void:
	if event.is_action_released('popochiu-skip'):
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
	
	if instructions.empty():
		yield(get_tree(), 'idle_frame')
	
	_running = false


# Es como run, pero salta la secuencia de acciones si se presiona la acción 'popochiu-skip'.
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


func goto_room(script_name := '', use_transition := true) -> void:
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
		var room = r as PopochiuRoomData
		if room.script_name.to_lower() == script_name.to_lower():
			get_tree().change_scene(room.scene)
			return
	
	printerr('No se encontró la PopochiuRoom %s' % script_name)


func room_readied(room: PopochiuRoom) -> void:
	current_room = room
	
	# Cargar el estado de la habitación
	if rooms_states.has(room.script_name):
		room.state = rooms_states[room.script_name]
	
	room.is_current = true
	room.visited = true
	room.visited_first_time = true if room.visited_times == 0 else false
	room.visited_times += 1
	
	# Agregar a la habitación los personajes que tiene configurados
	for c in room.characters_cfg:
		var chr: PopochiuCharacter = C.get_character(c.script_name)
		
		if chr:
			chr.position = c.position
			room.add_character(chr)
	
	if room.has_player and is_instance_valid(C.player):
		if not room.has_character(C.player.script_name):
			room.add_character(C.player)
		
		yield(C.player.idle(false), 'completed')
	
	for c in get_tree().get_nodes_in_group('PopochiuClickable'):
		c.room = room

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


func get_character_instance(script_name: String) -> PopochiuCharacter:
	for c in characters:
		var popochiu_character: PopochiuCharacterData = c
		if popochiu_character.script_name == script_name:
			return load(popochiu_character.scene).instance()
	
	prints("[Popochiu] Character %s doesn't exists" % script_name)
	return null


func get_inventory_item_instance(script_name: String) -> InventoryItem:
	for ii in inventory_items:
		var popochiu_inventory_item: PopochiuInventoryItemData = ii
		if popochiu_inventory_item.script_name == script_name:
			return load(popochiu_inventory_item.scene).instance()
	
	prints("[Popochiu] Item %s doesn't exists" % script_name)
	return null


func get_dialog(script_name: String) -> PopochiuDialog:
	for dt in dialogs:
		var tree: PopochiuDialog = dt
		if tree.script_name.to_lower() == script_name.to_lower():
			return tree

	prints("[Popochiu] Dialog '%s doesn't exists" % script_name)
	return null


func add_history(data: Dictionary) -> void:
	history.push_front(data)


# Permite que una función cualquiera se ejecute dentro de E.run o E.run_cutscene
func runnable(
	node: Node, method: String, params := [], yield_signal := ''
) -> void:
	yield()
	
	if cutscene_skipped:
		# TODO: Si esto sucede, hay que hacer algo para asegurar que los eventos
		#		dentro de la función omitida se disparen. P. ej. ¿Qué pasa si
		#		se trata de una animación y durante su ejecución se llaman
		#		métodos que cambian cosas en una escena? o ¿qué pasa si una función
		#		hace cambios en el estado del juego?
		yield(get_tree(), 'idle_frame')
		return
	
	var f := funcref(node, method)
	var c = f.call_funcv(params)
	
	if yield_signal:
		if yield_signal == 'func_comp':
			yield(c, 'completed')
		else:
			yield(node, yield_signal)
	else:
		yield(get_tree(), 'idle_frame')


#func add_item_to_start(script_name: String) -> void:
#	_items_on_start.append(script_name)


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
				var char_and_emotion: String = text.substr(0, char_talk)
				var emotion_idx: int = char_and_emotion.find('(')
				var char_name: String = char_and_emotion.substr(\
				0, emotion_idx).to_lower()
				var emotion := ''
				if emotion_idx > 0:
					emotion = char_and_emotion.substr(emotion_idx + 1).rstrip(')')
				
				# TODO: Pasar la emoción al character_say...

				if char_name.to_lower() == 'player':
					var char_line := text.substr(char_talk + 1).trim_prefix(' ')
					yield(C.player_say(char_line, false), 'completed')
				if C.is_valid_character(char_name):
					var char_line := text.substr(char_talk + 1).trim_prefix(' ')
					yield(
						C.character_say(char_name, char_line, false),
						'completed'
					)
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
