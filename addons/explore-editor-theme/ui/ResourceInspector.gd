tool
extends VBoxContainer

# Public proprrties
export var inspected_resource : Resource

# Private properties
var _editor_plugin : EditorPlugin

onready var inspect_button : Button = $InspectButton

func _ready() -> void:
	_editor_plugin = null
	var parent = get_parent()
	while (parent):
		if (parent.get("editor_plugin")):
			_editor_plugin = parent.get("editor_plugin")
			break
		
		parent = parent.get_parent()
	
	inspect_button.connect("pressed", self, "_on_inspect_pressed")

func _on_inspect_pressed() -> void:
	if (!inspected_resource):
		return
	
	if (_editor_plugin):
		# Make sure we aren't actually editing the resource in use, as that can create problems.
		_editor_plugin.get_editor_interface().edit_resource(inspected_resource.duplicate())
