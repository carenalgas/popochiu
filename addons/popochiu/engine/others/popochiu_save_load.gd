# @popochiu-docs-category engine
class_name PopochiuSaveLoad
extends Resource
## Class that allows to save and load game data.
## 
## Thanks GDQuest for this! ↴↴↴
## https://github.com/GDQuest/godot-demos-2022/tree/main/save-game

# TODO: This could be in PopochiuSettings for devs to change the path
const SAVE_GAME_PATH := "user://save_%d.json"


#region Public #####################################################################################
func count_saves() -> int:
	var saves := 0
	
	for i in range(1, 5):
		if FileAccess.file_exists(SAVE_GAME_PATH % i):
			saves += 1
	
	return saves


func get_saves_descriptions() -> Dictionary:
	var saves := {}
	
	for i in range(1, 5):
		if FileAccess.file_exists(SAVE_GAME_PATH % i):
			var opened := FileAccess.open(SAVE_GAME_PATH % i, FileAccess.READ)
			if not opened:
				PopochiuUtils.print_error(
					"Could not open the file %s. Error code: %s" % [
						SAVE_GAME_PATH % i, opened.get_open_error()
					]
				)
				return {}

			var content := opened.get_as_text()
			opened.close()
			
			var test_json_conv = JSON.new()
			test_json_conv.parse(content)
			
			if test_json_conv.data == null: continue
			
			var loaded_data: Dictionary = test_json_conv.data
			
			saves[i] = loaded_data.description
	
	return saves


func save_game(slot := 1, description := "") -> bool:
	var opened := FileAccess.open(SAVE_GAME_PATH % slot, FileAccess.WRITE)
	if not opened:
		PopochiuUtils.print_error(
			"Could not open the file %s. Error code: %s" % [
				SAVE_GAME_PATH % slot, opened.get_open_error()
			]
		)
		return false
	
	var data := {
		description = description,
		player = {
			room = PopochiuUtils.r.current.script_name,
			# Legacy inventory format — kept for backward compatibility with older Popochiu versions.
			# New saves use character_inventories below.
			inventory = _build_legacy_inventory_save_data(),
		},
		rooms = {}, # Stores the state of each PopochiuRoomData
		characters = {}, # Stores the state of each PopochiuCharacterData
		inventory_items = {}, # Stores the state of each PopochiuInventoryItemData
		dialogs = {}, # Stores the state of each PopochiuDialog
		globals = {}, # Stores the state of Globals
	}
	
	if PopochiuUtils.c.player:
		data.player.id = PopochiuUtils.c.player.script_name
		data.player.position = {
			x = PopochiuUtils.c.player.global_position.x,
			y = PopochiuUtils.c.player.global_position.y
		}
	
	# Go over each Popochiu type to save its current state -----------------------------------------
	for type in ["rooms", "characters", "inventory_items", "dialogs"]:
		_store_data(type, data)
	
	# Per-character inventories. Key is character script_name, value is Array of
	# {name: String, qty: int} dictionaries.
	data["character_inventories"] = _build_character_inventories_save_data()
	
	# Save PopochiuGlobals.gd (Globals) ------------------------------------------------------------
	# prop = {class_name, hint, hint_string, name, type, usage}
	for prop in PopochiuUtils.globals.get_script().get_script_property_list():
		if not prop.type in PopochiuResources.VALID_TYPES: continue
		
		# Check if the property is a script variable (8192)
		# or a export variable (8199)
		if prop.usage == PROPERTY_USAGE_SCRIPT_VARIABLE or prop.usage == (
			PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		):
			data.globals[prop.name] = PopochiuUtils.globals[prop.name]
	
	if PopochiuUtils.globals.has_method("on_save"):
		data.globals.custom_data = PopochiuUtils.globals.on_save()
	
	if data.globals.is_empty(): data.erase("globals")
	
	# Write the JSON -------------------------------------------------------------------------------
	var json_string := JSON.stringify(data)
	opened.store_string(json_string)
	opened.close()
	
	return true


