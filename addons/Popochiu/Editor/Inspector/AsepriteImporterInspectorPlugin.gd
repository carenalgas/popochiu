tool
extends EditorInspectorPlugin

const INSPECTOR_DOCK = preload("../Importers/Aseprite/docks/animation_player_inspector_dock.tscn")

var ei: EditorInterface
var file_system: EditorFileSystem
var settings = PopochiuResources.SETTINGS
var _target_node: Node
#var config


func can_handle(object):
	return object is PopochiuCharacter # || object is PopochiuInventoryItem || object is PopochiuProp


func parse_begin(object):
	_target_node = object


func parse_end():
	var dock = INSPECTOR_DOCK.instance()
	dock.target_node = _target_node
	dock.settings = settings
	dock.file_system = file_system
	add_custom_control(dock)
