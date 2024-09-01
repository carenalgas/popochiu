@tool
extends "settings_bar_button.gd"

const TextSpeedOption = preload(
	PopochiuResources.GUI_TEMPLATES_FOLDER
	+ "simple_click/components/settings_bar/resources/text_speed_option.gd"
)

@export var speed_options: Array : set = set_speed_options

var _speed_idx := 0


#region Godot ######################################################################################
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	super()
	
	if speed_options.is_empty():
		hide()
	
	texture_normal = (speed_options[_speed_idx] as TextSpeedOption).icon


#endregion

#region Virtual ####################################################################################
func _on_pressed() -> void:
	_change_text_speed()
	G.show_hover_text(self.description)


#endregion

#region SetGet #####################################################################################
func get_description() -> String:
	if speed_options.is_empty() or Engine.is_editor_hint():
		return description
	
	return "%s: %s" % [description, (speed_options[_speed_idx] as TextSpeedOption).description]


func set_speed_options(value: Array) -> void:
	speed_options = value
	
	for idx in value.size():
		if not value[idx]:
			var x := TextSpeedOption.new()
			x.resource_name = "Speed %d" % idx
			
			value[idx] = x
	
	if speed_options.is_empty():
		texture_normal = null
	else:
		texture_normal = speed_options[0].icon


#endregion

#region Private ####################################################################################
## Changes the speed of the text in dialog lines looping through the values in
## [member PopochiuSettings.text_speeds].
func _change_text_speed() -> void:
	_speed_idx = wrapi(_speed_idx + 1, 0, speed_options.size())
	texture_normal = (speed_options[_speed_idx] as TextSpeedOption).icon
	E.text_speed = (speed_options[_speed_idx] as TextSpeedOption).speed


#endregion
