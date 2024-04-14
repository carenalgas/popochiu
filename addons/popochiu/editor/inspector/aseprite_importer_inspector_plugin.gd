extends EditorInspectorPlugin ## TODO: create a base class with pointer variables

const DOCKS_PATH := "res://addons/popochiu/editor/importers/aseprite/docks/"
const INSPECTOR_DOCK = preload(DOCKS_PATH + "aseprite_importer_inspector_dock.tscn")
const CONFIG_SCRIPT = preload("res://addons/popochiu/editor/config/config.gd")
const INSPECTOR_DOCK_CHARACTER := DOCKS_PATH + "aseprite_importer_inspector_dock_character.gd"
const INSPECTOR_DOCK_ROOM := DOCKS_PATH + "aseprite_importer_inspector_dock_room.gd"

var main_dock: Panel
var _target_node: Node


#region Virtual ####################################################################################
func _can_handle(object):
	if object.has_method("get_parent") and object.get_parent() is Node2D:
		return false
	
	return object is PopochiuCharacter || object is PopochiuRoom #|| object is PopochiuInventoryItem


func _parse_begin(object: Object):
	_target_node = object


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if name != 'popochiu_placeholder': return false

	# Instanciate and configure the dock
	var dock = INSPECTOR_DOCK.instantiate()

	# Load the specific script in the dock
	if object is PopochiuCharacter:
		dock.set_script(load(INSPECTOR_DOCK_CHARACTER))
	if object is PopochiuRoom:
		dock.set_script(load(INSPECTOR_DOCK_ROOM))

	dock.target_node = object
	dock.file_system = EditorInterface.get_resource_filesystem()
	dock.main_dock = main_dock # TODO: change for SignalBus

	# Add the dock to the inspector
	add_custom_control(dock)
	return true


#endregion
