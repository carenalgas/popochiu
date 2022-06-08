extends Node
# (E) Popochiu's core
# It is the system main class, and is in charge of a making the game to work
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

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
export var inventory_limit := 0

var in_run := false
# Used to prevent going to another room when there is one being loaded
var in_room := false setget _set_in_room
var current_room: PopochiuRoom = null
# Stores the las PopochiuClickable node clicked to ease access to it from
# any other class
var clicked: Node
var cutscene_skipped := false
var rooms_states := {}
var history := []
var width := 0.0 setget ,get_width
var height := 0.0 setget ,get_height
var half_width := 0.0 setget ,get_half_width
var half_height := 0.0 setget ,get_half_height

# TODO: This could be in the camera's own script
var _is_camera_shaking := false
var _camera_shake_amount := 15.0
var _shake_timer := 0.0
# TODO: This might not just be a boolean, but there could be an array that puts
# the calls to run in a queue and executes them in order. Or perhaps it could be
# something that allows for more dynamism, such as putting one run to execute
# during the execution of another
var _running := false
var _use_transition_on_room_change := true

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
	# Set the first character on the list to be the default PC (playable character)
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
	if _is_camera_shaking:
		_shake_timer -= delta
		main_camera.offset = Vector2.ZERO + Vector2(
			rand_range(-1.0, 1.0) * _camera_shake_amount,
			rand_range(-1.0, 1.0) * _camera_shake_amount
		)
		
		if _shake_timer <= 0.0:
			_is_camera_shaking = false
			main_camera.offset = Vector2.ZERO
	elif not Engine.editor_hint and is_instance_valid(C.camera_owner):
		main_camera.position = C.camera_owner.position


func _input(event: InputEvent) -> void:
	if event.is_action_released('popochiu-skip'):
		cutscene_skipped = true
		$TransitionLayer.play_transition('pass_down_in', skip_cutscene_time)
		yield($TransitionLayer, 'transition_finished')
		G.emit_signal('continue_clicked')


func _unhandled_key_input(event: InputEventKey) -> void:
	# TODO: Capture keys for debugging or for triggering game signals that can
	# ease tests
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func wait(time := 1.0, is_in_queue := true) -> void:
	if is_in_queue: yield()
	if cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return
	yield(get_tree().create_timer(time), 'timeout')


# TODO: Stop or break a run in excecution
#func break_run() -> void:
#	pass


# Executes a series of instructions one by one. show_gi determines if the
# Graphic Interface will appear once all instructions have ran.
func run(instructions: Array, show_gi := true) -> void:
	if instructions.empty():
		yield(get_tree(), 'idle_frame')
		return
	
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


# Like run, but can be skipped with the input action: popochiu-skip.
func run_cutscene(instructions: Array) -> void:
	set_process_input(true)
	yield(run(instructions), 'completed')
	set_process_input(false)
	
	if cutscene_skipped:
		$TransitionLayer.play_transition(
			$TransitionLayer.PASS_DOWN_OUT, skip_cutscene_time
		)
		yield($TransitionLayer, 'transition_finished')
	
	cutscene_skipped = false


# Loads the room with script_name. use_transition can be used to trigger a fade
# out animation before loading the room, and a fade in animation once it is ready
func goto_room(script_name := '', use_transition := true) -> void:
	if not in_room: return
	self.in_room = false
	
	G.block()
	
	_use_transition_on_room_change = use_transition
	if use_transition:
		$TransitionLayer.play_transition($TransitionLayer.FADE_IN)
		yield($TransitionLayer, 'transition_finished')
	
	C.player.last_room = current_room.script_name
	
	# Store the room state
	rooms_states[current_room.script_name] = current_room.state
	
	# Remove PopochiuCharacter nodes from the room so they are not deleted
	current_room.on_room_exited()
	
	# Reset camera config
	# TODO: This could be in the Camera's own script... along with shaking
	main_camera.limit_left = _defaults.camera_limits.left
	main_camera.limit_right = _defaults.camera_limits.right
	main_camera.limit_top = _defaults.camera_limits.top
	main_camera.limit_bottom = _defaults.camera_limits.bottom
	
	for r in rooms:
		var room = r as PopochiuRoomData
		if room.script_name.to_lower() == script_name.to_lower():
			get_tree().change_scene(room.scene)
			return
	
	prints('[Popochiu] No PopochiuRoom with name: %s' % script_name)


