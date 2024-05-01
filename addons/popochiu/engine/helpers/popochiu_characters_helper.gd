class_name PopochiuCharactersHelper
extends RefCounted
## Helper class to handle things related to [PopochiuCharacters] but that may not be the
## responsibility of [PopochiuICharacter].


#region Public #####################################################################################
## Defines the [PopochiuCharacter] that will be controlled by players.
static func define_player() -> void:
	var pc: PopochiuCharacter
	
	if PopochiuResources.has_data_value("setup", "pc"):
		var pc_data_path: String = PopochiuResources.get_data_value(
			"characters",
			PopochiuResources.get_data_value("setup", "pc", ""),
			""
		)

		if pc_data_path:
			var pc_data: PopochiuCharacterData = load(pc_data_path)
			pc = load(pc_data.scene).instantiate()
	
	# If there is no explicitly configured Player-controlled Character (PC), select the first
	# PopochiuCharacter in the project as it
	if not C.player:
		# Set the first character on the list to be the default player character
		var characters := PopochiuResources.get_section("characters")

		if not characters.is_empty():
			pc = load((load(characters[0]) as PopochiuCharacterData).scene).instantiate()
	
	if pc:
		C.player = pc
		C.characters.append(pc)
		C.set(pc.script_name, pc)


## Evals [param text] to know if it is a wait inside a dialog or if it is a [PopochiuCharacter]
## saying something. This is used when calling [method E.queue].
static func exec_string(text: String) -> void:
	match text:
		".":
			await E.wait(0.25)
		"..":
			await E.wait(0.5)
		"...":
			await E.wait(1.0)
		"....":
			await E.wait(2.0)
		_:
			if not ":" in text:
				await E.get_tree().process_frame
			else:
				await _trigger_dialog_line(text)
	
	E.auto_continue_after = -1.0
#endregion

#region Private ####################################################################################
static func _trigger_dialog_line(text: String) -> void:
	var regex = RegEx.new()
	regex.compile(r'^(.+?)(?:\((\w+)\))?(?:\[(\d+)\])?:\s*(.+)$')
	var result = regex.search(text)
	
	var character_name := result.get_string(1)
	var emotion := result.get_string(2)
	var change_time := float(result.get_string(3))
	var dialogue_line := result.get_string(4)
	
	var character := C.get_character(character_name)
	
	if not character:
		await E.get_tree().process_frame
		return
	
	if emotion:
		character.emotion = emotion
	
	if change_time:
		E.auto_continue_after = change_time
	
	await character.say(dialogue_line)


#endregion
