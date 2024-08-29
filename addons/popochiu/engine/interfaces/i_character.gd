class_name PopochiuICharacter
extends Node
## Provides access to the [PopochiuCharacter]s in the game. Access with [b]C[/b] (e.g.
## [code]C.player.say("What a wonderful plugin")[/code]).
##
## Use it to manipulate Characters. Its script is [b]i_character.gd[/b].[br][br]
##
## Some things you can do with it:[br][br]
## [b]•[/b] Access the Player-controlled Character (PC) directly [code]C.player[/code].[br]
## [b]•[/b] Access any character (with autocompletion based on its name).[br]
## [b]•[/b] Make characters move or say something.[br][br]
##
## Example:
## [codeblock]
## func on_click() -> void:
##     await C.walk_to_clicked() # Make the PC move to the clicked object
##     await C.face_clicked() # Make the PC look at the clicked object
##     await C.player.say("It's a three-headed monkey!!!") # The PC says something
##     await C.Popsy.say("Don't tell me...") # Another character says something
## [/codeblock]


## Emitted when [param character] says [param message].
signal character_spoke(character: PopochiuCharacter, message: String)

## Access to the [PopochiuCharacter] that is the current Player-controlled Character (PC).
var player: PopochiuCharacter : set = set_player
## Access to the [PopochiuCharacter] that is owning the camera.
var camera_owner: PopochiuCharacter
## Stores data about the state of each [PopochiuCharacter] in the game. The key of each entry is the
## [member PopochiuCharacter.script_name] of the character.
var characters_states := {}

var _characters := {}


#region Public #####################################################################################
## Makes the Player-controlled Character (PC) move (NON-BLOCKING) to the
## [member PopochiuClickable.walk_to_point] position of the last clicked [PopochiuClickable] (i.e. a
## [PopochiuProp], a [PopochiuHotspot], or another [PopochiuCharacter]) in the room. You can set an
## [param offset] relative to the target position.
func walk_to_clicked(offset := Vector2.ZERO) -> void:
	await player.walk_to_clicked(offset)


## Makes the Player-controlled Character (PC) move (NON-BLOCKING) to the
## [member PopochiuClickable.walk_to_point] position of the last clicked [PopochiuClickable] (i.e. a
## [PopochiuProp], a [PopochiuHotspot], or another [PopochiuCharacter]) in the room. You can set an
## [param offset] relative to the target position.
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_walk_to_clicked(offset := Vector2.ZERO) -> Callable:
	return func (): await walk_to_clicked(offset)


## Similar to [method walk_to_clicked] but BLOCKING the GUI to prevent players from clicking other
## objects or any point in the room.
func walk_to_clicked_blocking(offset := Vector2.ZERO) -> void:
	await player.walk_to_clicked_blocking(offset)


## Similar to [method walk_to_clicked] but BLOCKING the GUI to prevent players from clicking other
## objects or any point in the room.
func queue_walk_to_clicked_blocking(offset := Vector2.ZERO) -> Callable:
	return func (): await walk_to_clicked_blocking(offset)


## Makes the Player-controlled Character (PC) look at the last clicked [PopochiuClickable].
func face_clicked() -> void:
	await player.face_clicked()


## Makes the Player-controlled Character (PC) look at the last clicked [PopochiuClickable].[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_face_clicked() -> Callable:
	return func (): await face_clicked()


## Makes the camera follow [param c].
func change_camera_owner(c: PopochiuCharacter) -> void:
	if E.cutscene_skipped:
		camera_owner = c
		await E.get_tree().process_frame
		return
	
	camera_owner = c
	await E.get_tree().process_frame


## Makes the camera follow [param c].[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_change_camera_owner(c: PopochiuCharacter) -> Callable:
	return func (): await change_camera_owner(c)


## Returns the instance of the [PopochiuCharacter] identified with [param script_name]. If the
## character doesn't exists, then [code]null[/code] is returned.[br][br]
## This method is used by [b]res://game/autoloads/c.gd[/b] to load the instace of each character
## (present in that script as a variable for code autocompletion) in runtime.
func get_runtime_character(script_name: String) -> PopochiuCharacter:
	var character: PopochiuCharacter = null
	
	if _characters.has(script_name):
		character = _characters[script_name]
	else:
		PopochiuUtils.print_error("Character %s is not in the room" % script_name)
	
	return character


## Returns [code]true[/code] if [param script_name] is equal to [code]player[/code] or exist in
## [member characters].
func is_valid_character(script_name: String) -> bool:
	var is_valid := false
	
	if script_name.to_lower() == "player":
		is_valid = true
	else:
		is_valid = _characters.has(script_name)
	
	return is_valid


## Gets a [PopochiuCharacter] identified with [param script_name]. If the instance doesn't exist in
## [member characters], then one is created, added to the array, and returned.
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
		# If the character doesn't existis, try to instantiate it from the list of characters (Resource)
		# in popochiu_data.cfg
		character = get_instance(script_name)
		
		if character:
			_characters[character.script_name] = character
			set(character.script_name, character)
	
	return character


## Gets the instance of the [PopochiuCharacter] identified with [param script_name].
func get_instance(script_name: String) -> PopochiuCharacter:
	var tres_path: String = PopochiuResources.get_data_value("characters", script_name, "")
	
	if not tres_path:
		PopochiuUtils.print_error("Character [b]%s[/b] doesn't exist in the project" % script_name)
		return null
	
	return load(load(tres_path).scene).instantiate()


#endregion

#region SetGet #####################################################################################
func set_player(value: PopochiuCharacter) -> void:
	player = value
	camera_owner = value


#endregion
