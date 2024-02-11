class_name Popochiu
extends Node
## This is Popochiu's main class, and is in charge of making the game to work.
## 
## Is the shortcut for [b]Popochiu.gd[/b], and can be used (from any script) with [b]E[/b] (E.g.
## [code]E.goto_room("House")[/code]).
## 
## Some things you can do with it:
## - Change to another room.
## - Access the main camera and some game settings.
## - Run commands sequentialy (even in a form that makes the skippable).
## - Use some utility methods (such as making a function of yours able to be in a run queue).
## 
## Examples
## [codeblock]
## # Makes the player-controlled character say "Hi", wait a second, and then say another thing
## E.queue([
##     "Player: Hi",
##     "...",
##     "Player: I'm the character you can control!!!",
## ])
## # Make the camera shake with a strength of 2.0 during 3.0 seconds
## E.camera_shake(2.0, 3.0)
## [/codeblock]

## Emitted when the text speed changes in [PopochiuSettings].
signal text_speed_changed
## Emitted when the language changes in [PopochiuSettings].
signal language_changed
## Emitted after [method save_game] saves a file with the current game data.
signal game_saved
## Emitted by [method room_readied] when stored game [param data] is loaded for the current room.
signal game_loaded(data: Dictionary)
## Emitted when [member current_command] changes. Can be used to know the active command for the
## current GUI template.
signal command_selected
## Emitted when the dialog style changes in [PopochiuSettings].
signal dialog_style_changed

## Path to the script with the class used to save and load game data.
const SAVELOAD_PATH := 'res://addons/popochiu/engine/others/popochiu_save_load.gd'

## Used to prevent going to another room when there is one being loaded.
var in_room := false : set = _set_in_room
## Stores a reference to the current [PopochiuRoom].
var current_room: PopochiuRoom
## Stores the last clicked [PopochiuClickable] node to ease access to it from any other class.
var clicked: PopochiuClickable = null
## Stores the last hovered [PopochiuClickable] node to ease access to it from any other class.
var hovered: PopochiuClickable = null : get = get_hovered, set = set_hovered
## Used to know if a cutscene was skipped.
## A reference to [PopochiuSettings]. Can be used to quickly access its members.
var settings := PopochiuResources.get_settings()
## Reference to the [PopochiuAudioManager].
var am: PopochiuAudioManager = null
# NOTE: This might not just be a boolean, but there could be an array that puts
# the calls to queue in an Array and executes them in order. Or perhaps it could
# be something that allows for more dynamism, such as putting one queue to execute
# during the execution of another one.
## Indicates if the game is playing a queue of instructions.
var playing_queue := false
## Reference to the [PopochiuGraphicInterface].
var gi: PopochiuGraphicInterface = null
## Reference to the [PopochiuTransitionLayer].
var tl: Node2D = null
## The current class used as the game commands
var cutscene_skipped := false
## Stores the state of each [PopochiuRoom] in the game. The key of each room is its
## [member PopochiuRoom.script_name], and each value is a [Dictionary] with its properties and the
## data of all its [PopochiuProp]s, [PopochiuHotspot]s, [PopochiuWalkableArea]s, [PopochiuRegion]s,
## and some data related with the [PopochiuCharacter]s in it. For more info about the data stored,
## check the documentation for [PopochiuRoomData].
var rooms_states := {}
## Stores the state of each [PopochiuDialog] in the game. The key of each dialog is its
## [member PopochiuDialog.script_name]. For more info about the stored data, check [PopochiuDialog].
var dialog_states := {}
## Stores a list of game events (triggered actions and dialog lines). Each event is defined by a
## [Dictionary].
var history := []
## The width, in pixels, of the game native resolution
## (that is [code]get_viewport().get_visible_rect().end.x[/code]).
var width := 0.0 : get = get_width
## The height, in pixels, of the game native resolution
## (that is [code]get_viewport().get_visible_rect().end.y[/code]).
var height := 0.0 : get = get_height
## [member width] divided by 2.
var half_width := 0.0 : get = get_half_width
## [member height] divided by 2.
var half_height := 0.0 : get = get_half_height
## Used to access the value of the current text speed. The possible text speed values are stored
## in the [member PopochiuSettings.text_speeds] [Array], so this property has the index of the
## speed being used by the game.
var current_text_speed_idx := settings.default_text_speed
## The text speed being used by the game. When this property changes, the
## [signal text_speed_changed] signal is emitted.
var current_text_speed: float = settings.text_speeds[current_text_speed_idx] :
	set = set_current_text_speed
