extends Node
# (E) Popochiu's core
# It is the system main class, and is in charge of a making the game to work
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

signal text_speed_changed
signal language_changed
signal game_saved
signal game_loaded(data)
signal redied

const SaveLoad := preload('res://addons/Popochiu/Engine/Others/PopochiuSaveLoad.gd')

var in_run := false
# Used to prevent going to another room when there is one being loaded
var in_room := false setget _set_in_room
var current_room: PopochiuRoom = null setget set_current_room
# Stores the las PopochiuClickable node clicked to ease access to it from
# any other class
var clicked: Node = null
var hovered: PopochiuClickable = null setget set_hovered, get_hovered
var cutscene_skipped := false
var rooms_states := {}
var dialog_states := {}
var history := []
var width := 0.0 setget ,get_width
var height := 0.0 setget ,get_height
var half_width := 0.0 setget ,get_half_width
var half_height := 0.0 setget ,get_half_height
var settings := PopochiuResources.get_settings()
var current_text_speed_idx := settings.default_text_speed
var current_text_speed: float = settings.text_speeds[current_text_speed_idx]
var current_language := 0
var auto_continue_after := -1.0
var scale := Vector2.ONE
var am: PopochiuAudioManager = null

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
var _config: ConfigFile = null
var _loaded_game := {}
var _hovered_queue := []

onready var main_camera: Camera2D = find_node('MainCamera')
onready var _defaults := {
	camera_limits = {
		left = main_camera.limit_left,
		right = E.width,
		top = main_camera.limit_top,
		bottom = E.height
	}
}
onready var _saveload := SaveLoad.new()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	_config = PopochiuResources.get_data_cfg()
	
	am = load(PopochiuResources.AUDIO_MANAGER).instance()
	
	var gi: CanvasLayer = null
	var tl: CanvasLayer = null
	
	if settings.graphic_interface:
		gi = settings.graphic_interface.instance()
		gi.name = 'GraphicInterface'
	else:
		gi = load(PopochiuResources.GRAPHIC_INTERFACE_ADDON).instance()
	
	if settings.transition_layer:
		tl = settings.transition_layer.instance()
		tl.name = 'TransitionLayer'
	else:
		tl = load(PopochiuResources.TRANSITION_LAYER_ADDON).instance()
	
	# Scale GI and TL
	scale = Vector2(E.width, E.height) / Vector2(320.0, 180.0)
	
	add_child(gi)
	add_child(tl)
	add_child(am)
	
	if PopochiuResources.has_data_value('setup', 'pc'):
		var pc_data_path: String = PopochiuResources.get_data_value(
			'characters',
			PopochiuResources.get_data_value('setup', 'pc', ''),
			''
		)
		
		if pc_data_path:
			var pc_data: PopochiuCharacterData = load(pc_data_path)
			var pc: PopochiuCharacter = load(pc_data.scene).instance()
			
			C.player = pc
			C.characters.append(pc)
			C.set(pc.script_name, pc)
	
	if not C.player:
		# Set the first character on the list to be the default player character
		var characters := PopochiuResources.get_section('characters')

		if not characters.empty():
			var pc: PopochiuCharacter = load(
				(load(characters[0]) as PopochiuCharacterData).scene
			).instance()

			C.player = pc
			C.characters.append(pc)
			C.set(pc.script_name, pc)
	
	# Add inventory items on start (ignore animations (3rd parameter))
	for key in settings.items_on_start:
		I.add_item(key, false, false)
	
	set_process_input(false)
	
	if settings.scale_gui:
		Cursor.scale_cursor(scale)
	
	# Save the default state for the objects in the game
	for room_tres in PopochiuResources.get_section('rooms'):
		var res: PopochiuRoomData = load(room_tres)
		E.rooms_states[res.script_name] = res
		res.save_childs_states()
	
	emit_signal('redied')


func _process(delta: float) -> void:
	if _is_camera_shaking:
		_shake_timer -= delta
		main_camera.offset = Vector2.ZERO + Vector2(
			rand_range(-1.0, 1.0) * _camera_shake_amount,
			rand_range(-1.0, 1.0) * _camera_shake_amount
		)
		
		if _shake_timer <= 0.0:
			stop_camera_shake()
	elif not Engine.editor_hint\
	and is_instance_valid(C.camera_owner)\
	and C.camera_owner.is_inside_tree():
		main_camera.position = C.camera_owner.position