func load_game(slot := 1) -> Dictionary:
	var opened := FileAccess.open(SAVE_GAME_PATH % slot, FileAccess.READ)
	if not opened:
		PopochiuUtils.print_error(
			"Could not open the file %s. Error code: %s" % [
				SAVE_GAME_PATH % slot, opened.get_open_error()
			]
		)
		return {}

	var content := opened.get_as_text()
	opened.close()
	
	var test_json_conv = JSON.new()
	test_json_conv.parse(content)
	var loaded_data: Dictionary = test_json_conv.data
	var player_data = loaded_data.get("player", {})
	
	PopochiuUtils.i.is_restoring = true
	
	# Load per-character inventories (new format).
	var character_inventories = loaded_data.get("character_inventories", {})
	if character_inventories is Dictionary and not character_inventories.is_empty():
		for character_name: String in character_inventories:
			var entries: Array = character_inventories[character_name]
			for entry in entries:
				_restore_inventory_entry(entry, character_name)
	else:
		# Fallback: legacy format — player.inventory (Array of String or Array of Dictionary).
		# Introduced in refs #349. Migrate to per-character inventory on load.
		var inventory_entries = []
		if player_data is Dictionary:
			inventory_entries = player_data.get("inventory", [])
		for entry in inventory_entries:
			_restore_inventory_entry(entry)
	
	PopochiuUtils.i.is_restoring = false
	
	# Load main object states
	for type in ["rooms", "characters", "inventory_items", "dialogs"]:
		if loaded_data.has(type):
			_load_state(type, loaded_data)
	
	# Load globals
	if loaded_data.has("globals"):
		for prop in loaded_data.globals:
			if typeof(PopochiuUtils.globals.get(prop)) == TYPE_NIL: continue
			
			PopochiuUtils.globals[prop] = loaded_data.globals[prop]
		
		if loaded_data.globals.has("custom_data") and PopochiuUtils.globals.has_method("on_load"):
			PopochiuUtils.globals.on_load(loaded_data.globals.custom_data)

	return loaded_data


#endregion

#region Private ####################################################################################
func _store_data(type: String, save: Dictionary) -> void:
	for key: String in PopochiuResources.get_section_keys(type):
		var stored := _get_object_state(type, key)
		save[type][key] = stored

		match type:
			"rooms":
				var room_state := _get_room_state(key)
				room_state.save_children_states(
					PopochiuUtils.r.current
					if is_instance_valid(PopochiuUtils.r.current)
					and PopochiuUtils.r.current.script_name == key
					else null
				)

				if (
					is_instance_valid(PopochiuUtils.r.current)
					and PopochiuUtils.r.current.script_name == key
				):
					room_state.custom_properties.clear()
					PopochiuResources.store_custom_properties(
						room_state.custom_properties, PopochiuUtils.r.current
					)
					room_state.visited_times = PopochiuUtils.r.current.visited_times

				save[type][key] = room_state.custom_properties.duplicate(true)
				save[type][key].visited_times = room_state.visited_times

				for category: String in PopochiuResources.ROOM_CHILDREN:
					save[type][key][category] = room_state[category]

				save[type][key].characters = room_state.characters
			"dialogs":
				_store_dialog_state(key, save)
			"characters":
				PopochiuUtils.c.characters_states[key] = stored
			"inventory_items":
				PopochiuUtils.i.items_states[key] = stored

		if save[type][key].is_empty():
			save[type].erase(key)
	
	if save[type].is_empty():
		save.erase(type)