## The number of seconds to wait before moving to the next dialog line (when playing dialog lines
## triggered inside a [method queue].
var auto_continue_after := -1.0
## The current dialog style used by the game. When this property changes, the
## [signal dialog_style_changed] signal is emitted.
var current_dialog_style := settings.dialog_style : set = set_dialog_style
## The scale value of the game. Defined by the native game resolution compared with (320, 180),
## which is the default game resolution defined by Popochiu.
var scale := Vector2.ONE
## A reference to the current commands script.
## (i.e. [NineVerbCommands], [SierraCommands] or [SimpleClickCommands])
var commands: PopochiuCommands = null
## Serves as a map to access the fallback methods of the current GUI.
var commands_map := {
	-1: {
		"name" = "fallback",
		fallback = _command_fallback
	}
}
## The ID of the current active command in the GUI. When this property changes, the
## [signal command_selected] signal is emitted.
var current_command := -1 : set = set_current_command

var _is_camera_shaking := false
var _camera_shake_amount := 15.0
var _shake_timer := 0.0
var _use_transition_on_room_change := true
var _config: ConfigFile = null
var _loaded_game := {}
var _hovered_queue := []
# Will have the instance of the PopochiuSaveLoad class in order to call the methods that save and
# load the game.
var _saveload: Resource = null

## A reference to the game [Camera2D].
@onready var main_camera: Camera2D = find_child('MainCamera')
@onready var _tween: Tween = null
@onready var _defaults := {
	camera_limits = {
		left = main_camera.limit_left,
		right = get_viewport().get_visible_rect().end.x,
		top = main_camera.limit_top,
		bottom = get_viewport().get_visible_rect().end.y
	}
}


#region Godot ######################################################################################
func _ready() -> void:
	_saveload = load(SAVELOAD_PATH).new()
	_config = PopochiuResources.get_data_cfg()
	
	# Create the AudioManager
	am = load(PopochiuResources.AUDIO_MANAGER).instantiate()
	
	# Set the Graphic Interface node
	if settings.graphic_interface:
		gi = settings.graphic_interface.instantiate()
		gi.name = 'GraphicInterface'
	else:
		gi = load(PopochiuResources.GUI_ADDON_FOLDER).instantiate()
	
	# Load the commands for the game
	var commands_path: String = PopochiuResources.get_data_value("ui", "commands", "")
	if not commands_path.is_empty():
		commands = load(commands_path).new()
	
	# Set the Transitions Layer node
	if settings.transition_layer:
		tl = settings.transition_layer.instantiate()
		tl.name = 'TransitionLayer'
	else:
		tl = load(PopochiuResources.TRANSITION_LAYER_ADDON).instantiate()
	
	# Calculate the scale that could be applied
	scale = Vector2(self.width, self.height) / Vector2(320.0, 180.0)
	
	# Add the AudioManager, the Graphic Interface, and the Transitions Layer to the tree
	$GraphicInterfaceLayer.add_child(gi)
	$TransitionsLayer.add_child(tl)
	add_child(am)
	
	# Load the player-controlled character defined by the dev
	if PopochiuResources.has_data_value('setup', 'pc'):
		var pc_data_path: String = PopochiuResources.get_data_value(
			'characters',
			PopochiuResources.get_data_value('setup', 'pc', ''),
			''
		)

		if pc_data_path:
			var pc_data: PopochiuCharacterData = load(pc_data_path)
			var pc: PopochiuCharacter = load(pc_data.scene).instantiate()

			C.player = pc
			C.characters.append(pc)
			C.set(pc.script_name, pc)
	
	# Load the first PopochiuCharacter in the project as the default PC
	if not C.player:
		# Set the first character on the list to be the default player character
		var characters := PopochiuResources.get_section('characters')

		if not characters.is_empty():
			var pc: PopochiuCharacter = load(
				(load(characters[0]) as PopochiuCharacterData).scene
			).instantiate()

			C.player = pc
			C.characters.append(pc)
			C.set(pc.script_name, pc)
	
	# Add inventory items checked start (ignore animations (3rd parameter))
	for key in settings.items_on_start:
		var ii: PopochiuInventoryItem = I.get_item_instance(key)
		
		if is_instance_valid(ii):
			ii.add(false)
	
	set_process_input(false)
	
	if settings.scale_gui:
		Cursor.scale_cursor(scale)
	
	# Save the default state for the objects in the game
	for room_tres in PopochiuResources.get_section('rooms'):
		var res: PopochiuRoomData = load(room_tres)
		E.rooms_states[res.script_name] = res
		
		res.save_childs_states()
	
	# Connect to singletons signals
	C.character_spoke.connect(_on_character_spoke)
	G.unblocked.connect(_on_graphic_interface_unblocked)
	
	# Assign property values to singletons and other global classes
	G.gui = gi


