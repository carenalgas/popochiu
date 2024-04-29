class_name PopochiuCharactersHelper
extends RefCounted
## Helper class to handle things related to [PopochiuCharacters] but that may not be the
## responsibility of [PopochiuICharacter].

## Stablishes the [PopochiuCharacter] that will be controlled by players.
static func define_player() -> void:
	if PopochiuResources.has_data_value("setup", "pc"):
		var pc_data_path: String = PopochiuResources.get_data_value(
			"characters",
			PopochiuResources.get_data_value("setup", "pc", ""),
			""
		)

		if pc_data_path:
			var pc_data: PopochiuCharacterData = load(pc_data_path)
			var pc: PopochiuCharacter = load(pc_data.scene).instantiate()
			
			C.player = pc
			C.characters.append(pc)
			C.set(pc.script_name, pc)
	
	# Load the first PopochiuCharacter in the project as the default PC
	if not C.player:
		# Set the first character on the list to be the default player character
		var characters := PopochiuResources.get_section("characters")

		if not characters.is_empty():
			var pc: PopochiuCharacter = load(
				(load(characters[0]) as PopochiuCharacterData).scene
			).instantiate()

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
			var colon_idx: int = text.find(":")
			if colon_idx >= 0:
				var colon_prefix: String = text.substr(0, colon_idx)
				
				var emotion_idx := colon_prefix.find("(")
				var auto_idx := colon_prefix.find("[")
				var name_idx := -1
				
				if emotion_idx > 0:
					if auto_idx < 0 or (auto_idx > 0 and auto_idx > emotion_idx):
						name_idx = emotion_idx
					elif auto_idx > 0:
						name_idx = auto_idx
				elif auto_idx > 0:
					name_idx = auto_idx
				
				var character_name: String = colon_prefix.substr(
					0, name_idx
				)
				
				if not C.is_valid_character(character_name):
					PopochiuUtils.print_error("No PopochiuCharacter with name: %s" % character_name)
					await E.get_tree().process_frame
					
					return
				
				var character := C.get_character(character_name)
				
				if not C.is_valid_character(character_name):
					PopochiuUtils.print_error("No PopochiuCharacter with name: %s" % character_name)
					await E.get_tree().process_frame
					
					return
				
				var emotion := ""
				if emotion_idx > 0:
					emotion = colon_prefix.substr(emotion_idx + 1).rstrip(")")
				
				var auto := -1.0
				if auto_idx > 0:
					E.auto_continue_after = float(colon_prefix.substr(auto_idx + 1).rstrip(")"))
				
				if not emotion.is_empty():
					character.emotion = emotion
				
				var dialogue := text.substr(colon_idx + 1).trim_prefix(" ")
				
				await character.say(dialogue)
			else:
				await E.get_tree().process_frame
	
	E.auto_continue_after = -1.0