func _input(event: InputEvent) -> void:
	if event.is_action_released('popochiu-skip'):
		cutscene_skipped = true
		$TransitionLayer.play_transition(
			TransitionLayer.PASS_DOWN_IN,
			E.settings.skip_cutscene_time
		)
		
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
		elif instruction is GDScriptFunctionState and instruction.is_valid():
			instruction.resume()
			yield(instruction, 'completed')
	
	if show_gi:
		G.done()
	
	if _is_camera_shaking:
		stop_camera_shake()
	
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
			$TransitionLayer.PASS_DOWN_OUT,
			E.settings.skip_cutscene_time
		)
		yield($TransitionLayer, 'transition_finished')
	
	cutscene_skipped = false


# Loads the room with script_name. use_transition can be used to trigger a fade
# out animation before loading the room, and a fade in animation once it is ready
func goto_room(
	script_name := '',
	use_transition := true,
	store_state := true,
	ignore_change := false
) -> void:
	if not in_room: return
	
	G.block()
	
	self.in_room = false
	
	_use_transition_on_room_change = use_transition
	
	if use_transition:
		$TransitionLayer.play_transition($TransitionLayer.FADE_IN)
		yield($TransitionLayer, 'transition_finished')
	
	if is_instance_valid(C.player) and Engine.get_idle_frames() > 0:
		C.player.last_room = current_room.script_name
	
	# Store the room state
	if store_state:
		rooms_states[current_room.script_name] = current_room.state
		current_room.state.save_childs_states()
	
	# Remove PopochiuCharacter nodes from the room so they are not deleted
	if Engine.get_idle_frames() > 0:
		current_room.exit_room()
	
	# Reset camera config
	# TODO: This could be in the Camera's own script... along with shaking
	main_camera.limit_left = _defaults.camera_limits.left
	main_camera.limit_right = _defaults.camera_limits.right
	main_camera.limit_top = _defaults.camera_limits.top
	main_camera.limit_bottom = _defaults.camera_limits.bottom
	
	if ignore_change: return
	
	var rp: String = PopochiuResources.get_data_value('rooms', script_name, null)
	if not rp:
		prints('[Popochiu] No PopochiuRoom with name: %s' % script_name)
		return
	
	if Engine.get_idle_frames() == 0:
		yield(get_tree(), 'idle_frame')
	
	R.clear_instances()
	clear_hovered()
	get_tree().change_scene(load(rp).scene)


# Called once the loaded room is _ready
func room_readied(room: PopochiuRoom) -> void:
	current_room = room
	
	# When running from the Editor the first time, use goto_room
	if Engine.get_idle_frames() == 0:
		yield(get_tree(), 'idle_frame')

		self.in_room = true
		
		# Calling this will make the camera be set to its default values and will
		# store the state of the main room (the last parameter will prevent
		# Popochiu from changing the scene to the same that is already loaded
		goto_room(room.script_name, false, true, true)
	
	# Make the camera be ready for the room
	current_room.setup_camera()
	
	# Update the core state
	if _loaded_game:
		C.player = C.get_character(_loaded_game.player.id)
	else:
		current_room.state.visited = true
		current_room.state.visited_times += 1
		current_room.state.visited_first_time = current_room.state.visited_times == 1
	
	# Add the PopochiuCharacter instances to the room
	for c in current_room.characters_cfg:
		var chr: PopochiuCharacter = C.get_character(c.script_name)
		
		if not chr: continue
		
		chr.position = c.position
		current_room.add_character(chr)
	
	# If the room must have the player character but it is not part of its
	# $Characters node, add it to the room
	if current_room.has_player and is_instance_valid(C.player):
		if not current_room.has_character(C.player.script_name):
			current_room.add_character(C.player)
		
		yield(C.player.idle(false), 'completed')
	
	# Load the state of Props, Hotspots, Regions and WalkableAreas
	for type in PopochiuResources.ROOM_CHILDS:
		for prop_name in rooms_states[room.script_name][type]:
			var prop: Node2D = current_room.callv(
				'get_' + type.trim_suffix('s'),
				[prop_name]
			)
			var prop_dic: Dictionary =\
			rooms_states[room.script_name][type][prop_name]
			
			for property in prop_dic:
				prop[property] = prop_dic[property]
	
	for c in get_tree().get_nodes_in_group('PopochiuClickable'):
		c.room = current_room
	
	current_room.on_room_entered()
	
	if _loaded_game:
		C.player.global_position = Vector2(
			_loaded_game.player.position.x,
			_loaded_game.player.position.y
		)
	
	if _use_transition_on_room_change:
		$TransitionLayer.play_transition($TransitionLayer.FADE_OUT)
		yield($TransitionLayer, 'transition_finished')
		yield(wait(0.3, false), 'completed')
	else:
		yield(get_tree(), 'idle_frame')
	
	if not current_room.hide_gi:
		G.done()
	
	self.in_room = true
	
	if _loaded_game:
		emit_signal('game_loaded', _loaded_game)
		E.run([G.display('Game loaded')])
		
		_loaded_game = {}
	
	# This enables the room to listen input events
	current_room.is_current = true
	
	current_room.on_room_transition_finished()