# Returns the persistent custom state of a room, character, or inventory item.
func _get_object_state(type: String, key: String) -> Dictionary:
	var state := {}

	match type:
		"rooms":
			var room_state := _get_room_state(key)
			state = room_state.custom_properties.duplicate(true)
			state.visited_times = room_state.visited_times
		"characters":
			var character := PopochiuUtils.c.get_character(key)
			if is_instance_valid(character):
				PopochiuResources.store_custom_properties(state, character)
			else:
				state = _stored_state_to_dictionary(key, PopochiuUtils.c.characters_states)
		"inventory_items":
			var item := PopochiuUtils.i.get_item_instance(key)
			if is_instance_valid(item):
				PopochiuResources.store_custom_properties(state, item)
			else:
				state = _stored_state_to_dictionary(key, PopochiuUtils.i.items_states)
		"dialogs":
			var dialog: PopochiuDialog = load(
				PopochiuResources.get_data_value("dialogs", key, "")
			)
			if is_instance_valid(dialog):
				PopochiuResources.store_properties(state, dialog)

	return state


func _get_room_state(room_name: String) -> PopochiuRoomData:
	var state = PopochiuUtils.r.rooms_states.get(room_name)
	if state is PopochiuRoomData:
		if state.scene.is_empty():
			state.scene = PopochiuResources.get_object_scene_path("rooms", room_name)
		return state

	var room_state := PopochiuRoomData.new()
	room_state.script_name = room_name
	room_state.scene = PopochiuResources.get_object_scene_path("rooms", room_name)
	room_state.resource_name = room_name

	if state is Object:
		PopochiuResources.store_custom_properties(room_state.custom_properties, state)
		if state.get("visited_times") != null:
			room_state.visited_times = state.visited_times
		for category: String in PopochiuResources.ROOM_CHILDREN + ["characters"]:
			if state.get(category) is Dictionary:
				room_state[category] = state[category]

	PopochiuUtils.r.rooms_states[room_name] = room_state
	return room_state


func _stored_state_to_dictionary(key: String, states: Dictionary) -> Dictionary:
	return PopochiuResources.state_to_dictionary(states.get(key, {}))


func _store_dialog_state(key: String, save: Dictionary) -> void:
	var dialog: PopochiuDialog = load(PopochiuResources.get_data_value("dialogs", key, ""))
	if not is_instance_valid(dialog):
		return

	save.dialogs[key].options = {}

	for option in dialog.options:
		save.dialogs[key].options[option.id] = {}
		PopochiuResources.store_properties(
			save.dialogs[key].options[option.id],
			option,
			["id", "always_on"]
		)


func _load_state(type: String, loaded_game: Dictionary) -> void:
	for id in loaded_game[type]:
		var state: Dictionary = loaded_game[type][id]

		match type:
			"rooms":
				_load_room_state(id, state)
			"characters":
				PopochiuUtils.c.characters_states[id] = state.duplicate(true)
				_restore_object_state(PopochiuUtils.c.get_character(id), state)
			"inventory_items":
				PopochiuUtils.i.items_states[id] = state.duplicate(true)
				_restore_object_state(PopochiuUtils.i.get_item_instance(id), state)
			"dialogs":
				_load_dialog_state(id, state)


func _load_room_state(room_name: String, state: Dictionary) -> void:
	var room_state := PopochiuRoomData.new()
	room_state.script_name = room_name
	room_state.scene = PopochiuResources.get_object_scene_path("rooms", room_name)
	room_state.resource_name = room_name
	room_state.visited_times = state.get("visited_times", 0)

	for category: String in PopochiuResources.ROOM_CHILDREN:
		room_state[category] = state.get(category, {})

	room_state.characters = state.get("characters", {})

	var custom_properties: Dictionary = state.duplicate(true)
	for reserved: String in ["visited_times", "characters"] + PopochiuResources.ROOM_CHILDREN:
		custom_properties.erase(reserved)
	room_state.custom_properties = custom_properties

	PopochiuUtils.r.rooms_states[room_name] = room_state


func _restore_object_state(object: Object, state: Dictionary) -> void:
	PopochiuResources.restore_custom_properties(object, state)


