class_name PopochiuResources
extends Node

enum Types {
	ROOM,
	CHARACTER,
	INVENTORY_ITEM,
	DIALOG,
	# Room object types
	PROP,
	HOTSPOT,
	REGION,
	MARKER,
	WALKABLE_AREA
}
enum CursorType {
	NONE,
	ACTIVE,
	DOWN,
	IDLE,
	LEFT,
	LOOK,
	RIGHT,
	SEARCH,
	TALK,
	UP,
	USE,
	WAIT,
}
enum AudioTypes {
	NONE = -1,
	MUSIC,
	SOUND_EFFECT,
	VOICE,
	UI
}

# PLUGIN -------------------------------------------------------------------------------------------
const MAIN_DOCK_PATH = "res://addons/popochiu/editor/main_dock/popochiu_dock.tscn"
const MAIN_TYPES = [
	Types.ROOM, Types.CHARACTER, Types.INVENTORY_ITEM, Types.DIALOG
]
const ROOM_TYPES = [Types.PROP, Types.HOTSPOT, Types.REGION, Types.MARKER, Types.WALKABLE_AREA]
const DOCUMENTATION = "https://carenalgas.github.io/popochiu/"
const CFG = "res://addons/popochiu/plugin.cfg"
const GUI_ADDON_FOLDER = "res://addons/popochiu/engine/objects/gui/"
const GUI_TEMPLATES_FOLDER = GUI_ADDON_FOLDER + "templates/"
const GUI_SCRIPT_TEMPLATES_FOLDER = "res://addons/popochiu/engine/templates/gui/"
const RETRO_RESOLUTION = Vector2(356.0, 200.0)
# SINGLETONS ---------------------------------------------------------------------------------------
const GLOBALS_SNGL = "res://game/popochiu_globals.gd"
const UTILS_SNGL = "res://addons/popochiu/engine/others/popochiu_utils.gd"
const CURSOR_SNGL = "res://addons/popochiu/engine/cursor/cursor.tscn"
const POPOCHIU_SNGL = "res://addons/popochiu/engine/popochiu.tscn"
const IROOM = "res://addons/popochiu/engine/interfaces/i_room.gd"
const ICHARACTER = "res://addons/popochiu/engine/interfaces/i_character.gd"
const IINVENTORY = "res://addons/popochiu/engine/interfaces/i_inventory.gd"
const IDIALOG = "res://addons/popochiu/engine/interfaces/i_dialog.gd"
const IGRAPHIC_INTERFACE_SNGL = "res://addons/popochiu/engine/interfaces/i_graphic_interface.gd"
const IAUDIO = "res://addons/popochiu/engine/interfaces/i_audio.gd"
const R_SNGL = "res://game/autoloads/r.gd"
const C_SNGL = "res://game/autoloads/c.gd"
const I_SNGL = "res://game/autoloads/i.gd"
const D_SNGL = "res://game/autoloads/d.gd"
const A_SNGL = "res://game/autoloads/a.gd"
const G_SNGL = "res://game/autoloads/g.gd"
# FIRST INSTALL ------------------------------------------------------------------------------------
const GI = 0
const TL = 1
const TRANSITION_LAYER_ADDON =\
"res://addons/popochiu/engine/objects/transition_layer/transition_layer.tscn"
# ENGINE -------------------------------------------------------------------------------------------
const POPOCHIU_SCENE = "res://addons/popochiu/engine/popochiu.tscn"
const AUDIO_MANAGER =\
"res://addons/popochiu/engine/audio_manager/audio_manager.tscn"
const CURSOR_TYPE =\
preload("res://addons/popochiu/engine/cursor/cursor.gd").Type
const DATA = "res://game//popochiu_data.cfg"
const ROOM_CHILDREN = ["props", "hotspots", "walkable_areas", "regions"]
const VALID_TYPES = [
	TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING,
	TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY,
	TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY,
	TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY
]
const PROPS_IGNORE = [
	"description",
	"baseline",
	"clickable",
	"cursor",
	"always_on_top",
	"frames",
	"v_frames",
	"link_to_item",
	"_description_code",
	"last_click_button",
	"_double_click_delay",
	"_has_double_click",
]
const HOTSPOTS_IGNORE = [
	"description",
	"baseline",
	"clickable",
	"cursor",
	"always_on_top",
	"_description_code",
	"last_click_button",
	"_double_click_delay",
	"_has_double_click",
]
const WALKABLE_AREAS_IGNORE = [
	"description",
	"tint"
]
const REGIONS_IGNORE = [
	"description",
	"tint",
	"scaling",
	"scale_top",
	"scale_bottom"
]
const SNGL_TEMPLATE = "@tool\n" +\
"extends \"%s\"\n\n" +\
"# classes ----\n" +\
"# ---- classes\n" +\
"\n" +\
"# nodes ----\n" +\
"# ---- nodes\n" +\
"\n" +\
"# functions ----\n" +\
"# ---- functions\n" +\
"\n"
const SNGL_SETUP = {
	R_SNGL : {
		interface = IROOM,
		section = "rooms",
		"class" = "res://game/rooms/%s/room_%s.gd",
		"const" = "const PR%s := preload(\"%s\")\n",
		node = "var %s: PR%s : get = get_%s\n",
		"func" = "func get_%s() -> PR%s: return get_runtime_room(\"%s\")\n",
		prefix = "R",
	},
	C_SNGL : {
		interface = ICHARACTER,
		section = "characters",
		"class" = "res://game/characters/%s/character_%s.gd",
		"const" = "const PC%s := preload(\"%s\")\n",
		node = "var %s: PC%s : get = get_%s\n",
		"func" = "func get_%s() -> PC%s: return get_runtime_character(\"%s\")\n",
		prefix = "C",
	},
	I_SNGL : {
		interface = IINVENTORY,
		section = "inventory_items",
		"class" = "res://game/inventory_items/%s/inventory_item_%s.gd",
		"const" = "const PII%s := preload(\"%s\")\n",
		node = "var %s: PII%s : get = get_%s\n",
		"func" = "func get_%s() -> PII%s: return get_item_instance(\"%s\")\n",
		prefix = "I",
	},
	D_SNGL : {
		interface = IDIALOG,
		section = "dialogs",
		"class" = "res://game/dialogs/%s/dialog_%s.gd",
		"const" = "const PD%s := preload(\"%s\")\n",
		node = "var %s: PD%s : get = get_%s\n",
		"func" = "func get_%s() -> PD%s: return get_instance(\"%s\")\n",
		prefix = "D",
	}
}
const A_TEMPLATE = "@tool\n" +\
"extends \"%s\"\n\n" +\
"# cues ----\n" +\
"# ---- cues\n" +\
"\n"
const AUDIO_CUE_SOUND =\
"res://addons/popochiu/engine/audio_manager/audio_cue_sound.gd"
const AUDIO_CUE_MUSIC =\
"res://addons/popochiu/engine/audio_manager/audio_cue_music.gd"
const VAR_AUDIO_CUE_SOUND = "var %s: AudioCueSound = load(\"%s\")\n"
const VAR_AUDIO_CUE_MUSIC = "var %s: AudioCueMusic = load(\"%s\")\n"
# GODOT PROJECT SETTINGS ---------------------------------------------------------------------------
const DISPLAY_WIDTH = "display/window/size/viewport_width"
const DISPLAY_HEIGHT = "display/window/size/viewport_height"
const MAIN_SCENE = "application/run/main_scene"
const TEST_WIDTH = "display/window/size/window_width_override"
const TEST_HEIGHT = "display/window/size/window_height_override"
const STRETCH_MODE = "display/window/stretch/mode"
const STRETCH_ASPECT = "display/window/stretch/aspect"
# GUI TEMPLATES ------------------------------------------------------------------------------------
const GUI_CUSTOM = "custom"
const GUI_CUSTOM_SCENE = GUI_ADDON_FOLDER + "popochiu_gui.tscn"
const GUI_CUSTOM_TEMPLATE = GUI_SCRIPT_TEMPLATES_FOLDER + "custom_commands_template.gd"
# GAME ---------------------------------------------------------------------------------------------
const GAME_PATH = "res://game/"
const ROOMS_PATH = GAME_PATH + "rooms/"
const CHARACTERS_PATH = GAME_PATH + "characters/"
const INVENTORY_ITEMS_PATH = GAME_PATH + "inventory_items/"
const DIALOGS_PATH = GAME_PATH + "dialogs/"
const GUI_GAME_FOLDER = GAME_PATH + "gui/"
const GUI_GAME_SCENE = GUI_GAME_FOLDER + "gui.tscn"
const GUI_COMMANDS = GUI_GAME_FOLDER + "gui_commands.gd"
const TRANSITION_LAYER = GAME_PATH + "transition_layer/transition_layer.tscn"


