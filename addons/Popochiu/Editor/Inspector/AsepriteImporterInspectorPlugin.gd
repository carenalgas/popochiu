tool
extends EditorInspectorPlugin ## TODO: create a base class with pointer variables

const INSPECTOR_DOCK = preload("res://addons/Popochiu/Editor/Importers/Aseprite/docks/AnimationPlayerInspectorDock.tscn")
const CONFIG_SCRIPT = preload("res://addons/Popochiu/Editor/Config/Config.gd")

var ei: EditorInterface
var fs: EditorFileSystem
var config: Reference
var _target_node: Node
	
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func can_handle(object):
	if object.has_method("get_parent") and object.get_parent() is YSort:
		return false
	return object is PopochiuCharacter #|| object is PopochiuInventoryItem || object is PopochiuProp


func parse_begin(object):
	_target_node = object

func parse_category(object, category):
	if category == 'Aseprite':
		var dock = INSPECTOR_DOCK.instance()
		dock.target_node = _target_node
		dock.config = config
		dock.file_system = fs
		add_custom_control(dock)

func parse_property(object, type, path, hint, hint_text, usage):
	return path == 'popochiu_placeholder'