# Called once the loaded room is _ready
func room_readied(room: PopochiuRoom) -> void:
	current_room = room
	
	# Load the room state
	if rooms_states.has(room.script_name):
		room.state = rooms_states[room.script_name]
	
	room.is_current = true
	room.visited = true
	room.visited_first_time = true if room.visited_times == 0 else false
	room.visited_times += 1
	
	# Add the PopochiuCharacter instances to the room
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
		$TransitionLayer.play_transition($TransitionLayer.FADE_OUT)
		yield($TransitionLayer, 'transition_finished')
		yield(wait(0.3, false), 'completed')
	else:
		yield(get_tree(), 'idle_frame')
	
	if not room.hide_gi:
		G.done()
	
	self.in_room = true
	
	# This enables the room to listen input events
	room.on_room_transition_finished()


# Changes the main camera's offset (useful when zooming the camera)
func camera_offset(offset := Vector2.ZERO, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	main_camera.offset = offset
	
	yield(get_tree(), 'idle_frame')


# Makes the camera shake with strength for duration seconds
func camera_shake(\
strength := 1.0, duration := 1.0, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	_camera_shake_amount = strength
	_shake_timer = duration
	_is_camera_shaking = true
	
	yield(get_tree().create_timer(duration), 'timeout')


# Changes the camera zoom. If target is larger than Vector2(1, 1) the camera
# will zoom out, smaller values make it zoom in. The effect will last duration
# seconds
func camera_zoom(\
target := Vector2.ONE, duration := 1.0, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	$Tween.interpolate_property(
		main_camera, 'zoom',
		main_camera.zoom, target,
		duration, Tween.TRANS_SINE, Tween.EASE_OUT
	)
	$Tween.start()
	
	yield($Tween, 'tween_all_completed')


# Returns a String of a text that could be a translation key
func get_text(msg: String) -> String:
	return tr(msg) if use_translations else msg


# Gets the PopochiuCharacter with script_name
func get_character_instance(script_name: String) -> PopochiuCharacter:
	for c in characters:
		var popochiu_character: PopochiuCharacterData = c
		if popochiu_character.script_name == script_name:
			return load(popochiu_character.scene).instance()
	
	prints("[Popochiu] Character %s doesn't exists" % script_name)
	return null


# Gets the PopochiuInventoryItem with script_name
func get_inventory_item_instance(script_name: String) -> PopochiuInventoryItem:
	for ii in inventory_items:
		var popochiu_inventory_item: PopochiuInventoryItemData = ii
		if popochiu_inventory_item.script_name == script_name:
			return load(popochiu_inventory_item.scene).instance()
	
	prints("[Popochiu] Item %s doesn't exists" % script_name)
	return null


# Gets the PopochiuDialog with script_name
func get_dialog(script_name: String) -> PopochiuDialog:
	for dt in dialogs:
		var tree: PopochiuDialog = dt
		if tree.script_name.to_lower() == script_name.to_lower():
			return tree

	prints("[Popochiu] Dialog '%s doesn't exists" % script_name)
	return null


# Adds an action to the history of actions.
# Look PopochiuClickable._unhandled_input or GraphicInterface._show_dialog_text
# for examples
func add_history(data: Dictionary) -> void:
	history.push_front(data)


# Makes a method in node to be able to be used in a run call. Method parameters
# can be passed with params, and yield_signal is the signal that will notify the
# function has been completed (so run can continue with the next command in the queue)
func runnable(
	node: Node, method: String, params := [], yield_signal := ''
) -> void:
	yield()
	
	if cutscene_skipped:
		# TODO: What should happen if the skipped function was an animation that
		# triggers calls during execution? What should happen if the skipped
		# function has to change the state of the game?
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


# Checks if the room with script_name exists in the array of rooms of Popochiu
func room_exists(script_name: String) -> bool:
	for r in rooms:
		var room = r as PopochiuRoomData
		if room.script_name.to_lower() == script_name.to_lower():
			return true
	return false


# Plays the transition type animation in TransitionLayer.tscn that last duration
# in seconds. Possible type values can be found in TransitionLayer
func play_transition(type: int, duration: float, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	$TransitionLayer.play_transition(type, duration)
	
	yield($TransitionLayer, 'transition_finished')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func get_width() -> float:
	return get_viewport().get_visible_rect().end.x


func get_height() -> float:
	return get_viewport().get_visible_rect().end.y


func get_half_width() -> float:
	return get_viewport().get_visible_rect().end.x / 2.0


func get_half_height() -> float:
	return get_viewport().get_visible_rect().end.y / 2.0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
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
				
				C.get_character(char_name).emotion = emotion
				
				if char_name.to_lower() == 'player':
					var char_line := text.substr(char_talk + 1).trim_prefix(' ')

					yield(C.player_say(char_line, false), 'completed')

					G.block()
				if C.is_valid_character(char_name):
					var char_line := text.substr(char_talk + 1).trim_prefix(' ')

					yield(
						C.character_say(char_name, char_line, false),
						'completed'
					)

					G.block()
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
