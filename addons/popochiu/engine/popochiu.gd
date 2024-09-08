class_name Popochiu
extends Node
## This is Popochiu's main hub, and is in charge of making the game to work.
## 
## Is the shortcut for [b]Popochiu.gd[/b], and can be used (from any script) with [b]E[/b] (E.g.
## [code]E.camera.shake()[/code]).
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
## A signal that is never emitted and serves to stop the execution of instructions by clicking
## anywhere in a [PopochiuRoom] when a [PopochiuClickable] has already been clicked.
signal await_stopped

## Path to the script with the class used to save and load game data.
const SAVELOAD_PATH := "res://addons/popochiu/engine/others/popochiu_save_load.gd"

## Used to prevent going to another room when there is one being loaded.
var in_room := false : set = _set_in_room
## @deprecated
## [b]Deprecated[/b]. Now this is [member PopochiuIRoom.current].
var current_room: PopochiuRoom
## Stores the last clicked [PopochiuClickable] node to ease access to it from any other class.
var clicked: PopochiuClickable = null
## Stores the last hovered [PopochiuClickable] node to ease access to it from any other class.
var hovered: PopochiuClickable = null : get = get_hovered, set = set_hovered
## Used to know if a cutscene was skipped.
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
## Reference to the [PopochiuTransitionLayer].
var tl: Node2D = null
## The current class used as the game commands
var cutscene_skipped := false
## @deprecated
## [b]Deprecated[/b]. Now this is [member PopochiuIRoom.rooms_states].
var rooms_states := {}
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
var loaded_game := {}

var _hovered_queue := []
# Will have the instance of the PopochiuSaveLoad class in order to call the methods that save and
# load the game.
var _saveload: Resource = null

## A reference to the [PopochiuMainCamera].
@onready var camera: PopochiuMainCamera = %PopochiuMainCamera


#region Godot ######################################################################################
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
	tl = load(PopochiuResources.TRANSITION_LAYER_ADDON).instantiate()
	
	# Calculate the scale that could be applied
	scale = Vector2(width, height) / PopochiuResources.RETRO_RESOLUTION
	
	# Add the AudioManager, the Graphic Interface, and the Transitions Layer to the tree
	$GraphicInterfaceLayer.add_child(gui)
	$TransitionsLayer.add_child(tl)
	add_child(am)
	
	# Load the Player-controlled Character (PC)
	PopochiuCharactersHelper.define_player()
	
	# Add inventory items checked to start with
	await get_tree().process_frame
	
	for key in settings.items_on_start:
		var ii: PopochiuInventoryItem = I.get_item_instance(key)
		
		if is_instance_valid(ii):
			ii.add(false)
	
	if settings.scale_gui:
		Cursor.scale_cursor(scale)
	
	R.store_states()
	
	# Connect to autoloads' signals
	C.character_spoke.connect(_on_character_spoke)
	
	# Assign property values to singletons and other global classes
	G.gui = gui


func _input(event: InputEvent) -> void:
	if event.is_action_released("popochiu-skip"):
		cutscene_skipped = true
		tl.play_transition(PopochiuTransitionLayer.PASS_DOWN_IN, settings.skip_cutscene_time)
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


## Executes an array of [param instructions] one by one. [param show_gui] determines if the
## Graphic Interface will appear once all instructions have ran.
func queue(instructions: Array, show_gui := true) -> void:
	if instructions.is_empty():
		await get_tree().process_frame
		
		return
	
	if playing_queue:
		await get_tree().process_frame
		await queue(instructions, show_gui)
		
		return
	
	playing_queue = true
	
	G.block()
	
	for idx in instructions.size():
		var instruction = instructions[idx]
		
		if instruction is Callable:
			await instruction.call()
		elif instruction is String:
			await PopochiuCharactersHelper.execute_string(instruction as String)
	
	if show_gui:
		G.unblock()
	
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
		tl.play_transition(tl.PASS_DOWN_OUT, settings.skip_cutscene_time)
		await tl.transition_finished
	
	cutscene_skipped = false


## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuIRoom.goto_room].
func goto_room(
	script_name := "", use_transition := true, store_state := true, ignore_change := false
) -> void:
	R.goto_room(script_name, use_transition, store_state, ignore_change)


## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuIRoom.room_readied].
func room_readied(room: PopochiuRoom) -> void:
	R.room_readied(room)


## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuMainCamera.queue_change_offset].
func queue_camera_offset(offset := Vector2.ZERO) -> Callable:
	return camera.queue_change_offset(offset)


## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuMainCamera.change_offset].
func camera_offset(offset := Vector2.ZERO) -> void:
	camera.change_offset(offset)


## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuMainCamera.queue_shake].
func queue_camera_shake(strength := 1.0, duration := 1.0) -> Callable:
	return camera.queue_shake(strength, duration)


## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuMainCamera.shake].
func camera_shake(strength := 1.0, duration := 1.0) -> void:
	camera.shake(strength, duration)


## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuMainCamera.queue_shake_bg].
func queue_camera_shake_bg(strength := 1.0, duration := 1.0) -> Callable:
	return camera.queue_shake_bg(strength, duration)


## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuMainCamera.shake_bg].
func camera_shake_bg(strength := 1.0, duration := 1.0) -> void:
	camera.shake_bg(strength, duration)


## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuMainCamera.queue_change_zoom].
func queue_camera_zoom(target := Vector2.ONE, duration := 1.0) -> Callable:
	return camera.queue_change_zoom(target, duration)


## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuMainCamera.change_zoom].
func camera_zoom(target := Vector2.ONE, duration := 1.0) -> void:
	camera.change_zoom(target, duration)


## Returns [param msg] translated to the current language if the game is using translations
## [member PopochiuSettings.use_translations]. Otherwise, the returned [String] will be the same
## as the one received as a parameter.
func get_text(msg: String) -> String:
	return tr(msg) if settings.use_translations else msg


## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuICharacter.get_instance].
func get_character_instance(script_name: String) -> PopochiuCharacter:
	return C.get_instance(script_name)


## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuIInventory.get_instance].
func get_inventory_item_instance(script_name: String) -> PopochiuInventoryItem:
	return I.get_instance(script_name)


## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuIDialog.get_instance].
func get_dialog(script_name: String) -> PopochiuDialog:
	return D.get_instance(script_name)


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
func queueable(node: Object, method: String, params := [], signal_name := "") -> Callable:
	return func (): await _queueable(node, method, params, signal_name)


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
func save_game(slot := 1, description := "") -> void:
	if _saveload.save_game(slot, description):
		game_saved.emit()


## Loads the game in the given [param slot].
func load_game(slot := 1) -> void:
	I.clean_inventory(true)
	
	if D.current_dialog:
		D.current_dialog.stop()
	
	loaded_game = _saveload.load_game(slot)
	
	if loaded_game.is_empty(): return
	
	game_load_started.emit()
	R.goto_room(
		loaded_game.player.room,
		true,
		false # Do not store the state of the current room
	)

## @deprecated
## [b]Deprecated[/b]. Now this is done by [method PopochiuMainCamera.stop_shake].
func stop_camera_shake() -> void:
	camera.stop_shake()


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
		G.mouse_entered_clickable.emit(clickable)
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
	Cursor.toggle_visibility(in_room)


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
