# @popochiu-docs-category engine
class_name Popochiu
extends Node
## Popochiu's core engine, responsible for the main game logic and systems.
## It is accessible from any game script as [b]E[/b] (e.g. [code]E.camera.shake()[/code]).
##
## Provides core functionality for the game engine, plus access to some general-purpose feature:
## - Accessing the main camera and game settings.
## - Running sequential (and skippable) instruction queues.
## - Recording game events in a history log.
## - Handling game saves and loads.
## - Registering custom commands for the GUI.
## - Wrapping custom methods so they can be used inside a [method queue].
##
## Use examples:
## [codeblock]
## # Makes the player-controlled character say "Hi", wait a second, and then say another thing
## E.queue([
##     "Player: Hi",
##     "...",
##     "Player: I'm the character you can control!!!",
## ])
## # Shake the camera with a strength of 2.0 for 3.0 seconds
## E.camera.shake(2.0, 3.0)
## [/codeblock]

## Emitted when the text speed changes in [PopochiuSettings].
signal text_speed_changed
## Emitted when the language changes in [PopochiuSettings].
signal language_changed
## Emitted after [method save_game] saves a file with the current game data.
signal game_saved
## Emitted before a loaded game starts the transition to show the loaded data.
signal game_load_started
## Emitted by [method room_readied] when stored game [param data] is loaded for the current room.
signal game_loaded(data: Dictionary)
## Emitted when [member current_command] changes. Can be used to know the active command for the
## current GUI template.
signal command_selected
## Emitted when the dialog style changes in [PopochiuSettings].
signal dialog_style_changed
## Sentinel signal that is never emitted. Awaiting it permanently suspends the current instruction
## chain, allowing new player interactions to take over (e.g. when the player clicks elsewhere while
## a character is walking to a [PopochiuClickable]).
signal await_stopped

## Path to the script with the class used to save and load game data.
const SAVELOAD_PATH := "res://addons/popochiu/engine/others/popochiu_save_load.gd"

# @popochiu-docs-ignore
#
## Prevents room changes while a room is being loaded.
var in_room := false : set = _set_in_room
## Stores the last clicked [PopochiuClickable] for global access.
var clicked: PopochiuClickable = null
## Stores the last hovered [PopochiuClickable] for global access.
var hovered: PopochiuClickable = null : get = get_hovered, set = set_hovered
## A reference to [PopochiuSettings]. Can be used to quickly access its members.
var settings := PopochiuSettings.new()
## Reference to the [PopochiuAudioManager].
var am: PopochiuAudioManager = null
# NOTE: This might not just be a boolean, but there could be an array that puts the calls to queue
# in an Array and executes them in order. Or perhaps it could be something that allows for more
# dynamism, such as putting one queue to execute during the execution of another one.
## Indicates if the game is playing a queue of instructions.
var playing_queue := false
## Reference to the [PopochiuGraphicInterface].
var gui: PopochiuGraphicInterface = null
## Whether the current cutscene was skipped by the player.
var cutscene_skipped := false
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
## The text speed being used by the game. When this property changes, the
## [signal text_speed_changed] signal is emitted.
var text_speed: float = settings.text_speed : set = set_text_speed
## The number of seconds to wait before moving to the next dialog line (when playing dialog lines
## triggered inside a [method queue]).
var auto_continue_after := -1.0
## The current dialog style used by the game. When this property changes, the
## [signal dialog_style_changed] signal is emitted.
var current_dialog_style := settings.dialog_style : set = set_dialog_style
## The scale value of the game. Defined by the native game resolution compared with (356, 200),
## which is the default game resolution defined by Popochiu.
var scale := Vector2.ONE
## Reference to the current GUI commands script
## (e.g. [NineVerbCommands], [SierraCommands], or [SimpleClickCommands]).
var commands: PopochiuCommands = null
## Maps command IDs to their names and fallback methods for the current GUI.
var commands_map := {
	-1: {
		"name" = "fallback",
		fallback = _command_fallback
	}
}
## The ID of the current active command in the GUI. When this property changes, the
## [signal command_selected] signal is emitted.
var current_command := -1 : set = set_current_command
var loaded_game := {}

