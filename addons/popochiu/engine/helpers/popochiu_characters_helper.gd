class_name PopochiuCharactersHelper
extends RefCounted
## Helper class to handle things related to [PopochiuCharacters] but that may not be the
## responsibility of [PopochiuICharacter].

static var char_pattern := r'(?<character>.+?)'
static var emo_pattern := r'(?:\((?<emotion>\w+)\))?'
static var time_pattern := r'(?:\[(?<time>\d+)\])?'
static var line_pattern := r':\s*(?<line>.+)'
static var emo_or_time_pattern := r'(%s%s|%s%s)?' % [
	emo_pattern, time_pattern, time_pattern, emo_pattern
]


#region Public #####################################################################################
## Defines the [PopochiuCharacter] that will be controlled by players.
static func define_player() -> void:
	var pc := C.get_character(PopochiuResources.get_data_value("setup", "pc", ""))
	
	# If there is no explicitly configured Player-controlled Character (PC), select the first
	# PopochiuCharacter on the list of characters to be the default PC
	if not pc:
		var characters := PopochiuResources.get_section_keys("characters")
		if not characters.is_empty():
			pc = C.get_character(characters[0])
	
	if pc:
		C.player = pc


## Evals [param text] to know if it is a wait inside a dialog or if it is a [PopochiuCharacter]
## saying something. This is used when calling [method E.queue].
static func execute_string(text: String) -> void:
	var regex = RegEx.new()
	regex.compile(r'^\.+$')
	var result = regex.search(text)
	
	if result:
		# A shortcut to wait X seconds
		await E.wait(0.25 * pow(2, result.get_string(0).count(".") - 1))
	elif ":" in text:
		await _trigger_dialog_line(text)
	else:
		await E.get_tree().process_frame
	
	E.auto_continue_after = -1.0


#endregion

#region Private ####################################################################################
static func _trigger_dialog_line(text: String) -> void:
	var regex = RegEx.new()
	regex.compile(r'^%s%s%s$' % [char_pattern, emo_or_time_pattern, line_pattern])
	var result = regex.search(text)
	
	var character_name := result.get_string("character")
	var emotion := result.get_string("emotion")
	var change_time := result.get_string("time")
	var dialogue_line := result.get_string("line")
	
	var character := C.get_character(character_name)
	
	if not character:
		PopochiuUtils.print_warning("Character %s not found to play dialog line." % character_name)
		
		await E.get_tree().process_frame
		return
	
	if emotion:
		character.emotion = emotion
	
	if change_time:
		E.auto_continue_after = float(change_time)
	
	await character.say(dialogue_line)


#endregion
