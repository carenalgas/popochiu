class_name ToolbarButton
extends TextureButton

export var description := '' setget ,_get_description
export var script_name := ''
export(Cursor.Type) var cursor


func _get_description() -> String:
	return description