func _process(delta: float) -> void:
	if _is_camera_shaking:
		_shake_timer -= delta
		main_camera.offset = Vector2.ZERO + Vector2(
			randf_range(-1.0, 1.0) * _camera_shake_amount,
			randf_range(-1.0, 1.0) * _camera_shake_amount
		)
		
		if _shake_timer <= 0.0:
			stop_camera_shake()
	elif (
		not Engine.is_editor_hint() 
		and is_instance_valid(C.camera_owner) 
		and C.camera_owner.is_inside_tree()
	):
		main_camera.position = (
			C.camera_owner.position_stored 
			if C.camera_owner.position_stored 
			else C.camera_owner.position
		)


func _input(event: InputEvent) -> void:
	if event.is_action_released('popochiu-skip'):
		cutscene_skipped = true
		tl.play_transition(
			PopochiuTransitionLayer.PASS_DOWN_IN,
			settings.skip_cutscene_time
		)
		
		await tl.transition_finished


func _unhandled_key_input(event: InputEvent) -> void:
	# TODO: Capture keys for debugging or for triggering game signals that can ease tests
	pass


#endregion

#region Public #####################################################################################
## Creates a delay timer that will last [param time] seconds. This method is intended to be used
## inside a [method queue] of instructions.
func queue_wait(time := 1.0) -> Callable:
	return func (): await wait(time)


## Creates a delay timer that will last [param time] seconds.
func wait(time := 1.0) -> void:
	if cutscene_skipped:
		await get_tree().process_frame
		return
	
	await get_tree().create_timer(time).timeout


# TODO: Stop or break a queue in excecution
#func break_queue() -> void:
#	pass


## Executes an array of [param instructions] one by one. [param show_gi] determines if the
## Graphic Interface will appear once all instructions have ran.
func queue(instructions: Array, show_gi := true) -> void:
	if instructions.is_empty():
		await get_tree().process_frame
		return
	
	if playing_queue:
		await get_tree().process_frame
		await queue(instructions, show_gi)
		return
	
	playing_queue = true
	
	G.block()
	
	for idx in instructions.size():
		var instruction = instructions[idx]
		
		if instruction is Callable:
			await instruction.call()
		elif instruction is String:
			await _eval_string(instruction as String)
	
	if show_gi:
		G.unblock()
	
	if _is_camera_shaking:
		stop_camera_shake()
	
	if instructions.is_empty():
		await get_tree().process_frame
	
	playing_queue = false


## Like [method queue], but [param instructions] can be skipped with the input action:
## [code]popochiu-skip[/code] (see [b]Project Settings... > Input Map[/b]). By default you can skip
## a cutscene with the [kbd]ESC[/kbd] key.
func cutscene(instructions: Array) -> void:
	set_process_input(true)
	await queue(instructions)
	set_process_input(false)
	
	if cutscene_skipped:
		tl.play_transition(
			tl.PASS_DOWN_OUT,
			settings.skip_cutscene_time
		)
		await tl.transition_finished
	
	cutscene_skipped = false