var _hovered_queue := []
# Will have the instance of the PopochiuSaveLoad class in order to call the methods that save and
# load the game.
var _saveload: Resource = null

## A reference to the [PopochiuMainCamera].
@onready var camera: PopochiuMainCamera = %PopochiuMainCamera


#region Godot ######################################################################################
func _init() -> void:
	Engine.register_singleton(&"E", self)


func _ready() -> void:
	set_process_input(false)
	_saveload = load(SAVELOAD_PATH).new()
	
	# Create the AudioManager
	am = load(PopochiuResources.AUDIO_MANAGER).instantiate()
	
	# Instantiate the Graphic Interface node
	if settings.dev_use_addon_template:
		var template: String = PopochiuResources.get_data_value("ui", "template", "")
		var path := PopochiuResources.GUI_CUSTOM_SCENE
		
		if template != "custom":
			template = template.to_snake_case()
			path = PopochiuResources.GUI_TEMPLATES_FOLDER + "%s/%s_gui.tscn" % [template, template]
		
		gui = load(path).instantiate()
	else:
		gui = load(PopochiuResources.GUI_GAME_SCENE).instantiate()
		gui.name = "GUI"
	
	# Load the commands for the game
	commands = load(PopochiuResources.GUI_COMMANDS).new()
	
	# Instantiate the Transitions Layer node
	PopochiuUtils.t.tl = load(PopochiuResources.TRANSITION_LAYER_SCENE).instantiate()
	
	# Calculate the scale that could be applied
	scale = Vector2(width, height) / PopochiuResources.RETRO_RESOLUTION
	
	# Add the AudioManager, the Graphic Interface, and the Transitions Layer to the tree
	$GraphicInterfaceLayer.add_child(gui)
	$TransitionsLayer.add_child(PopochiuUtils.t.tl)
	add_child(am)
	
	# Load the Player-controlled Character (PC)
	PopochiuCharactersHelper.define_player()
	
	# Add inventory items checked to start with
	await get_tree().process_frame
	
	for key in settings.items_on_start:
		var ii: PopochiuInventoryItem = PopochiuUtils.i.get_item_instance(key)
		
		if is_instance_valid(ii):
			ii.add(false)
	
	if settings.scale_gui:
		PopochiuUtils.cursor.scale_cursor(scale)
	
	PopochiuUtils.r.store_states()
	
	# Connect to autoloads' signals
	PopochiuUtils.c.character_spoke.connect(_on_character_spoke)
	
	# Assign property values to singletons and other global classes
	PopochiuUtils.g.gui = gui


func _input(event: InputEvent) -> void:
	if event.is_action_released("popochiu-skip"):
		cutscene_skipped = true
		PopochiuUtils.t.play_transition(
			settings.tl_cutscene_transition,
			settings.tl_skip_cutscene_time,
			settings.tl_cutscene_transition_mode
			)
		await PopochiuUtils.t.transition_finished


func _unhandled_key_input(event: InputEvent) -> void:
	# TODO: Capture keys for debugging or for triggering game signals that can ease tests
	pass


#endregion

#region Public #####################################################################################
## Creates a delay timer that lasts [param time] seconds.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_wait(time := 1.0) -> Callable:
	return func (): await wait(time)


## Creates a delay timer that will last [param time] seconds.
func wait(time := 1.0) -> void:
	if cutscene_skipped:
		await get_tree().process_frame
		return
	
	await get_tree().create_timer(time).timeout


# TODO: Stop or break a queue in execution
#func break_queue() -> void:
#	pass


