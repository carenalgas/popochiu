# @popochiu-docs-category game-scripts-interfaces
class_name PopochiuICharacter
extends Node
## Provides access to the project's [PopochiuCharacter]s via the singleton [b]C[/b] (for example:
## [code]C.player.say("What a wonderful plugin")[/code]).
##
## Use this interface to manipulate characters at runtime.
##
## Capabilities include:
##
## - Accessing the Player-controlled Character (PC) directly with [code]C.player[/code].[br]
## - Accessing any character by name ([code]C.CharacterName[/code] - autocompletion supported).[br]
## - Commanding characters to move, speak, etc.
## - Change camera ownership.
##
## [b]Use examples:[/b]
## [codeblock]
## func on_click() -> void:
##     await C.walk_to_clicked() # Make the PC move to the clicked object
##     await C.face_clicked() # Make the PC look at the clicked object
##     await C.player.say("It's a three-headed monkey!!!") # The PC says something
##     await C.Popsy.say("Don't tell me...") # Another character says something
##     C.GrumpyOldMan.say("Snort! Snarl!") # Make a character speak in background (non blocking)
## [/codeblock]


## Emitted when [param character] speaks [param message].
signal character_spoke(character: PopochiuCharacter, message: String)
## Emitted when the player character changes from [param old_player] to [param new_player].
signal player_changed(old_player: PopochiuCharacter, new_player: PopochiuCharacter)

## The [PopochiuCharacter] that is the current Player-controlled Character (PC).
## Setting this variable updates [member camera_owner] and emits [signal player_changed]
## so other systems can react to the player swap.
var player: PopochiuCharacter : set = set_player
## The [PopochiuCharacter] that currently owns the camera.
var camera_owner: PopochiuCharacter
## Stores per-character runtime state. Keys are the characters'
## [member PopochiuCharacter.script_name] values.
var characters_states := {}

var _characters := {}


#region Godot ######################################################################################
func _init() -> void:
	Engine.register_singleton(&"C", self)


#endregion

#region Public #####################################################################################
## Moves the Player-controlled Character (PC) non-blocking to the
## [member PopochiuClickable.walk_to_point] of the last clicked [PopochiuClickable] (for example a
## [PopochiuProp], [PopochiuHotspot], or another [PopochiuCharacter]) in the room.
## Provide an optional [param offset] to adjust the final position.
func walk_to_clicked(offset := Vector2.ZERO) -> void:
	await player.walk_to_clicked(offset)


## Moves the Player-controlled Character (PC) non-blocking to the
## [member PopochiuClickable.walk_to_point] of the last clicked [PopochiuClickable] (for example a
## [PopochiuProp], [PopochiuHotspot], or another [PopochiuCharacter]) in the room.
## Provide an optional [param offset] to adjust the final position.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to_clicked(offset := Vector2.ZERO) -> Callable:
	return func (): await walk_to_clicked(offset)


## Similar to [method walk_to_clicked] but blocks the GUI while the PC is moving
## to prevent player input.
func walk_to_clicked_blocking(offset := Vector2.ZERO) -> void:
	await player.walk_to_clicked_blocking(offset)


## Similar to [method walk_to_clicked] but blocks the GUI while the PC is moving
## to prevent player input.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to_clicked_blocking(offset := Vector2.ZERO) -> Callable:
	return func (): await walk_to_clicked_blocking(offset)


## Makes the Player-controlled Character (PC) look at the last clicked [PopochiuClickable].
func face_clicked() -> void:
	await player.face_clicked()


## Makes the Player-controlled Character (PC) look at the last clicked [PopochiuClickable].
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_clicked() -> Callable:
	return func (): await face_clicked()


## Changes the camera owner to [param c]. If [PopochiuUtils.e.cutscene_skipped] is true, the camera
## owner is updated immediately and a frame is yielded to ensure the change takes effect.
func change_camera_owner(c: PopochiuCharacter) -> void:
	if PopochiuUtils.e.cutscene_skipped:
		camera_owner = c
		await PopochiuUtils.e.get_tree().process_frame
		return
	
	camera_owner = c
	await PopochiuUtils.e.get_tree().process_frame


## Changes the camera owner to [param c]. If [PopochiuUtils.e.cutscene_skipped] is true, the camera
## owner is updated immediately and a frame is yielded to ensure the change takes effect.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_change_camera_owner(c: PopochiuCharacter) -> Callable:
	return func (): await change_camera_owner(c)


## Returns the runtime instance of the [PopochiuCharacter] identified by [param script_name], or
## [code]null[/code] if the character is not present in the current room.[br]
## This is used by [b]res://game/autoloads/c.gd[/b] to populate character variables at runtime.
func get_runtime_character(script_name: String) -> PopochiuCharacter:
	var character: PopochiuCharacter = null
	
	if _characters.has(script_name):
		character = _characters[script_name]
	else:
		PopochiuUtils.print_error("Character %s is not in the room" % script_name)
	
	return character


## Returns [code]true[/code] if [param script_name] refers to the current player or exists in
## the room's character list.
func is_valid_character(script_name: String) -> bool:
	var is_valid := false
	
	if script_name.to_lower() == "player":
		is_valid = true
	else:
		is_valid = _characters.has(script_name)
	
	return is_valid


## Returns a [PopochiuCharacter] instance identified by [param script_name]. If the instance
## does not already exist in [member _characters], it will be instantiated from project data
## and registered.[br]
## If the character cannot be found in project data, returns [code]null[/code].
func get_character(script_name: String) -> PopochiuCharacter:
	var character: PopochiuCharacter = null
	
	if script_name.is_empty():
		return character
	
	if (
		script_name.to_lower() == "player"
		or (is_instance_valid(player) and player.script_name.to_lower() == script_name)
	):
		character = player
	elif _characters.has(script_name):
		character = _characters[script_name]
	else:
		# If the character doesn't exist, try to instantiate it from the list of
		# characters (Resource) in popochiu_data.cfg
		character = get_instance(script_name)
		
		if character:
			_characters[character.script_name] = character
			set(character.script_name, character)
	
	return character


## Instantiates and returns the [PopochiuCharacter] resource referenced by [param script_name]
## as defined in the Popochiu project data. If the character does not exist in the project,
## logs an error and returns [code]null[/code].
func get_instance(script_name: String) -> PopochiuCharacter:
	var tres_path: String = PopochiuResources.get_data_value("characters", script_name, "")
	
	if not tres_path:
		PopochiuUtils.print_error("Character [b]%s[/b] doesn't exist in the project" % script_name)
		return null
	
	return load(load(tres_path).scene).instantiate()


#endregion

#region SetGet #####################################################################################
func set_player(value: PopochiuCharacter) -> void:
	var old_player = player
	player = value
	camera_owner = value
	
	# Emit the player changed signal so characters can update their clickability
	player_changed.emit(old_player, value)


#endregion