## Loads the room with [param script_name]. [param use_transition] can be used to trigger a [i]fade
## out[/i] animation before loading the room, and a [i]fade in[/i] animation once it is ready.
## If [param store_state] is [code]true[/code] the state of the room will be stored in memory.
## [param ignore_change] is used internally by Popochiu to know if it's the first time the room is
## loaded when starting the game.
func goto_room(
	script_name := '',
	use_transition := true,
	store_state := true,
	ignore_change := false
) -> void:
	if not in_room: return
	
	self.in_room = false
	
	G.block()
	
	_use_transition_on_room_change = use_transition
	if use_transition:
		tl.play_transition(tl.FADE_IN)
		await tl.transition_finished
	
	if is_instance_valid(C.player) and Engine.get_process_frames() > 0:
		C.player.last_room = current_room.script_name
	
	# Store the room state
	if store_state:
		rooms_states[current_room.script_name] = current_room.state
		current_room.state.save_childs_states()
	
	# Remove PopochiuCharacter nodes from the room so they are not deleted
	if Engine.get_process_frames() > 0:
		current_room.exit_room()
	
	# Reset camera config
	# TODO: This could be in the Camera3D's own script... along with shaking
	main_camera.limit_left = _defaults.camera_limits.left
	main_camera.limit_right = _defaults.camera_limits.right
	main_camera.limit_top = _defaults.camera_limits.top
	main_camera.limit_bottom = _defaults.camera_limits.bottom
	
	if ignore_change: return
	
	var rp: String = PopochiuResources.get_data_value('rooms', script_name, null)
	if rp.is_empty():
		printerr('[Popochiu] No PopochiuRoom with name: %s' % script_name)
		return
	
	if Engine.get_process_frames() == 0:
		await get_tree().process_frame
	
	R.clear_instances()
	clear_hovered()
	get_tree().change_scene_to_file(load(rp).scene)


## Called once the loaded [param room] is "ready" ([method Node._ready]).
func room_readied(room: PopochiuRoom) -> void:
	current_room = room
	
	if R.current != room:
		R.current = room
	
	# When running from the Editor the first time, use goto_room
	if Engine.get_process_frames() == 0:
		await get_tree().process_frame

		self.in_room = true
		
		# Calling this will make the camera be set to its default values and will store the state of
		# the main room (the last parameter will prevent Popochiu from changing the scene to the
		# same that is already loaded)
		goto_room(room.script_name, false, true, true)
	
	# Make the camera be ready for the room
	current_room.setup_camera()
	
	# Update the core state
	if _loaded_game:
		C.player = C.get_character(_loaded_game.player.id)
	else:
		current_room.state.visited = true
		current_room.state.visited_times += 1
		current_room.state.visited_first_time =\
		current_room.state.visited_times == 1
	
	# Add the PopochiuCharacter instances to the room
	if (rooms_states[room.script_name]['characters'] as Dictionary).is_empty():
		# Store the initial state of the characters in the room
		current_room.state.save_characters()
	
	current_room.clean_characters()
	
	# Load the state of characters in the room
	for chr_script_name: String in rooms_states[room.script_name]['characters']:
		var chr_dic: Dictionary = rooms_states[room.script_name]['characters'][chr_script_name]
		var chr: PopochiuCharacter = C.get_character(chr_script_name)
		
		if not chr: continue
		
		chr.position = Vector2(chr_dic.x, chr_dic.y)
		chr._looking_dir = chr_dic.facing
		chr.visible = chr_dic.visible
		chr.modulate = chr_dic.modulate
		chr.self_modulate = chr_dic.self_modulate
		chr.light_mask = chr_dic.light_mask
		
		current_room.add_character(chr)
	
	# If the room must have the player character but it is not part of its $Characters node, then
	# add the PopochiuCharacter to the room
	if current_room.has_player and is_instance_valid(C.player):
		if not current_room.has_character(C.player.script_name):
			current_room.add_character(C.player)
			await C.player.idle()
	
	# Load the state of Props, Hotspots, Regions and WalkableAreas
	for type in PopochiuResources.ROOM_CHILDS:
		for script_name in rooms_states[room.script_name][type]:
			var node: Node2D = current_room.callv(
				'get_' + type.trim_suffix('s'),
				[(script_name as String).to_pascal_case()]
			)
			var node_dic: Dictionary =\
			rooms_states[room.script_name][type][script_name]
			
			for property in node_dic:
				if not PopochiuResources.has_property(node, property): continue
				
				node[property] = node_dic[property]
	
	for c in get_tree().get_nodes_in_group('PopochiuClickable'):
		c.room = current_room
	
	current_room._on_room_entered()
	
	if _loaded_game:
		C.player.global_position = Vector2(
			_loaded_game.player.position.x,
			_loaded_game.player.position.y
		)
	
	if _use_transition_on_room_change:
		tl.play_transition(tl.FADE_OUT)
		await tl.transition_finished
		await wait(0.3)
	else:
		await get_tree().process_frame
	
	if not current_room.hide_gi:
		G.unblock()
	
	self.in_room = true
	
	if _loaded_game:
		game_loaded.emit(_loaded_game)
		await G.show_system_text('Game loaded')
		
		_loaded_game = {}
	
	# This enables the room to listen input events
	current_room.is_current = true
	
	current_room._on_room_transition_finished()