#region Public #####################################################################################
# Verify if the folders (where Popochiu's objects will be) exists
static func init_file_structure() -> bool:
	var is_first_install := !DirAccess.dir_exists_absolute(GAME_PATH)
	
	# Create the folders that does not exist
	for d in _get_directories().values():
		if not DirAccess.dir_exists_absolute(d):
			DirAccess.make_dir_recursive_absolute(d)
	
	# ---- Create config files ---------------------------------------------------------------------
	# Create .cfg file
	if not FileAccess.file_exists(DATA):
		_create_empty_file(DATA)
	
	# Create Globals file
	if not FileAccess.file_exists(GLOBALS_SNGL):
		var globals_file = FileAccess.open(GLOBALS_SNGL, FileAccess.WRITE)
		globals_file.store_string("extends Node")
		globals_file.close()
	
	# ---- Create autoload files -------------------------------------------------------------------
	create_auto_loads()
	
	return is_first_install


static func create_auto_loads() -> void:
	for key in SNGL_SETUP:
		if not FileAccess.file_exists(key):
			var file := FileAccess.open(key, FileAccess.WRITE)
			file.store_string(SNGL_TEMPLATE % SNGL_SETUP[key].interface)
			file.close()
	
	if not FileAccess.file_exists(A_SNGL):
		var file := FileAccess.open(A_SNGL, FileAccess.WRITE)
		file.store_string(A_TEMPLATE % IAUDIO)
		file.close()