func _load_dialog_state(id: String, loaded_state: Dictionary) -> void:
	var state := load(PopochiuResources.get_data_value("dialogs", id, ""))
	if not is_instance_valid(state):
		return

	for p in loaded_state:
		if p == "custom_data": continue
		if p == "options": continue
		if state[p] is Array and state[p].is_typed():
			state[p].assign(loaded_state[p])
			continue

		state[p] = loaded_state[p]

	PopochiuUtils.d.trees[id] = state
	if loaded_state.has("options"):
		_load_dialog_options(state, loaded_state.options)

	if loaded_state.has("custom_data") and state.has_method("on_load"):
		state.on_load(loaded_state.custom_data)


func _load_dialog_options(
	dialog: PopochiuDialog, loaded_options: Dictionary
) -> void:
	for opt in dialog.options:
		if not loaded_options.has(opt.id): continue
		
		for prop in opt.get_script().get_script_property_list():
			if prop.name == "always_on": continue
			
			if loaded_options[opt.id].has(prop.name):
				opt[prop.name] = loaded_options[opt.id][prop.name]


func _restore_inventory_entry(entry, character_name: String = "") -> void:
	var item_name := ""
	var qty := 1

	if entry is String:
		# refs #349: Legacy save format — plain string item name, assume quantity of 1.
		item_name = entry
	elif entry is Dictionary:
		item_name = entry.get("name", "")
		qty = entry.get("qty", 1)
	else:
		PopochiuUtils.print_warning(
			"Skipping malformed inventory entry while loading a save file."
		)
		return

	if item_name.is_empty():
		PopochiuUtils.print_warning(
			"Skipping inventory entry with an empty item name while loading a save file."
		)
		return

	if typeof(qty) != TYPE_INT:
		PopochiuUtils.print_warning(
			"Skipping inventory entry for %s. Quantity must be an integer." % item_name
		)
		return

	if qty <= 0:
		PopochiuUtils.print_warning(
			"Skipping inventory entry for %s. Quantity must be greater than 0." % item_name
		)
		return

	var item := PopochiuUtils.i.get_item_instance(item_name)
	if not is_instance_valid(item):
		PopochiuUtils.print_warning(
			"Skipping inventory entry for %s. Item could not be instantiated." % item_name
		)
		return

	# Resolve target character — if character_name is provided, use it; otherwise default to player.
	var target: PopochiuCharacter = null
	if not character_name.is_empty():
		target = PopochiuUtils.c.get_character(character_name)
	if not is_instance_valid(target):
		target = PopochiuUtils.c.player

	if is_instance_valid(target):
		item.add(qty, target)


# Builds per-character inventory data for the save file.
# Returns a Dictionary {character_name: [{name, qty}, ...]}.
func _build_character_inventories_save_data() -> Dictionary:
	var result := {}
	# Iterate over all characters registered in the character interface.
	for c_name: String in PopochiuUtils.c.characters_states:
		var character: PopochiuCharacter = PopochiuUtils.c.get_character(c_name)
		if not is_instance_valid(character) or character.inventory.is_empty():
			continue
		var entries: Array = []
		for item_name: String in character.inventory:
			var item: PopochiuInventoryItem = character.inventory[item_name]
			if is_instance_valid(item) and item.quantity_owned > 0:
				entries.append({
					"name": item_name,
					"qty": item.quantity_owned,
				})
		if not entries.is_empty():
			result[c_name] = entries
	return result


# Builds the legacy inventory array for the save file (player character only).
# Kept for backward compatibility with older Popochiu versions.
func _build_legacy_inventory_save_data() -> Array:
	if not is_instance_valid(PopochiuUtils.c.player):
		return []
	var result := []
	for item_name: String in PopochiuUtils.c.player.inventory:
		var item: PopochiuInventoryItem = PopochiuUtils.c.player.inventory[item_name]
		result.append({
			"name": item_name,
			"qty": item.quantity_owned if is_instance_valid(item) else 1,
		})
	return result


#endregion
