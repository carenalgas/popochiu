tool
extends Resource
# Each option in a dialog.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

export var id := '' setget _set_id
export var text := ''
export var visible := true

# TODO: Store the localization code
var description := ''
var disabled := false
var used := false
var script_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func turn_on() -> void:
	visible = true


func turn_off() -> void:
	visible = false


func turn_off_forever() -> void:
	# TODO: Implement functionality
	pass


func hide_forever() -> void:
	# TODO: Implement functionality
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _on_interacted() -> void:
	pass


func _on_interaction_canceled() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _set_id(value: String) -> void:
	id = value
	script_name = id
	resource_name = id
	
	property_list_changed_notify()