## Changes the main camera's offset by [param offset] pixels. This method is intended to be used
## inside a [method queue] of instructions.
func queue_camera_offset(offset := Vector2.ZERO) -> Callable:
	return func (): await camera_offset(offset)


## Changes the main camera's offset by [param offset] pixels. Useful when zooming the camera.
func camera_offset(offset := Vector2.ZERO) -> void:
	main_camera.offset = offset
	
	await get_tree().process_frame


## Makes the camera shake with [param strength] during [param duration] seconds. This method is
## intended to be used inside a [method queue] of instructions.
func queue_camera_shake(strength := 1.0, duration := 1.0) -> Callable:
	return func (): await camera_shake(strength, duration)


## Makes the camera shake with [param strength] during [param duration] seconds.
func camera_shake(strength := 1.0, duration := 1.0) -> void:
	_camera_shake_amount = strength
	_shake_timer = duration
	_is_camera_shaking = true
	
	await get_tree().create_timer(duration).timeout


## Makes the camera shake with [param strength] during [param duration] seconds without blocking
## excecution (that means it runs in the background). This method is intended to be used inside a
## [method queue] of instructions.
func queue_camera_shake_bg(strength := 1.0, duration := 1.0) -> Callable:
	return func (): await camera_shake_bg(strength, duration)


## Makes the camera shake with [param strength] during [param duration] seconds without blocking
## excecution (that means it runs in the background).
func camera_shake_bg(strength := 1.0, duration := 1.0) -> void:
	_camera_shake_amount = strength
	_shake_timer = duration
	_is_camera_shaking = true
	
	await get_tree().process_frame


## Changes the camera zoom. If [param target] is greater than [code]Vector2(1, 1)[/code] the camera
## will [b]zoom out[/b], smaller values will make it [b]zoom in[/b]. The effect will last
## [param duration] seconds. This method is intended to be used inside a [method queue] of
## instructions.
func queue_camera_zoom(target := Vector2.ONE, duration := 1.0) -> Callable:
	return func (): await camera_zoom(target, duration)


## Changes the camera zoom. If [param target] is greater than [code]Vector2(1, 1)[/code] the camera
## will [b]zoom out[/b], smaller values will make it [b]zoom in[/b]. The effect will last
## [param duration] seconds.
func camera_zoom(target := Vector2.ONE, duration := 1.0) -> void:
	if is_instance_valid(_tween) and _tween.is_running():
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(main_camera, 'zoom', target, duration)\
	.from_current().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await _tween.finished


## Returns [param msg] translated to the current language if the game is using translations
## [member PopochiuSettings.use_translations]. Otherwise, the returned [String] will be the same
## as the one received as a parameter.
func get_text(msg: String) -> String:
	return tr(msg) if settings.use_translations else msg


## Gets the instance of the [PopochiuCharacter] identified with [param script_name].
func get_character_instance(script_name: String) -> PopochiuCharacter:
	for rp in PopochiuResources.get_section('characters'):
		var popochiu_character: PopochiuCharacterData = load(rp)
		if popochiu_character.script_name == script_name:
			return load(popochiu_character.scene).instantiate()
	
	printerr("[Popochiu] Character %s doesn't exists" % script_name)
	return null


