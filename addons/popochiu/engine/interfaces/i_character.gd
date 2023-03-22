# (C) Data and functions to make characters do actions.
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
# Makes a character (script_name) say something.
#func character_say(chr_name: String, dialog: String) -> Callable:
#	return func (): await character_say_now(chr_name, dialog)
#
#
#func character_say_now(chr_name: String, dialog: String) -> void:
#	if not E.in_run():
#		G.block()
#
#	var talking_character: PopochiuCharacter = get_character(chr_name)
#
#	if talking_character:
#		await talking_character.say_now(dialog)
#	else:
#		printerr(
#			'[Popochiu] ICharacter.character_say:',
#			'character %s not found' % chr_name
#		)
#		await get_tree().process_frame
#
#	if not E.in_run():
#		G.done()
#
#
## Makes the PC (player character) say something inside an E.run([])
#func player_say(dialog: String) -> Callable:
#	return func (): await player_say_now(dialog)
#
#
## Makes the PC (player character) say something outside an E.run([])
#func player_say_now(dialog: String) -> void:
#	if not E.in_run():
#		G.block()
#
#	await player.say_now(dialog)
#
#	if not E.in_run():
#		G.done()


func character_walk_to(chr_name: String, position: Vector2) -> Callable:
	return func (): await character_walk_to_now(chr_name, position)


# Makes a character (script_name) walk to a position in the current room.
func character_walk_to_now(chr_name: String, position: Vector2) -> void:
	var walking_character: PopochiuCharacter = get_character(chr_name)
	if walking_character:
#		await walking_character.walk_now(position)
#		await walking_character.walk_now(walking_character.to_global(position))
		await walking_character.walk_now(E.current_room.to_global(position))
	else:
		printerr(
			'[Popochiu] ICharacter.character_walk_to:',
			'character %s not found' % chr_name
		)
		
		await get_tree().process_frame


func player_walk_to(position: Vector2) -> Callable:
	return func (): await player_walk_to_now(position)


# Makes the PC (player character) walk to a position in the current room.
func player_walk_to_now(position: Vector2) -> void:
	await player.walk_now(position)


func walk_to_clicked() -> Callable:
	return func (): await walk_to_clicked_now()


# Makes the PC (player character) walk to the walk_to_point position of the last
# clicked PopochiuClickable (e.g. a PopochiuProp, a PopochiuHotspot, another
# PopochiuCharacter, etc.) in the room.
func walk_to_clicked_now() -> void:
	await player_walk_to_now(
		(E.clicked as PopochiuClickable).to_global(E.clicked.walk_to_point)
	)
#	await player_walk_to(E.clicked.walk_to_point)


func face_clicked() -> Callable:
	return func (): await face_clicked_now()


# Makes the PC (player character) look at the last clicked PopochiuClickable.
# E.g. a PopochiuProp, another PopochiuCharacter, etc.
func face_clicked_now() -> void:
	await C.player.face_clicked_now()


# Checks if the character exists in the array of PopochiuCharacter instances.
func is_valid_character(script_name: String) -> bool:
	for c in characters:
		if (c as PopochiuCharacter).script_name.to_lower() == script_name.to_lower():
			return true
	return false


# Gets a character identified by the received script_name.
func get_character(script_name: String) -> PopochiuCharacter:
	if script_name.to_lower() == 'player'\
	or player.script_name.to_lower() == script_name:
		return player
	
	for c in characters:
		if (c as PopochiuCharacter).script_name.to_lower() == script_name.to_lower():
			return c
	
	# If the character doesn't existis, try to instantiate from the list of
	# characters (Resource) in Popochiu
	var new_character: PopochiuCharacter = E.get_character_instance(script_name)
	if new_character:
		characters.append(new_character)
		C.set(new_character.script_name, new_character)
		
		return new_character

	return null


func change_camera_owner(c: PopochiuCharacter) -> Callable:
	return func (): await change_camera_owner_now(c)


func change_camera_owner_now(c: PopochiuCharacter) -> void:
	if E.cutscene_skipped:
		camera_owner = c
		await get_tree().process_frame
		return
	
	camera_owner = c
	await get_tree().process_frame


func set_character_emotion(chr_name: String, emotion: String) -> Callable:
	return func (): await set_character_emotion_now(chr_name, emotion)


func set_character_emotion_now(chr_name: String, emotion: String) -> void:
	if get_character(chr_name):
		get_character(chr_name).emotion = emotion
	
	await get_tree().process_frame


func set_character_ignore_walkable_areas(chr_name: String, value: bool) -> void:
	if get_character(chr_name):
		get_character(chr_name).ignore_walkable_areas = value


func get_character_ignore_walkable_areas(chr_name: String) -> bool:
	return get_character(chr_name).ignore_walkable_areas


func get_runtime_character(script_name: String) -> PopochiuCharacter:
	var character: PopochiuCharacter = null

	for c in characters:
		if (c as PopochiuCharacter).script_name.to_lower() == script_name.to_lower():
			character = c
			break

	if not character:
		printerr('[Popochiu] Character %s is not in the room' % script_name)

	return character


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_player(value: PopochiuCharacter) -> void:
	player = value
	camera_owner = value
