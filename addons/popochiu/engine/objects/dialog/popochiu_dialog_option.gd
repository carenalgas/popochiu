# @popochiu-docs-category game-objects
@tool
class_name PopochiuDialogOption
extends Resource
## Represents a single selectable option within a [PopochiuDialog].
##
## Options can be shown or hidden, enabled or disabled, and track whether they have been used.

## The identifier of the option. Use it when scripting.
@export var id := "" : set = set_id
## The text to show on screen for the option.
@export var text := ""
## The icon to show on screen for the option.
#@export var icon: Texture = null
## Whether this option is visible.
@export var visible := true
## Whether this option is disabled. If [code]true[/code], the option won't be rendered.
@export var disabled := false
## Whether this option should be [b]always[/b] rendered as not previously selected.
@export var always_on := false

## Stores the same value of the [member id] property.
var script_name := ""
## Whether the option has ever been selected. If [code]true[/code], the option's [member text] will
## be shown differently in the options menu to indicate it was already clicked.
var used := false
## The number of times this options has been clicked.
var used_times := 0


#region Virtual ####################################################################################
## Called when this option is selected.
func _on_selected() -> void:
	pass


#endregion

#region Public #####################################################################################
## Makes the option visible. Has no effect if the option is [member disabled].
func turn_on() -> void:
	if disabled: return
	
	visible = true
	used = false


## Makes the option invisible.
func turn_off() -> void:
	visible = false


## Disables the option permanently by setting [member disabled] to [code]true[/code].
func turn_off_forever() -> void:
	disabled = true


#endregion

#region SetGet #####################################################################################
func set_id(value: String) -> void:
	id = value
	
	script_name = id
	resource_name = id


func set_text(v):
	text = v


#func set_icon(v):
#	icon = v


func set_always_on(v):
	always_on = v


#endregion

#region Private ####################################################################################

# Used internally to populate a PopochiuDialogOption.
func configure(config: Dictionary) -> void:
	text = config.get("text", text)
#	icon = config.get("icon", icon)
	visible = config.get("visible", visible)
	disabled = config.get("disabled", disabled)
	always_on = config.get("always_on", always_on)

#endregion