## Gets the instance of the [PopochiuInventoryItem] identified with [param script_name].
func get_inventory_item_instance(script_name: String) -> PopochiuInventoryItem:
	for rp in PopochiuResources.get_section('inventory_items'):
		var popochiu_inventory_item: PopochiuInventoryItemData = load(rp)
		if popochiu_inventory_item.script_name == script_name:
			return load(popochiu_inventory_item.scene).instantiate()
	
	printerr("[Popochiu] Item %s doesn't exists" % script_name)
	return null


## Gets the instance of the [PopochiuDialog] identified with [param script_name].
func get_dialog(script_name: String) -> PopochiuDialog:
	for rp in PopochiuResources.get_section('dialogs'):
		var tree: PopochiuDialog = load(rp)
		if tree.script_name.to_lower() == script_name.to_lower():
			return tree

	printerr("[Popochiu] Dialog '%s doesn't exists" % script_name)
	return null


## Adds an action, represented by [param data], to the [member history] of actions. 
## The structure that [param data] can have may be in the form:
## [codeblock]# To store the Look At interaction with the prop ToyCar:
## {
##     action = "look_at",
##     target = "ToyCar"
## }[/codeblock]
## or
## [codeblock]# To store a dialog line said by the Popsy character
## {
##     character = "Popsy",
##     text = "Hi. I said this and now it is recorded in the game's log!"
## }[/codeblock]
## [method PopochiuClickable.handle_command] and [method PopochiuInventoryItem.handle_command] store
## interactions with clickables and inventory items.
## [method PopochiuGraphicInterface.on_dialog_line_started] stores dialog lines said by characters.
func add_history(data: Dictionary) -> void:
	history.push_front(data)


## Makes a [param method] in [param node] to be able to be used inside an array of instructions for
## [method queue]. Parameters for [param method] can be passed as an array in [param params].
## By default the queued method will wait for [code]"completed"[/code], but in can wait for a
## specific signal given the [param signal_name].
## Examples:
## [codeblock]
## # queue() will wait until $AnimationPlayer.animation_finished signal is emitted
## E.queue([
##     "Player: Ok. This is a queueable example",
##     E.queueable($AnimationPlayer, "play", ["glottis_appears"], "animation_finished"),
##     'Popsy: Hi Goddiu!',
##     "Player: You're finally here!!!"
## ])
## [/codeblock]
## An example with a custom method:
## [codeblock]
## # queue pauses until _make_glottis_appear.completed signal is emitted
## func _ready() -> void:
## E.queue([
##     "Player: Ok. This is another queueable example",
##     E.queueable(self, '_make_glottis_appear', [], 'completed'),
##     "Popsy: Hi Goddiu!",
##     "Player: So... you're finally here!!!",
## ])
## 
## func _make_glottis_appear() -> void:
##     $AnimationPlayer.play("make_glottis_appear")
##     await $AnimationPlayer.animation_finished
##     Globals.glottis_appeared = true
##     await E.wait(1.0)
## [/codeblock]
## An example with a custom signal
## [codeblock]
## # queue pauses until the "clicked" signal is emitted in the %PopupButton
## # ---- In some prop ----
## func on_click() -> void:
##     E.run([
##         "Player: Ok. This is the last queueable example.",
##         "Player: Promise!",
##         E.queueable(%PopupButton, "_show_button", [], "clicked"),
##         "Popsy: Are we done!?",
##         "Player: Yup",
##     ])
## 
## # ---- In the PopupButton node ----
## signal clicked
## 
## func _show_button() -> void:
##     $BtnPlay.show()
## 
## func _on_BtnPlay_pressed() -> void:
##     await A.mx_mysterious_place.play()
##     clicked.emit()
## [/codeblock]
func queueable(
	node: Object, method: String, params := [], signal_name := ''
) -> Callable:
	return func (): await _queueable(node, method, params, signal_name)


## Checks if the room with [param script_name] exists in the list of rooms of the game.
func room_exists(script_name: String) -> bool:
	for rp in PopochiuResources.get_section('rooms'):
		var room: PopochiuRoomData = load(rp)
		if room.script_name.to_lower() == script_name.to_lower():
			return true
	return false