## Executes an array of [param instructions] one by one. [param show_gui] determines whether the
## Graphic Interface reappears once all instructions have run.
func queue(instructions: Array, show_gui := true) -> void:
	if instructions.is_empty():
		await get_tree().process_frame
		
		return
	
	if playing_queue:
		await get_tree().process_frame
		await queue(instructions, show_gui)
		
		return
	
	playing_queue = true
	
	PopochiuUtils.g.block()
	
	for idx in instructions.size():
		var instruction = instructions[idx]
		
		if instruction is Callable:
			await instruction.call()
		elif instruction is String:
			await PopochiuCharactersHelper.execute_string(instruction as String)
	
	if show_gui:
		PopochiuUtils.g.unblock()
	
	if camera.is_shaking:
		camera.stop_shake()
	
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
		PopochiuUtils.t.play_transition(
			settings.tl_cutscene_transition,
			settings.tl_skip_cutscene_time,
			settings.tl_cutscene_transition_mode
		)
		await PopochiuUtils.t.transition_finished
	
	cutscene_skipped = false


## Returns [param msg] translated to the current language if
## [member PopochiuSettings.use_translations] is enabled. Otherwise returns [param msg] unchanged.
func get_text(msg: String) -> String:
	return tr(msg) if settings.use_translations else msg


## Adds an action, represented by [param data], to the [member history].
## The [param data] dictionary can have one of these forms:
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


## Wraps a [param method] on [param node] so it can be used inside an array of instructions for
## [method queue]. Arguments for [param method] can be passed as an array in [param params].
## By default the queued method waits for [code]"completed"[/code], but it can wait for a
## different signal specified by [param signal_name].
## Examples:
## [codeblock]
## # queue() will wait until $AnimationPlayer.animation_finished signal is emitted
## E.queue([
##     "Player: Ok. This is a queueable example",
##     E.queueable($AnimationPlayer, "play", ["glottis_appears"], "animation_finished"),
##     "Popsy: Hi Goddiu!",
##     "Player: You're finally here!!!"
## ])
## [/codeblock]
## An example with a custom method:
## [codeblock]
## # queue pauses until _make_glottis_appear.completed signal is emitted
## func _ready() -> void:
## E.queue([
##     "Player: Ok. This is another queueable example",
##     E.queueable(self, "_make_glottis_appear", [], "completed"),
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
##     E.queue([
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
func queueable(node: Object, method: String, params := [], signal_name := "") -> Callable:
	return func (): await _queueable(node, method, params, signal_name)


## @deprecated Available in 2.1 - Will be removed in 2.2.
## Plays the transition [param anim_name] animation in the [TransitionLayer] with a [param duration] in
## seconds with the specified [param mode]. This method is intended to be used inside a [method queue] of
## instructions.
func queue_play_transition(anim_name: String, duration: float, mode: int) -> Callable:
	PopochiuUtils.print_warning(
		"E.queue_play_transition() is deprecated and will be removed in Popochiu 2.2." +
		" Use T.queue_play_transition() instead."
	)
	return func (): await play_transition(anim_name, duration, mode)

## @deprecated Available in 2.1 - Will be removed in 2.2.
## Plays the transition [param anim_name] animation in the [TransitionLayer] with a [param duration] in
## seconds with the specified [param mode].
func play_transition(anim_name: String, duration: float, mode: int) -> void:
	PopochiuUtils.print_warning(
		"E.play_transition() is deprecated and will be removed in Popochiu 2.2." +
		" Use T.play_transition() instead."
	)
	PopochiuUtils.t.play_transition(anim_name, duration, mode)
	
	await PopochiuUtils.t.transition_finished


## Returns [code]true[/code] if any saved game sessions exist in the game's save folder
## ([code]user://[/code] by default — open via [b]Project > Open User Data Folder[/b]).
func has_save() -> bool:
	return !_saveload.get_saves_descriptions().is_empty()


## Returns the number of saved game files in the game's save folder
## ([code]user://[/code] by default — open via [b]Project > Open User Data Folder[/b]).
func saves_count() -> int:
	return _saveload.count_saves()


## Gets the names of the saved games (the name given to the slot when the game is saved).
func get_saves_descriptions() -> Dictionary:
	return _saveload.get_saves_descriptions()


## Saves the current game state in a given [param slot] with the name in [param description].
func save_game(slot := 1, description := "") -> void:
	if _saveload.save_game(slot, description):
		game_saved.emit()


