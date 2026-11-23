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
	
	var game_state_snapshot := PopochiuUtils.e.game_state.get_snapshot()
	var data := {
		description = description,
		player = {
			room = PopochiuUtils.r.current.script_name,
			# Legacy inventory format — kept for backward compatibility with older Popochiu versions.
			# New saves use character_inventories below.
			inventory = _build_legacy_inventory_save_data(),
		},
		rooms = game_state_snapshot.get("rooms", {}),
		characters = game_state_snapshot.get("characters", {}),
		inventory_items = game_state_snapshot.get("inventory_items", {}),
		dialogs = {},
		globals = {},
	}
	
	if PopochiuUtils.c.player:
		data.player.id = PopochiuUtils.c.player.script_name
		data.player.position = {
			x = PopochiuUtils.c.player.global_position.x,
			y = PopochiuUtils.c.player.global_position.y
		}
	
	# Dialogs still use their own resources --------------------------------------------------------
	_store_dialogs(data)
	
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
	
	PopochiuUtils.e.game_state.clear_snapshots()
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
	
	# Load object snapshots after inventories so item quantities are restored over the final state.
	PopochiuUtils.e.game_state.load_snapshot(loaded_data)

	# Dialogs still use their own resources
	if loaded_data.has("dialogs"):
		_load_dialogs(loaded_data)
	
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
func _store_dialogs(save: Dictionary) -> void:
	for key: String in PopochiuResources.get_section_keys("dialogs"):
		_store_dialog_state(key, save)

	if save.dialogs.is_empty():
		save.erase("dialogs")


func _store_dialog_state(key: String, save: Dictionary) -> void:
	var dialog: PopochiuDialog = load(PopochiuResources.get_data_value("dialogs", key, ""))
	if not is_instance_valid(dialog):
		return

	save.dialogs[key] = {}
	PopochiuResources.store_properties(save.dialogs[key], dialog)
	save.dialogs[key].options = {}

	for option: PopochiuDialogOption in dialog.options:
		save.dialogs[key].options[option.id] = {}
		PopochiuResources.store_properties(
			save.dialogs[key].options[option.id],
			option,
			["id", "always_on"]
		)


func _load_dialogs(loaded_game: Dictionary) -> void:
	for id: String in loaded_game.dialogs:
		_load_dialog_state(id, loaded_game.dialogs[id])


func _load_dialog_state(id: String, loaded_state: Dictionary) -> void:
	var state := load(PopochiuResources.get_data_value("dialogs", id, ""))
	if not is_instance_valid(state):
		return

	for p: String in loaded_state:
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
	var characters := PopochiuUtils.c.get_characters().duplicate()
	if is_instance_valid(PopochiuUtils.c.player):
		characters[PopochiuUtils.c.player.script_name] = PopochiuUtils.c.player

	for c_name: String in characters:
		var character: PopochiuCharacter = characters[c_name]
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
