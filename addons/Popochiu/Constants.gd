extends Node

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

const BASE_DIR := 'res://popochiu'
const MAIN_DOCK_PATH := 'res://addons/Popochiu/Editor/MainDock/PopochiuDock.tscn'
const EMPTY_DOCK_PATH := 'res://addons/Popochiu/Editor/MainDock/EmptyDock.tscn'
const UTILS_SNGL := 'res://addons/Popochiu/Engine/Others/PopochiuUtils.gd'
const CURSOR_SNGL := 'res://addons/Popochiu/Engine/Cursor/Cursor.tscn'
const POPOCHIU_SNGL := 'res://addons/Popochiu/Engine/Popochiu.tscn'
const ICHARACTER_SNGL := 'res://addons/Popochiu/Engine/Interfaces/ICharacter.gd'
const IINVENTORY_SNGL := 'res://addons/Popochiu/Engine/Interfaces/IInventory.gd'
const IDIALOG_SNGL := 'res://addons/Popochiu/Engine/Interfaces/IDialog.gd'
const IGRAPHIC_INTERFACE_SNGL := 'res://addons/Popochiu/Engine/Interfaces/IGraphicInterface.gd'
const IAUDIO_MANAGER_SNGL := 'res://addons/Popochiu/Engine/AudioManager/AudioManager.tscn'
# const GLOBALS_SRC := 'res://addons/Popochiu/Engine/Objects/Globals.gd'
# const GLOBALS_SNGL := 'res://popochiu/Globals.gd'
const GRAPHIC_INTERFACE_SRC := 'res://addons/Popochiu/Engine/Objects/GraphicInterface/'
const GRAPHIC_INTERFACE_SCENE := BASE_DIR + '/GraphicInterface/GraphicInterface.tscn'
const TRANSITION_LAYER_SRC := 'res://addons/Popochiu/Engine/Objects/TransitionLayer/'
const TRANSITION_LAYER_SCENE := BASE_DIR + '/TransitionLayer/TransitionLayer.tscn'
const POPOCHIU_SCENE := 'res://addons/Popochiu/Engine/Popochiu.tscn'

const CURSOR_TYPE := preload('res://addons/Popochiu/Engine/Cursor/Cursor.gd').Type
