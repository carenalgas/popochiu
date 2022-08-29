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
	POINT
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
const ROOM_TYPES := [Types.PROP, Types.HOTSPOT, Types.REGION, Types.POINT]
const WIKI := 'https://github.com/mapedorr/popochiu/wiki/'
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
# ════ GODOT PROJECT SETTINGS ══════════════════════════════════════════════════
const DISPLAY_WIDTH := 'display/window/size/width'
const DISPLAY_HEIGHT := 'display/window/size/height'
const MAIN_SCENE := 'application/run/main_scene'
const TEST_WIDTH := 'display/window/size/test_width'
const TEST_HEIGHT := 'display/window/size/test_height'
const STRETCH_MODE := 'display/window/stretch/mode'
const STRETCH_ASPECT := 'display/window/stretch/aspect'
const IMPORTER_TEXTURE := 'importer_defaults/texture'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Verify if the folders (where Popochiu's objects will be) exists
static func init_file_structure() -> bool:
	var directory := Directory.new()
	var is_first_install := !directory.dir_exists(BASE_DIR)
	
	# Create the folders that does not exist
	for d in _get_directories().values():
		if not directory.dir_exists(d):
			directory.make_dir_recursive(d)
	
	# Create config files
	
	# Create .cfg file
	if not directory.file_exists(DATA):
		_create_empty_file(DATA)
	
	# Create settings file
	if not directory.file_exists(SETTINGS):
		if ResourceSaver.save(SETTINGS, SETTINGS_CLASS.new()) != OK:
			prints('[Popochiu] Error %s creating PopochiuSettings.tres')
	
	# Create Globals file
	if not directory.file_exists(GLOBALS_SNGL):
		var file = File.new()
		file.open(GLOBALS_SNGL, File.WRITE)
		file.store_string('extends Node')
		file.close()
	
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


# ▨▨▨▨ SETTINGS ▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨
static func get_settings() -> PopochiuSettings:
	return load(SETTINGS) as PopochiuSettings


static func save_settings(new_settings: PopochiuSettings) -> bool:
	var result := ResourceSaver.save(SETTINGS, new_settings)
	
	if result != OK:
		push_error('[Popochiu] Error %d when updating settings.' % result)
		return false
	
	return true


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
static func _create_empty_file(path):
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string('')
	file.close()


static func _get_directories() -> Dictionary:
	return {
		BASE = BASE_DIR,
		ROOMS = BASE_DIR + '/Rooms',
		CHARACTERS = BASE_DIR + '/Characters',
		INVENTORY_ITEMS = BASE_DIR + '/InventoryItems',
		DIALOGS = BASE_DIR + '/Dialogs',
	}