# Changes the main camera's offset (useful when zooming the camera)
func camera_offset(offset := Vector2.ZERO, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	main_camera.offset = offset
	
	yield(get_tree(), 'idle_frame')


# Makes the camera shake with strength for duration seconds
func camera_shake(
	strength := 1.0, duration := 1.0, is_in_queue := true
) -> void:
	if is_in_queue: yield()
	
	_camera_shake_amount = strength
	_shake_timer = duration
	_is_camera_shaking = true
	
	yield(get_tree().create_timer(duration), 'timeout')


# Makes the camera shake with strength for duration seconds without blocking
# excecution
func camera_shake_no_block(
	strength := 1.0, duration := 1.0, is_in_queue := true
) -> void:
	if is_in_queue: yield()
	
	_camera_shake_amount = strength
	_shake_timer = duration
	_is_camera_shaking = true
	
	yield(get_tree(), 'idle_frame')


# Changes the camera zoom. If target is larger than Vector2(1, 1) the camera
# will zoom out, smaller values make it zoom in. The effect will last duration
# seconds
func camera_zoom(
	target := Vector2.ONE, duration := 1.0, is_in_queue := true
) -> void:
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
	return tr(msg) if E.settings.use_translations else msg


# Gets the PopochiuCharacter with script_name
func get_character_instance(script_name: String) -> PopochiuCharacter:
	for rp in PopochiuResources.get_section('characters'):
		var popochiu_character: PopochiuCharacterData = load(rp)
		if popochiu_character.script_name == script_name:
			return load(popochiu_character.scene).instance()
	
	prints("[Popochiu] Character %s doesn't exists" % script_name)
	return null


# Gets the PopochiuInventoryItem with script_name
func get_inventory_item_instance(script_name: String) -> PopochiuInventoryItem:
	for rp in PopochiuResources.get_section('inventory_items'):
		var popochiu_inventory_item: PopochiuInventoryItemData = load(rp)
		if popochiu_inventory_item.script_name == script_name:
			return load(popochiu_inventory_item.scene).instance()
	
	prints("[Popochiu] Item %s doesn't exists" % script_name)
	return null


# Gets the PopochiuDialog with script_name
func get_dialog(script_name: String) -> PopochiuDialog:
	for rp in PopochiuResources.get_section('dialogs'):
		var tree: PopochiuDialog = load(rp)
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
	node: Object, method: String, params := [], yield_signal := ''
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
#	for r in rooms:
	for rp in PopochiuResources.get_section('rooms'):
		var room: PopochiuRoomData = load(rp)
		if room.script_name.to_lower() == script_name.to_lower():
			return true
	return false


# Plays the transition type animation in TransitionLayer.tscn that last duration
# in seconds. Possible type values can be found in TransitionLayer
func play_transition(type: int, duration: float, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	$TransitionLayer.play_transition(type, duration)
	
	yield($TransitionLayer, 'transition_finished')


func change_text_speed() -> void:
	current_text_speed_idx = wrapi(
		current_text_speed_idx + 1,
		0,
		settings.text_speeds.size()
	)
	current_text_speed = settings.text_speeds[current_text_speed_idx]
	
	emit_signal('text_speed_changed')


func has_save() -> bool:
	return _saveload.count_saves() > 0


func saves_count() -> int:
	return _saveload.count_saves()


func get_saves_descriptions() -> Dictionary:
	return _saveload.get_saves_descriptions()


func save_game(slot := 1, description := '') -> void:
	if _saveload.save_game(slot, description):
		emit_signal('game_saved')
		
		E.run([G.display('Game saved')])


func load_game(slot := 1) -> void:
	I.clean_inventory(true)
	
	_loaded_game = _saveload.load_game(slot)
	
	if not _loaded_game: return
	
	goto_room(
		_loaded_game.player.room,
		true,
		false # Do not store the state of the current room
	)


func stop_camera_shake() -> void:
	_is_camera_shaking = false
	_shake_timer = 0.0
	main_camera.offset = Vector2.ZERO


func add_hovered(node: PopochiuClickable, prepend := false) -> void:
	if prepend:
		_hovered_queue.push_front(node)
	else:
		_hovered_queue.append(node)


func remove_hovered(node: PopochiuClickable) -> bool:
	_hovered_queue.erase(node)
	
	if not _hovered_queue.empty():
		var pc: PopochiuClickable = _hovered_queue[-1]
		G.show_info(pc.description)
		Cursor.set_cursor(pc.cursor)
		return false
	
	return true


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func get_width() -> float:
	return get_viewport().get_visible_rect().end.x


func get_height() -> float:
	return get_viewport().get_visible_rect().end.y


func get_half_width() -> float:
	return get_viewport().get_visible_rect().end.x / 2.0


func get_half_height() -> float:
	return get_viewport().get_visible_rect().end.y / 2.0


func set_hovered(value: PopochiuClickable) -> void:
	hovered = value
	
	if not hovered:
		G.show_info()


func get_hovered() -> PopochiuClickable:
	return null if _hovered_queue.empty() else _hovered_queue[-1]


func clear_hovered() -> void:
	_hovered_queue.clear()
	self.hovered = null


func set_current_room(value: PopochiuRoom) -> void:
	current_room = value
	R.current = value


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _eval_string(text: String) -> void:
	match text:
		'.':
			yield(wait(0.25, false), 'completed')
		'..':
			yield(wait(0.5, false), 'completed')
		'...':
			yield(wait(1.0, false), 'completed')
		'....':
			yield(wait(2.0, false), 'completed')
		_:
			var colon_idx: int = text.find(':')
			if colon_idx:
				var colon_prefix: String = text.substr(0, colon_idx)
				
				var emotion_idx := colon_prefix.find('(')
				var auto_idx := colon_prefix.find('[')
				var name_idx := -1
				
				if emotion_idx > 0:
					name_idx = emotion_idx
					
					if auto_idx > 0 and auto_idx < emotion_idx:
						name_idx = auto_idx
				elif auto_idx > 0:
					name_idx = auto_idx
				
				var character_name: String = colon_prefix.substr(
					0, name_idx
				).to_lower()
				
				if not C.is_valid_character(character_name):
					printerr('[Popochiu] No PopochiuCharacter with name: %s'\
					% character_name)
					return yield(get_tree(), 'idle_frame')
				
				var emotion := ''
				if emotion_idx > 0:
					emotion = colon_prefix.substr(emotion_idx + 1).rstrip(')')
				
				var auto := -1.0
				if auto_idx > 0:
					auto_continue_after = float(
						colon_prefix.substr(auto_idx + 1).rstrip(')')
					)
				
				C.get_character(character_name).emotion = emotion
				
				var dialogue := text.substr(colon_idx + 1).trim_prefix(' ')
				
				if character_name == 'player'\
				or C.player.script_name.to_lower() == character_name:
					yield(C.player_say_no_block(dialogue, false), 'completed')
				elif C.is_valid_character(character_name):
					yield(
						C.character_say_no_block(character_name, dialogue, false),
						'completed'
					)
				else:
					yield(get_tree(), 'idle_frame')
			else:
				yield(get_tree(), 'idle_frame')
	
	auto_continue_after = -1.0


func _set_in_room(value: bool) -> void:
	in_room = value
	Cursor.toggle_visibility(in_room)


#func _set_language_idx(value: int) -> void:
#	default_language = value
#	TranslationServer.set_locale(languages[value])
#	emit_signal('language_changed')
