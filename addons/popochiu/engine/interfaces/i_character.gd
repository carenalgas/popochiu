# Data and functions to make characters do actions.
extends Node

# `character` is a PopochiuCharacter
signal character_move_ended(character)
signal character_spoke(character, message)
signal character_grab_done(character)

var player: PopochiuCharacter : set = set_player
var characters := []
var camera_owner: PopochiuCharacter
var characters_states := {}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Queues the call to walk_to_clicked()
func queue_walk_to_clicked() -> Callable:
	return func (): await walk_to_clicked()


# Makes the PC (player-controlled character) walk to the walk_to_point position
# of the last clicked PopochiuClickable (e.g. a PopochiuProp, a PopochiuHotspot,
# another PopochiuCharacter, etc.) in the room.
func walk_to_clicked() -> void:
	await player.walk(
		(E.clicked as PopochiuClickable).to_global(E.clicked.walk_to_point)
	)


# Queues the call to face_clicked()
func queue_face_clicked() -> Callable:
	return func (): await face_clicked()


# Makes the PC (player character) look at the last clicked PopochiuClickable.
# E.g. a PopochiuProp, another PopochiuCharacter, etc.
func face_clicked() -> void:
	await player.face_clicked()


func queue_change_camera_owner(c: PopochiuCharacter) -> Callable:
	return func (): await change_camera_owner(c)


func change_camera_owner(c: PopochiuCharacter) -> void:
	if E.cutscene_skipped:
		camera_owner = c
		await E.get_tree().process_frame
		return
	
	camera_owner = c
	await E.get_tree().process_frame


func get_runtime_character(script_name: String) -> PopochiuCharacter:
	var character: PopochiuCharacter = null

	for c in characters:
		if c.script_name.to_lower() == script_name.to_lower():
			character = c
			
			break

	if not character:
		printerr('[Popochiu] Character %s is not in the room' % script_name)

	return character


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_player(value: PopochiuCharacter) -> void:
	player = value
	camera_owner = value


# Checks if the character exists in the array of PopochiuCharacter instances.
func is_valid_character(script_name: String) -> bool:
	var result := false
	var sn := script_name.to_lower()
	
	if sn == 'player':
		result = true
	else:
		for c in characters:
			if c.script_name.to_lower() == sn:
				result = true
				
				break
	
	return result


# Gets a character identified by the received script_name.
func get_character(script_name: String) -> PopochiuCharacter:
	if script_name.to_lower() == 'player'\
	or player.script_name.to_lower() == script_name:
		return player
	
	for c in characters:
		if c.script_name.to_lower() == script_name.to_lower():
			return c
	
	# If the character doesn't existis, try to instantiate it from the list of
	# characters (Resource) in PopochiuData.cfg
	var new_character: PopochiuCharacter = E.get_character_instance(script_name)
	if new_character:
		characters.append(new_character)
		set(new_character.script_name, new_character)
		
		return new_character

	return null