static func update_autoloads(save := false) -> void:
	# ---- Create autoload files -------------------------------------------------------------------
	create_auto_loads()
	
	# ---- Update autoload files -------------------------------------------------------------------
	for id in SNGL_SETUP:
		if FileAccess.file_exists(id):
			var s: Script = load(id)
			var code := s.source_code
			var modified := false
			var sngl_setup: Dictionary = SNGL_SETUP[id]
			
			if not get_data_cfg().has_section(sngl_setup.section):
				continue
			
			for key in get_data_cfg().get_section_keys(sngl_setup.section):
				var var_name: String = key
				var snake_name := key.to_snake_case()
					
				if var_name[0].is_valid_int():
					var_name = var_name.insert(0, sngl_setup.prefix)
				
				if not ("var %s" % var_name) in code:
					var classes_idx := code.find("# ---- classes")
					var class_path: String = sngl_setup["class"] % [
						snake_name, snake_name
					]
					
					code = code.insert(
						classes_idx,
						sngl_setup["const"] % [key, class_path]
					)
					
					var nodes_idx := code.find("# ---- nodes")
					code = code.insert(
						nodes_idx,
						sngl_setup.node % [var_name, key, key]
					)
					
					var functions_idx := code.find("# ---- functions")
					code = code.insert(
						functions_idx,
						sngl_setup["func"] % [key, key, key]
					)
					
					modified = true
			
			if modified:
				s.source_code = code
				
				if save: ResourceSaver.save(s, id)
	
	# ---- Populate the A singleton ----------------------------------------------------------------
	if not get_data_cfg().has_section("audio")\
	or not FileAccess.file_exists(A_SNGL):
		return
	
	# [mx_cues, sfx_cues, vo_cues, ui_cues]
	var audio_groups := get_data_cfg().get_section_keys("audio")
	var s: Script = load(A_SNGL)
	var code := s.source_code
	var modified := false
	
	var old_audio_cues := []
	
	# Add all the AudioCues as variables
	for group in audio_groups:
		for path in get_data_value("audio", group, []):
			# Check if the AudioCue is of a valid type
			var audio_cue: Resource = load(path)
			var script_path: String = audio_cue.get_script().resource_path
			
			if not script_path in [AUDIO_CUE_MUSIC, AUDIO_CUE_SOUND]:
				# Backup the properties of the AudioCue
				var values = audio_cue.get_values()
				
				if group == "mx_cues":
					audio_cue.set_script(load(AUDIO_CUE_MUSIC))
				else:
					audio_cue.set_script(load(AUDIO_CUE_SOUND))
				
				# Restore the properties of the AudioCue
				audio_cue.set_values(values)
				old_audio_cues.append(audio_cue)
				
				ResourceSaver.save(audio_cue, path)
			
			var var_name := audio_cue.resource_name
			
			if ("var %s" % var_name) in code:
				continue
			
			var cues_idx := code.find("# ---- cues")
			
			if group == "mx_cues":
				code = code.insert(
					cues_idx, VAR_AUDIO_CUE_MUSIC % [var_name, path]
				)
			else:
				code = code.insert(
					cues_idx, VAR_AUDIO_CUE_SOUND % [var_name, path]
				)
			
			modified = true
	
	if modified:
		s.source_code = code
		
		if save: ResourceSaver.save(s, A_SNGL)
	
	# Save the script changes in the AudioCues
	for cue in old_audio_cues:
		ResourceSaver.call_deferred("save", cue.resource_path, cue)


