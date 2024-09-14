@tool
class_name PopochiuDialogOption
extends Resource
## Each of the options in a [PopochiuDialog].

## The identifier of the option. Use it when scripting.
@export var id := "" : set = set_id
## The text to show on screen for the option.
@export var text := ""
## The icon to show on screen for the option.
#@export var icon: Texture = null
## Whether this option is visible.
@export var visible := true
## Whether this option is disabled. If [code]true[/code], the option won´t be rendered.
@export var disabled := false
## Whether this option should be [b]always[/b] rendered as not previously selected.
@export var always_on := false

## Stores the same value of the [member id] property.
var script_name := ""
## Whether the option was already been selected. If [code]true[/code], then the option's
## [member text] will be shown different in the options menu, so players know they already clicked
## the option.
var used := false
## The number of times this options has been clicked.
var used_times := 0


#region Virtual ####################################################################################
## Called when the option is selected.
## [i]Virtual[/i].
func _on_selected() -> void:
	pass


#endregion

#region Public #####################################################################################
## Makes the option visible. Won´t work if the option is [member disabled].
func turn_on() -> void:
	if disabled: return
	
	visible = true
	used = false


## Makes the option invisible.
func turn_off() -> void:
	visible = false


## Disables the option by making [member disable] [code]true[/code].
func turn_off_forever() -> void:
	disabled = true


#endregion

#region SetGet #####################################################################################
func set_id(value: String) -> void:
	id = value
	
	script_name = id
	resource_name = id


#endregion
