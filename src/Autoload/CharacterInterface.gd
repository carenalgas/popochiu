extends Node

# El nodo Character que se movió en la escena
signal character_moved(character)
signal character_spoke(character, message)
signal character_move_ended(character)
signal character_say(chr_name, dialog)
signal character_walk_to(chr_name, position)

var player: Character
var characters := []


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func character_say(chr_name: String, dialog: String) -> void:
	var talking_character: Character = _get_character(chr_name)
	yield(talking_character.say(dialog, true), 'completed')


func player_say(dialog: String) -> void:
	yield(player.say(dialog, true), 'completed')


func character_walk_to(chr_name: String, position: Vector2) -> void:
	emit_signal('character_walk_to', chr_name, position)
	yield(self, 'character_move_ended')
#	yield(get_tree().create_timer(0.2), 'timeout')


func player_walk_to(position: Vector2) -> void:
	yield(character_walk_to(Data.player, position), 'completed')


func walk_to_clicked() -> void:
	yield(character_walk_to(Data.player, Data.clicked.walk_to_point), 'completed')


func is_valid_character(chr_name: String) -> bool:
	for c in characters:
		if (c as Character).script_name.to_lower() == chr_name.to_lower():
			return true
	return false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _get_character(script_name: String) -> Character:
	for c in characters:
		if (c as Character).script_name.to_lower() == script_name.to_lower():
			return c
	return null
