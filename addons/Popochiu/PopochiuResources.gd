extends Node
class_name PopochiuResources

enum Types {
	ROOM,
	CHARACTER,
	INVENTORY_ITEM,
	DIALOG,
	# Room's object types
	PROP,
	HOTSPOT,
	REGION,
	POINT,
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

# ════ PLUGIN ══════════════════════════════════════════════════════════════════
const BASE_DIR := 'res://popochiu'
const MAIN_DOCK_PATH := 'res://addons/Popochiu/Editor/MainDock/PopochiuDock.tscn'
const MAIN_TYPES := [
	Types.ROOM, Types.CHARACTER, Types.INVENTORY_ITEM, Types.DIALOG
]
const ROOM_TYPES := [Types.PROP, Types.HOTSPOT, Types.REGION, Types.POINT, Types.WALKABLE_AREA]
const WIKI := 'https://github.com/mapedorr/popochiu/wiki/'
const CFG := 'res://addons/Popochiu/plugin.cfg'
# ════ SINGLETONS ══════════════════════════════════════════════════════════════
const GLOBALS_SNGL := 'res://popochiu/PopochiuGlobals.gd'
const UTILS_SNGL := 'res://addons/Popochiu/Engine/Others/PopochiuUtils.gd'
const CURSOR_SNGL := 'res://addons/Popochiu/Engine/Cursor/Cursor.tscn'
const POPOCHIU_SNGL := 'res://addons/Popochiu/Engine/Popochiu.tscn'
const ICHARACTER_SNGL := 'res://addons/Popochiu/Engine/Interfaces/ICharacter.gd'
const IINVENTORY_SNGL := 'res://addons/Popochiu/Engine/Interfaces/IInventory.gd'
const IDIALOG_SNGL := 'res://addons/Popochiu/Engine/Interfaces/IDialog.gd'
const IGRAPHIC_INTERFACE_SNGL :=\
'res://addons/Popochiu/Engine/Interfaces/IGraphicInterface.gd'
const IAUDIO_MANAGER_SNGL :=\
'res://addons/Popochiu/Engine/AudioManager/AudioManager.tscn'
# ════ FIRST INSTALL ═══════════════════════════════════════════════════════════
const GRAPHIC_INTERFACE_ADDON :=\
'res://addons/Popochiu/Engine/Objects/GraphicInterface/GraphicInterface.tscn'
const GRAPHIC_INTERFACE_POPOCHIU :=\
BASE_DIR + '/GraphicInterface/GraphicInterface.tscn'
const TRANSITION_LAYER_ADDON :=\
'res://addons/Popochiu/Engine/Objects/TransitionLayer/TransitionLayer.tscn'
const TRANSITION_LAYER_POPOCHIU :=\
BASE_DIR + '/TransitionLayer/TransitionLayer.tscn'
# ════ ENGINE ══════════════════════════════════════════════════════════════════
const POPOCHIU_SCENE := 'res://addons/Popochiu/Engine/Popochiu.tscn'
const CURSOR_TYPE :=\
preload('res://addons/Popochiu/Engine/Cursor/Cursor.gd').Type
const DATA := 'res://popochiu//PopochiuData.cfg'
const SETTINGS := 'res://popochiu//PopochiuSettings.tres'
const SETTINGS_CLASS :=\
preload('res://addons/Popochiu/Engine/Objects/PopochiuSettings.gd')
const ROOM_CHILDS := ['props', 'hotspots', 'walkable_areas', 'regions']
const VALID_TYPES := [
	TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING,
	TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY,
	TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY,
	TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY
]
const PROPS_IGNORE := [
	'description',
	'baseline',
	'clickable',
	'cursor',
	'always_on_top',
	'frames',
	'link_to_item',
	'_description_code',
]
const HOTSPOTS_IGNORE := [
	'description',
	'baseline',
	'clickable',
	'cursor',
	'always_on_top',
	'_description_code',
]
const WALKABLE_AREAS_IGNORE := [
	'description',
	'tint'
]
const REGIONS_IGNORE := [
	'description',
	'tint'
]
# ════ GODOT PROJECT SETTINGS ══════════════════════════════════════════════════
const DISPLAY_WIDTH := 'display/window/size/viewport_width'
const DISPLAY_HEIGHT := 'display/window/size/viewport_height'
const MAIN_SCENE := 'application/run/main_scene'
const TEST_WIDTH := 'display/window/size/window_width_override'
const TEST_HEIGHT := 'display/window/size/window_height_override'
const STRETCH_MODE := 'display/window/stretch/mode'
const STRETCH_ASPECT := 'display/window/stretch/aspect'
const IMPORTER_TEXTURE := 'importer_defaults/texture'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Verify if the folders (where Popochiu's objects will be) exists
static func init_file_structure() -> bool:
	var is_first_install := !DirAccess.dir_exists_absolute(BASE_DIR)
	
	# Create the folders that does not exist
	for d in _get_directories().values():
		if not DirAccess.dir_exists_absolute(d):
			DirAccess.make_dir_recursive_absolute(d)
	
	# Create config files
	
	# Create .cfg file
	if not FileAccess.file_exists(DATA):
		_create_empty_file(DATA)
	
	# Create settings file
	if not FileAccess.file_exists(SETTINGS):
		if ResourceSaver.save(SETTINGS_CLASS.new(), SETTINGS) != OK:
			prints('[Popochiu] Error %s creating PopochiuSettings.tres')
	
	# Create Globals file
	if not FileAccess.file_exists(GLOBALS_SNGL):
		var globals_file = FileAccess.open(GLOBALS_SNGL, FileAccess.WRITE)
		globals_file.store_string('extends Node')
	
	return is_first_install


# ▨▨▨▨ GAME DATA ▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨
static func get_data_cfg() -> ConfigFile:
	var config := ConfigFile.new()
	var err: int = config.load(DATA)
	
	if err == OK:
		return config
	
	prints("[Popochiu] Couldn't load PopochiuData config.")
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
		prints("[Popochiu] Can't delete %s key from %s section" %\
		[key, section])


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
	var props_to_ignore := ['script_name', 'scene']
	
	if not ignore_too.is_empty():
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
		if target.custom_data.is_empty(): target.erase('custom_data')


# ▨▨▨▨ SETTINGS ▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨
static func get_settings() -> PopochiuSettings:
	return load(SETTINGS) as PopochiuSettings


static func save_settings(new_settings: PopochiuSettings) -> bool:
	var result := ResourceSaver.save(new_settings, SETTINGS)
	
	if result != OK:
		push_error('[Popochiu] Error %d when updating settings.' % result)
		return false
	
	return true


# ▨▨▨▨ PLUGIN ▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨
static func get_plugin_cfg() -> ConfigFile:
	var config := ConfigFile.new()
	var err: int = config.load(CFG)
	
	if err == OK:
		return config
	
	prints("[Popochiu] Couldn't load plugin config.")
	return null


static func get_version() -> String:
	return get_plugin_cfg().get_value('plugin', 'version')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
static func _create_empty_file(path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string('')


static func _get_directories() -> Dictionary:
	return {
		BASE = BASE_DIR,
		ROOMS = BASE_DIR + '/Rooms',
		CHARACTERS = BASE_DIR + '/Characters',
		INVENTORY_ITEMS = BASE_DIR + '/InventoryItems',
		DIALOGS = BASE_DIR + '/Dialogs',
	}
