extends Node
# (C) Para hacer cosas con los personajes

# El nodo Character que se movió en la escena
signal character_moved(character)
signal character_spoke(character, message)
signal character_move_ended(character)
signal character_say(chr_name, dialog)
signal character_walk_to(chr_name, position)

var player: Character
var characters := []


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func character_say(chr_name: String, dialog: String, is_in_queue := true) -> void:
	var talking_character: Character = get_character(chr_name)

	if is_in_queue: yield()

	if talking_character:
		yield(talking_character.say(dialog, false), 'completed')
	else:
		printerr('CharacterInterface:', 'character %s not found')


func player_say(dialog: String, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	yield(player.say(dialog, false), 'completed')


func character_walk_to(chr_name: String, position: Vector2, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	emit_signal('character_walk_to', chr_name, position)
	yield(self, 'character_move_ended')


func player_walk_to(position: Vector2, is_in_queue := true) -> void:
	if is_in_queue: yield()

	yield(character_walk_to(Data.player, position, false), 'completed')


func walk_to_clicked(is_in_queue := true) -> void:
	if is_in_queue: yield()

	yield(character_walk_to(Data.player, Data.clicked.walk_to_point, false), 'completed')


func is_valid_character(chr_name: String) -> bool:
	for c in characters:
		if (c as Character).script_name.to_lower() == chr_name.to_lower():
			return true
	return false


func get_character(script_name: String) -> Character:
	for c in characters:
		if (c as Character).script_name.to_lower() == script_name.to_lower():
			return c
	return null

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