## Plays the transition [param type] animation in the [TransitionLayer] with a [param duration] in
## seconds. Available type values can be found in [member TransitionLayer.Types]. This method is
## intended to be used inside a [method queue] of instructions.
func queue_play_transition(type: int, duration: float) -> Callable:
	return func (): await play_transition(type, duration)


## Plays the transition [param type] animation in the [TransitionLayer] with a [param duration] in
## seconds. Available type values can be found in [member TransitionLayer.Types].
func play_transition(type: int, duration: float) -> void:
	tl.play_transition(type, duration)
	
	await tl.transition_finished


## Changes the speed of the text in dialog lines looping through the values in
## [member PopochiuSettings.text_speeds].
func change_text_speed() -> void:
	current_text_speed_idx = wrapi(
		current_text_speed_idx + 1,
		0,
		settings.text_speeds.size()
	)
	current_text_speed = settings.text_speeds[current_text_speed_idx]
	
	text_speed_changed.emit()


## Checks if there are any saved game sessions in the game's folder. By default Godot's
## [code]user://[/code] (you can open this folder with [b]Project > Open User Data Folder[/b]).
func has_save() -> bool:
	return !_saveload.get_saves_descriptions().is_empty()


## Counts the number of saved game files in the game's folder. By default Godot's
## [code]user://[/code] (you can open this folder with [b]Project > Open User Data Folder[/b]).
func saves_count() -> int:
	return _saveload.count_saves()


## Gets the names of the saved games (the name given to the slot when the game is saved).
func get_saves_descriptions() -> Dictionary:
	return _saveload.get_saves_descriptions()


## Saves the current game state in a given [param slot] with the name in [param description].
func save_game(slot := 1, description := '') -> void:
	if _saveload.save_game(slot, description):
		game_saved.emit()
		
		await G.show_system_text('Game saved')


## Loads the game in the given [param slot].
func load_game(slot := 1) -> void:
	I.clean_inventory(true)
	
	_loaded_game = _saveload.load_game(slot)
	
	if _loaded_game.is_empty(): return
	
	goto_room(
		_loaded_game.player.room,
		true,
		false # Do not store the state of the current room
	)


## Makes the camera stop shaking.
func stop_camera_shake() -> void:
	_is_camera_shaking = false
	_shake_timer = 0.0
	main_camera.offset = Vector2.ZERO


## Adds the [param node] to the array of hovered PopochiuClickable. If [param prepend] is
## [code]true[/code], then the [param node] will be added at the beginning of the array.
func add_hovered(node: PopochiuClickable, prepend := false) -> void:
	if prepend:
		_hovered_queue.push_front(node)
	else:
		_hovered_queue.append(node)


## Removes a [param node] from the array of hovered PopochiuClickable. Returns [code]true[/code]
## if, after deletion, the array becomes empty.
func remove_hovered(node: PopochiuClickable) -> bool:
	_hovered_queue.erase(node)
	
	if not _hovered_queue.is_empty() and is_instance_valid(_hovered_queue[-1]):
		var clickable: PopochiuClickable = _hovered_queue[-1]
		G.show_hover_text(clickable.description)
		
		if clickable.get("cursor"):
			Cursor.show_cursor(Cursor.get_type_name(clickable.cursor))
		
		return false
	
	return true


## Clears the array of hovered PopochiuClickable.
func clear_hovered() -> void:
	_hovered_queue.clear()
	self.hovered = null


## Registers a GUI command identified by [param id], with name [param command_name] and a
## [param fallback] method to be called when the object receiving the interaction doesn't has an
## implementation for the registered command.
func register_command(id: int, command_name: String, fallback: Callable) -> void:
	commands_map[id] = {
		"name" = command_name,
		"fallback" = fallback
	}


## Registers a GUI command with just its name in [param command_name] and a [param fallback] method
## to be called when the object receiving the interaction doesn't has an implementation for the
## registered command. Returns the [code]id[/code] assigned to the registered command.
func register_command_without_id(command_name: String, fallback: Callable) -> int:
	var id := commands_map.size()
	register_command(id, command_name, fallback)
	
	return id


