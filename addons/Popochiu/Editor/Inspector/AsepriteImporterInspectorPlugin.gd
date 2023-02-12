tool
extends EditorInspectorPlugin

const INSPECTOR_DOCK = preload("../Importers/Aseprite/docks/animation_player_inspector_dock.tscn")
const CONFIG_SCRIPT = preload("../Importers/Aseprite/config/config.gd")

var ei: EditorInterface
var file_system: EditorFileSystem
var _target_node: Node
## TODO: this should be passed over by the general plugin BUT better to move this stuff with Popochiu default config
var config := CONFIG_SCRIPT.new()


func can_handle(object):
	return object is PopochiuCharacter # || object is PopochiuInventoryItem || object is PopochiuProp


func parse_begin(object):
	_target_node = object


func parse_end():
	var dock = INSPECTOR_DOCK.instance()
	dock.target_node = _target_node
	dock.config = config
	dock.file_system = file_system
	add_custom_control(dock)