## Loads the game in the given [param slot].
func load_game(slot := 1) -> void:
	PopochiuUtils.i.clean_inventory(true)
	
	if PopochiuUtils.d.current_dialog:
		PopochiuUtils.d.current_dialog.stop()
	
	loaded_game = _saveload.load_game(slot)
	
	if loaded_game.is_empty(): return
	
	game_load_started.emit()
	PopochiuUtils.r.goto_room(
		loaded_game.player.room,
		true,
		false # Do not store the state of the current room
	)

## @deprecated Now this is done by [method PopochiuMainCamera.stop_shake].
func stop_camera_shake() -> void:
	camera.stop_shake()


# @popochiu-docs-ignore
#
## Adds [param node] to the hovered [PopochiuClickable] stack. If [param prepend] is
## [code]true[/code], the node is inserted at the front.
func add_hovered(node: PopochiuClickable, prepend := false) -> void:
	if prepend:
		_hovered_queue.push_front(node)
	else:
		_hovered_queue.append(node)


# @popochiu-docs-ignore
#
## Removes [param node] from the hovered [PopochiuClickable] stack. Returns [code]true[/code]
## if the stack is empty after removal.
func remove_hovered(node: PopochiuClickable) -> bool:
	_hovered_queue.erase(node)
	
	if not _hovered_queue.is_empty() and is_instance_valid(_hovered_queue[-1]):
		var clickable: PopochiuClickable = _hovered_queue[-1]
		PopochiuUtils.g.mouse_entered_clickable.emit(clickable)
		return false
	
	return true


# @popochiu-docs-ignore
#
## Clears the hovered [PopochiuClickable] stack.
func clear_hovered() -> void:
	_hovered_queue.clear()
	self.hovered = null


## Registers a GUI command identified by [param id], with name [param command_name] and a
## [param fallback] method to call when the interacted object has no implementation for the
## registered command.
func register_command(id: int, command_name: String, fallback: Callable) -> void:
	commands_map[id] = {
		"name" = command_name,
		"fallback" = fallback
	}


## Registers a GUI command with just its name in [param command_name] and a [param fallback] method
## to call when the interacted object has no implementation for the registered command. Returns the
## auto-assigned [code]id[/code].
func register_command_without_id(command_name: String, fallback: Callable) -> int:
	var id := commands_map.size()
	register_command(id, command_name, fallback)
	
	return id


## Calls the fallback method registered for the current active GUI command. If no fallback method is
## registered, [method _command_fallback] is called.
func command_fallback() -> void:
	var fallback: Callable = commands_map[-1].fallback
	
	if commands_map.has(current_command):
		fallback = commands_map[current_command].fallback
	
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
		PopochiuUtils.g.show_hover_text()


func get_hovered() -> PopochiuClickable:
	if not _hovered_queue.is_empty() and is_instance_valid(_hovered_queue[-1]):
		return _hovered_queue[-1]
	
	return null


func set_text_speed(value: float) -> void:
	text_speed = value
	text_speed_changed.emit()


func set_current_command(value: int) -> void:
	current_command = value
	command_selected.emit()


func set_dialog_style(value: int) -> void:
	current_dialog_style = value
	dialog_style_changed.emit()


#endregion

#region Private ####################################################################################
func _set_in_room(value: bool) -> void:
	in_room = value
	PopochiuUtils.cursor.toggle_visibility(in_room)


func _queueable(node: Object, method: String, params := [], signal_name := "") -> void:
	if cutscene_skipped:
		# TODO: What should happen if the skipped function was an animation that triggers calls
		# during execution? What should happen if the skipped function has to change the state of
		# the game?
		await get_tree().process_frame
		return
	
	var f := Callable(node, method)
	var c = f.callv(params)
	
	if not signal_name.is_empty():
		if signal_name == "completed":
			await c
		else:
			# TODO: Is there a better way to do this in GDScript 2?
			await node.get(signal_name)
	else:
		await get_tree().process_frame


func _on_character_spoke(chr: PopochiuCharacter, msg := "") -> void:
	add_history({
		character = chr,
		text = msg
	})


func _command_fallback() -> void:
	PopochiuUtils.print_warning("[color=red]No fallback for that command![/color]")


#endregion
