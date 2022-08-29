extends Node
# Class for saving and loading game data.
# Thanks GDQuest for this! (https://github.com/GDQuest/godot-demos-2022/tree/main/save-game)
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

# TODO: This could be in PopochiuSettings for devs to change the path
const SAVE_GAME_PATH := 'user://save_%d.json'
const VALID_TYPES := [
	TYPE_BOOL, TYPE_INT, TYPE_REAL, TYPE_STRING,
	TYPE_ARRAY, TYPE_STRING_ARRAY, TYPE_RAW_ARRAY, TYPE_INT_ARRAY
]

var _file := File.new()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func count_saves() -> int:
	var saves := 0
	
	for i in range(1, 5):
		if _file.file_exists(SAVE_GAME_PATH % i):
			saves += 1
	
	return saves


func get_saves_descriptions() -> Dictionary:
	var saves := {}
	
	for i in range(1, 5):
		if _file.file_exists(SAVE_GAME_PATH % i):
			var error := _file.open(SAVE_GAME_PATH % i, File.READ)
			if error != OK:
				printerr(\
				'[Popochiu] Could not open the file %s. Error code: %s'\
				% [SAVE_GAME_PATH % i, error])
				return {}

			var content := _file.get_as_text()
			_file.close()
			
			var loaded_data: Dictionary = JSON.parse(content).result
			
			saves[i] = loaded_data.description
	
	return saves


func save_game(slot := 1, description := '') -> bool:
	var error := _file.open(SAVE_GAME_PATH % slot, File.WRITE)
	if error != OK:
		printerr(\
		'[Popochiu] Could not open the file %s. Error code: %s'\
		% [SAVE_GAME_PATH % slot, error])
		return false
	
	var data := {
		description = description,
		player = {
			room = E.current_room.script_name,
			inventory = I.items,
		},
		rooms = {}, # Stores the state of each PopochiuRoomData
		characters = {}, # Stores the state of each PopochiuCharacterData
		inventory_items = {}, # Stores the state of each PopochiuInventoryItemData
		dialogs = {}, # Stores the state of each PopochiuDialog
		globals = {}, # Stores the state of Globals
	}
	
	if C.player:
		data.player.id = C.player.script_name
		data.player.position = {
			x = C.player.global_position.x,
			y = C.player.global_position.y
		}
	
	# Go over each Popochiu type to save its current state ---------------------
	for type in ['rooms', 'characters', 'inventory_items', 'dialogs']:
		_store_data(type, data)
	
	# Save PopochiuGlobals.gd (Globals) ----------------------------------------
	# prop = {class_name, hint, hint_string, name, type, usage}
	for prop in Globals.get_script().get_script_property_list():
		if not prop.type in VALID_TYPES: continue
		
		# Check if the property is a script variable (8192)
		# or a export variable (8199)
		if prop.usage == PROPERTY_USAGE_SCRIPT_VARIABLE or prop.usage == (
			PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		):
			data.globals[prop.name] = Globals[prop.name]
	
	if Globals.has_method('on_save'):
		data.globals.custom_data = Globals.on_save()
	
	if not data.globals: data.erase('globals')
	
	# Write the JSON -----------------------------------------------------------
	var json_string := JSON.print(data)
	_file.store_string(json_string)
	_file.close()
	
	return true


func load_game(slot := 1) -> Dictionary:
	var error := _file.open(SAVE_GAME_PATH % slot, File.READ)
	if error != OK:
		printerr(\
		'[Popochiu] Could not open the file %s. Error code: %s'\
		% [SAVE_GAME_PATH % slot, error])
		return {}

	var content := _file.get_as_text()
	_file.close()
	
	var loaded_data: Dictionary = JSON.parse(content).result
	
	# Load inventory items
	for item in loaded_data.player.inventory:
		I.add_item(item, false, false)
	
	# Load main object states
	for type in ['rooms', 'characters', 'inventory_items', 'dialogs']:
		_load_state(type, loaded_data)
	
	# Load globals
	if loaded_data.has('globals'):
		for prop in loaded_data.globals:
			if typeof(Globals.get(prop)) == TYPE_NIL: continue
			
			Globals[prop] = loaded_data.globals[prop]
		
		if loaded_data.globals.has('custom_data')\
		and Globals.has_method('on_load'):
			Globals.on_load(loaded_data.globals.custom_data)

	return loaded_data


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _store_data(type: String, save: Dictionary) -> void:
	for path in PopochiuResources.get_section(type):
		var data := load(path)
		
		save[type][data.script_name] = {}
		
		_check_and_store_properties(save[type][data.script_name], data)
		
		if type == 'dialogs':
			save[type][data.script_name].options = {}
			
			for opt in (data as PopochiuDialog).options:
				save[type][data.script_name].options[opt.id] = {}
				_check_and_store_properties(
					save[type][data.script_name].options[opt.id],
					opt,
					['id']
				)
		
		if not save[type][data.script_name]:
			save[type].erase(data.script_name)
	
	if not save[type]:
		save.erase(type)


func _check_and_store_properties(
target: Dictionary, source: Object, ignore_too := []
) -> void:
	var props_to_ignore := ['script_name', 'scene']
	
	if not ignore_too.empty():
		props_to_ignore.append_array(ignore_too)
	
	# ---- Store basic type properties -----------------------------------------
	# prop = {class_name, hint, hint_string, name, type, usage}
	for prop in source.get_script().get_script_property_list():
		if prop.name in props_to_ignore: continue
		if not prop.type in VALID_TYPES: continue
		
		# Check if the property is a script variable (8192)
		# or a export variable (8199)
		if prop.usage == PROPERTY_USAGE_SCRIPT_VARIABLE or prop.usage == (
			PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		):
			target[prop.name] = source[prop.name]
	
	# ---- Call custom function to store extra data ----------------------------
	if source.has_method('on_save'):
		target.custom_data = source.on_save()
		if not target.custom_data: target.erase('custom_data')


func _load_state(type: String, loaded_game: Dictionary) -> void:
	for id in loaded_game[type]:
		var state := load(PopochiuResources.get_data_value(type, id, ''))
		
		for p in loaded_game[type][id]:
			if p == 'custom_data': continue
			if type == 'dialogs' and p == 'options': continue
			
			state[p] = loaded_game[type][id][p]
		
		if type == 'rooms':
			E.rooms_states[id] = state
		elif type == 'dialogs':
			D.trees[id] = state
			_load_dialog_options(state, loaded_game[type][id].options)
		
		if loaded_game[type][id].has('custom_data')\
		and state.has_method('on_load'):
			state.on_load(loaded_game[type][id].custom_data)


func _load_dialog_options(dialog: PopochiuDialog, loaded_options: Dictionary) -> void:
	for opt in dialog.options:
		if not loaded_options.has(opt.id): continue
		
		for prop in opt.get_script().get_script_property_list():
			if loaded_options[opt.id].has(prop.name):
				opt[prop.name] = loaded_options[opt.id][prop.name]
