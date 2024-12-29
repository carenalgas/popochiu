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
			inventory = PopochiuUtils.i.items,
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
	
	# Load inventory items
	for item in loaded_data.player.inventory:
		PopochiuUtils.i.get_item_instance(item).add(false)
	
	# Load main object states
	for type in ["rooms", "characters", "inventory_items", "dialogs"]:
		if loaded_data.has(type):
			_load_state(type, loaded_data)
	
	# Load globals
	if loaded_data.has("globals"):
		for prop in loaded_data.globals:
			if typeof(PopochiuUtils.globals.get(prop)) == TYPE_NIL: continue
			
			PopochiuUtils.globals[prop] = loaded_data.globals[prop]
		
		if loaded_data.globals.has("custom_data")\
		and PopochiuUtils.globals.has_method("on_load"):
			PopochiuUtils.globals.on_load(loaded_data.globals.custom_data)

	return loaded_data


#endregion

#region Private ####################################################################################
func _store_data(type: String, save: Dictionary) -> void:
	for path in PopochiuResources.get_section(type):
		# load the ___State.tres file
		var data := load(path)
		
		save[type][data.script_name] = {}
		
		PopochiuResources.store_properties(save[type][data.script_name], data)
		
		match type:
			"rooms":
				data.save_children_states()
				
				for category in PopochiuResources.ROOM_CHILDREN:
					save[type][data.script_name][category] = data[category]
				
				save[type][data.script_name]["characters"] = data.characters
			"dialogs":
				save[type][data.script_name].options = {}
				
				for opt in (data as PopochiuDialog).options:
					save[type][data.script_name].options[opt.id] = {}
					PopochiuResources.store_properties(
						save[type][data.script_name].options[opt.id],
						opt,
						["id", "always_on"]
					)
		
		if save[type][data.script_name].is_empty():
			save[type].erase(data.script_name)
	
	if save[type].is_empty():
		save.erase(type)


func _load_state(type: String, loaded_game: Dictionary) -> void:
	for id in loaded_game[type]:
		var state := load(PopochiuResources.get_data_value(type, id, ""))
		
		for p in loaded_game[type][id]:
			if p == "custom_data": continue
			if type == "dialogs" and p == "options": continue
			
			state[p] = loaded_game[type][id][p]
		
		match type:
			"rooms":
				PopochiuUtils.r.rooms_states[id] = state
			"characters":
				PopochiuUtils.c.characters_states[id] = state
			"inventory_items":
				PopochiuUtils.i.items_states[id] = state
			"dialogs":
				PopochiuUtils.d.trees[id] = state
				_load_dialog_options(state, loaded_game[type][id].options)
		
		if loaded_game[type][id].has("custom_data")\
		and state.has_method("on_load"):
			state.on_load(loaded_game[type][id].custom_data)


func _load_dialog_options(
	dialog: PopochiuDialog, loaded_options: Dictionary
) -> void:
	for opt in dialog.options:
		if not loaded_options.has(opt.id): continue
		
		for prop in opt.get_script().get_script_property_list():
			if prop.name == "always_on": continue
			
			if loaded_options[opt.id].has(prop.name):
				opt[prop.name] = loaded_options[opt.id][prop.name]


#endregion
