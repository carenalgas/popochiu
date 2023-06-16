extends EditorInspectorPlugin ## TODO: create a base class with pointer variables

const INSPECTOR_DOCK = preload("res://addons/popochiu/editor/importers/aseprite/docks/animation_player_inspector_dock.tscn")
const CONFIG_SCRIPT = preload("res://addons/popochiu/editor/config/config.gd")

var ei: EditorInterface
var fs: EditorFileSystem
var config: RefCounted
var _target_node: Node
	
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _can_handle(object):
	if object.has_method("get_parent") and object.get_parent() is Node2D:
		return false
	return object is PopochiuCharacter #|| object is PopochiuInventoryItem || object is PopochiuProp


func _parse_begin(object):
	_target_node = object

func _parse_category(object, category):
	if category == 'Aseprite':
		var dock = INSPECTOR_DOCK.instantiate()
		dock.target_node = object
		dock.config = config
		dock.file_system = fs
		add_custom_control(dock)

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	return name == 'popochiu_placeholder'