static func remove_autoload_obj(id: String, script_name: String) -> void:
	var sngl_setup: Dictionary = SNGL_SETUP[id]
	var snake_name := script_name.to_snake_case()
	var class_path: String = sngl_setup["class"] % [snake_name, snake_name]
	var s: Script = load(id)
	var code := s.source_code
	
	code = code.replace(sngl_setup["const"] % [script_name, class_path], "")
	code = code.replace(sngl_setup.node % [script_name, script_name, script_name], "")
	code = code.replace(sngl_setup["func"] % [script_name, script_name, script_name], "")
	
	s.source_code = code
	ResourceSaver.save(s, id)


static func remove_audio_autoload(type: String, var_name: String, path: String) -> void:
	var s: Script = load(A_SNGL)
	var code := s.source_code
	
	if type == "mx_cues":
		code = code.replace(VAR_AUDIO_CUE_MUSIC % [var_name, path], "")
	else:
		code = code.replace(VAR_AUDIO_CUE_SOUND % [var_name, path], "")
	
	s.source_code = code
	ResourceSaver.save(s, A_SNGL)


# ---- GAME DATA -----------------------------------------------------------------------------------
static func get_data_cfg() -> ConfigFile:
	var config := ConfigFile.new()
	var err: int = config.load(DATA)
	
	if err == OK:
		return config
	
	PopochiuUtils.print_error("Couldn't load popochiu_data.cfg")
	return null


static func set_data_value(section: String, key: String, value) -> int:
	var config := get_data_cfg()
	
	config.set_value(section, key, value)
	return config.save(DATA)


static func has_data_value(section: String, key: String) -> bool:
	return get_data_cfg().has_section_key(section, key)


static func get_data_value(section: String, key: String, default):
	var config := get_data_cfg()
	
	if not config.has_section(section):
		return default
	
	return config.get_value(section, key, default)


static func erase_data_value(section: String, key: String) -> void:
	var config := get_data_cfg()
	
	if config.has_section_key(section, key):
		config.erase_section_key(section, key)
		config.save(DATA)
	else:
		PopochiuUtils.print_error("Can't delete %s key from %s section" % [key, section])


static func get_section(section: String) -> Array:
	var config := get_data_cfg()
	var resource_paths := []
	
	if config.has_section(section):
		for key in config.get_section_keys(section):
			resource_paths.append(config.get_value(section, key))
	
	return resource_paths


static func store_properties(
	target: Dictionary, source: Object, ignore_too := []
) -> void:
	copy_popochiu_object_properties(target, source, ignore_too)
	
	# ---- Call custom function to store extra data ------------------------------------------------
	if source.has_method("on_save"):
		target.custom_data = source.on_save()
		if target.custom_data.is_empty(): target.erase("custom_data")


static func copy_popochiu_object_properties(target, source: Object, ignore_too := []) -> void:
	var properties_to_ignore := ["script_name", "scene"]
	
	if not ignore_too.is_empty():
		properties_to_ignore.append_array(ignore_too)
	
	# ---- Store basic type properties -------------------------------------------------------------
	# prop = {class_name, hint, hint_string, name, type, usage}
	for prop in source.get_script().get_script_property_list():
		if prop.name in properties_to_ignore: continue
		if not prop.type in VALID_TYPES: continue
		
		# Check if the property is a script variable (8192)
		# or a export variable (8199)
		if prop.usage == PROPERTY_USAGE_SCRIPT_VARIABLE or prop.usage == (
			PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		):
			target[prop.name] = source[prop.name]


static func has_property(source: Object, property: String) -> bool:
	for prop in source.get_script().get_script_property_list():
		if prop.name == property:
			return true
	
	return false


static func get_section_keys(section: String) -> Array:
	var keys := []
	var config := get_data_cfg()

	if config.has_section(section):
		keys = config.get_section_keys(section)

	return keys


# ---- PLUGIN --------------------------------------------------------------------------------------
static func get_plugin_cfg() -> ConfigFile:
	var config := ConfigFile.new()
	var err: int = config.load(CFG)
	
	if err == OK:
		return config
	
	PopochiuUtils.print_error("Couldn't load plugin config.")
	return null


static func get_version() -> String:
	return get_plugin_cfg().get_value("plugin", "version")


static func is_setup_done() -> bool:
	return get_data_value("setup", "done", false)


static func is_gui_set() -> bool:
	return (
		!get_data_value("ui", "template", "").is_empty()
		and DirAccess.dir_exists_absolute(GUI_GAME_FOLDER)
	)


#endregion

#region Private ####################################################################################
static func _create_empty_file(path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("")
	file.close()


static func _get_directories() -> Dictionary:
	return {
		BASE = GAME_PATH,
		AUTOLOADS = GAME_PATH + "/autoloads/",
		ROOMS = ROOMS_PATH,
		CHARACTERS = CHARACTERS_PATH,
		INVENTORY_ITEMS = INVENTORY_ITEMS_PATH,
		DIALOGS = DIALOGS_PATH,
	}


#endregion