## Calls the fallback method registered for the current active GUI command. If no fallback method is
## registered, [method _command_fallback] is called.
func command_fallback() -> void:
	var fallback: Callable = commands_map[-1].fallback
	
	if commands_map.has(E.current_command):
		fallback = commands_map[E.current_command].fallback
	
	await fallback.call()


## Returns the name of the GUI command registered with [param command_id].
func get_command_name(command_id: int) -> String:
	var command_name := ""
	
	if commands_map.has(command_id):
		command_name = commands_map[command_id].name
	
	return command_name


## Returns the name of the current active GUI command.
func get_current_command_name() -> String:
	return get_command_name(current_command)


#endregion

#region SetGet #####################################################################################
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
		G.show_hover_text()


func get_hovered() -> PopochiuClickable:
	if not _hovered_queue.is_empty() and is_instance_valid(_hovered_queue[-1]):
		return _hovered_queue[-1]
	
	return null


func set_current_text_speed(value: float) -> void:
	current_text_speed = value
	text_speed_changed.emit()


func set_current_command(value: int) -> void:
	current_command = value
	
	command_selected.emit()


func set_dialog_style(value: int) -> void:
	current_dialog_style = value
	dialog_style_changed.emit()


#endregion

#region Private ####################################################################################
func _eval_string(text: String) -> void:
	match text:
		'.':
			await wait(0.25)
		'..':
			await wait(0.5)
		'...':
			await wait(1.0)
		'....':
			await wait(2.0)
		_:
			var colon_idx: int = text.find(':')
			if colon_idx >= 0:
				var colon_prefix: String = text.substr(0, colon_idx)
				
				var emotion_idx := colon_prefix.find('(')
				var auto_idx := colon_prefix.find('[')
				var name_idx := -1
				
				if emotion_idx > 0:
					if auto_idx < 0 or (auto_idx > 0 and auto_idx > emotion_idx):
						name_idx = emotion_idx
					elif auto_idx > 0:
						name_idx = auto_idx
				elif auto_idx > 0:
					name_idx = auto_idx
				
				var character_name: String = colon_prefix.substr(
					0, name_idx
				)
				
				if not C.is_valid_character(character_name):
					printerr('[Popochiu] No PopochiuCharacter with name: %s'\
					% character_name)
					await get_tree().process_frame
					return
				
				var character := C.get_character(character_name)
				
				if not C.is_valid_character(character_name):
					printerr('[Popochiu] No PopochiuCharacter with name: %s'\
					% character_name)
					
					await get_tree().process_frame
					return
				
				var emotion := ''
				if emotion_idx > 0:
					emotion = colon_prefix.substr(emotion_idx + 1).rstrip(')')
				
				var auto := -1.0
				if auto_idx > 0:
					auto_continue_after = float(
						colon_prefix.substr(auto_idx + 1).rstrip(')')
					)
				
				if not emotion.is_empty():
					character.emotion = emotion
				
				var dialogue := text.substr(colon_idx + 1).trim_prefix(' ')
				
				await character.say(dialogue)
			else:
				await get_tree().process_frame
	
	auto_continue_after = -1.0


func _set_in_room(value: bool) -> void:
	in_room = value
	Cursor.toggle_visibility(in_room)


#func _set_language_idx(value: int) -> void:
#	default_language = value
#	TranslationServer.set_locale(languages[value])
#	language_changed.emit()


func _queueable(node: Object, method: String, params := [], signal_name := '') -> void:
	if cutscene_skipped:
		# TODO: What should happen if the skipped function was an animation that triggers calls
		# during execution? What should happen if the skipped function has to change the state of
		# the game?
		await get_tree().process_frame
		return
	
	var f := Callable(node, method)
	var c = f.callv(params)
	
	if not signal_name.is_empty():
		if signal_name == 'completed':
			await c
		else:
			# TODO: Is there a better way to do this in GDScript 2?
			await node.get(signal_name)
	else:
		await get_tree().process_frame


func _on_character_spoke(chr: PopochiuCharacter, msg := '') -> void:
	add_history({
		character = chr,
		text = msg
	})


func _on_graphic_interface_unblocked() -> void:
	clicked = null
	#current_command = 0


func _command_fallback() -> void:
	PopochiuUtils.print_warning("[color=red]No fallback for that command![/color]")


#endregion
