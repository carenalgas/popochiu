extends Node
# (C) Data and functions to make characters do actions.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

# character parameter is a PopochiuCharacter node
signal character_move_ended(character)
signal character_spoke(character, message)
signal character_grab_done(character)

var player: PopochiuCharacter = null setget set_player
var characters := []
var camera_owner: PopochiuCharacter = null


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Makes a character (script_name) say something.
func character_say(chr_name: String, dialog: String) -> void:
	yield()
	yield(_character_say(chr_name, dialog), 'completed')


func character_say_no_block(
	chr_name: String, dialog: String, call_done := true
) -> void:
	yield(_character_say(chr_name, dialog), 'completed')
	
	if call_done:
		G.done()


# Makes the PC (player character) say something inside an E.run([])
func player_say(dialog: String) -> void:
	yield()
	yield(player.say(dialog, false), 'completed')


# Makes the PC (player character) say something outside an E.run([])
func player_say_no_block(dialog: String, call_done := true) -> void:
	yield(player.say(dialog, false), 'completed')
	
	if call_done:
		G.done()


# Makes a character (script_name) walk to a position in the current room.
func character_walk_to(\
chr_name: String, position: Vector2, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	var walking_character: PopochiuCharacter = get_character(chr_name)
	if walking_character:
		yield(
			walking_character.walk(E.current_room.to_global(position), false),
			'completed'
		)
	else:
		printerr(
			'[Popochiu] ICharacter.character_walk_to:',
			'character %s not found' % chr_name
		)
		yield(get_tree(), 'idle_frame')


# Makes the PC (player character) walk to a position in the current room.
func player_walk_to(position: Vector2, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	yield(player.walk(position, false), 'completed')


# Makes the PC (player character) walk to the walk_to_point position of the last
# clicked PopochiuClickable (e.g. a PopochiuProp, a PopochiuHotspot, another
# PopochiuCharacter, etc.) in the room.
func walk_to_clicked(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	yield(player_walk_to(E.clicked.walk_to_point, false), 'completed')


# Makes the PC (player character) look at the last clicked PopochiuClickable.
# E.g. a PopochiuProp, another PopochiuCharacter, etc.
func face_clicked(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	yield(C.player.face_clicked(false), 'completed')


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
		return new_character

	return null


func change_camera_owner(c: PopochiuCharacter, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	if E.cutscene_skipped:
		camera_owner = c
		yield(get_tree(), 'idle_frame')
		return
	
	camera_owner = c
	yield(get_tree(), 'idle_frame')


func set_character_emotion(\
chr_name: String, emotion: String, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	if get_character(chr_name):
		get_character(chr_name).emotion = emotion
	
	yield(get_tree(), 'idle_frame')


func set_character_ignore_walkable_areas(chr_name: String, value: bool) -> void:
	if get_character(chr_name):
		get_character(chr_name).ignore_walkable_areas = value


func get_character_ignore_walkable_areas(chr_name: String) -> bool:
	return get_character(chr_name).ignore_walkable_areas


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_player(value: PopochiuCharacter) -> void:
	player = value
	camera_owner = value


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _character_say(chr_name: String, dialog: String) -> void:
	var talking_character: PopochiuCharacter = get_character(chr_name)
	
	if talking_character:
		yield(talking_character.say(dialog, false), 'completed')
	else:
		printerr(
			'[Popochiu] ICharacter.character_say:',
			'character %s not found' % chr_name
		)
		yield(get_tree(), 'idle_frame')
