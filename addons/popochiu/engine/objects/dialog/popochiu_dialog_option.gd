@tool
class_name PopochiuDialogOption
extends Resource
# Each option in a dialog.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

@export var id := '' : set = set_id
@export var text := ''
@export var visible := true
@export var disabled := false
@export var always_on := false

# TODO: Store the localization code
var script_name := ''
var used := false
var used_times := 0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _on_selected() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func turn_on() -> void:
	if disabled: return
	
	visible = true
	used = false


func turn_off() -> void:
	visible = false


func turn_off_forever() -> void:
	disabled = true


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_id(value: String) -> void:
	id = value
	script_name = id
	resource_name = id
	
	notify_property_list_changed()
