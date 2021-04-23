tool
extends Container


onready var options : Container = $Options


const PROP_TO_COLOR_MENU := {
	frame_border = "FrameBorder",
	selection_border = "SelectionBorder",
	texture_background = "TextureBackground",
	inspector_background = "InspectorBackground",
}

const DEFAULT_SETTINGS :={
	frame_border = {
		color = Color("#808080"),
		visibility = true,
	},
	selection_border = {
		color = Color.yellow,
		visibility = true,
	},
	texture_background = {
		color = Color("#404040"),
		visibility = true,
	},
	inspector_background = {
		color = Color.black,
	},
}


var settings := DEFAULT_SETTINGS.duplicate(true) setget set_settings


signal settings_changed(settings)


func _ready():
	for property in PROP_TO_COLOR_MENU:
		var node_name : String = PROP_TO_COLOR_MENU[property]
		var color_menu = options.get_node(node_name)

		color_menu.set_meta("property", property)

		color_menu.connect("property_changed", self, "_on_ColorMenuItem_property_changed")


# Setters and Getters
func set_settings(new_settings : Dictionary) -> void:
	if new_settings:
		settings = new_settings
	else:
		settings = DEFAULT_SETTINGS.duplicate(true)

	for property in PROP_TO_COLOR_MENU:
		var node_name : String = PROP_TO_COLOR_MENU[property]
		var color_menu = options.get_node(node_name)

		color_menu.color_value = settings[property].color
		color_menu.visibility = settings[property].get("visibility", false)

	emit_signal("settings_changed", settings)


# Signal Callbacks
func _on_ColorMenuItem_property_changed(color_menu_item : Node) -> void:
	var property : String = color_menu_item.get_meta("property")

	settings[property]["color"] = color_menu_item.color_value
	settings[property]["visibility"] = color_menu_item.visibility

	emit_signal("settings_changed", settings)
