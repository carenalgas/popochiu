tool
extends VBoxContainer

signal filesystem_changed()

# Public properties
var icon_name: String = "" setget set_icon_name
var type_name: String = "" setget set_type_name

# Node references
onready var save_button: Button = $SaveButton
onready var save_dialog: FileDialog = $SaveDialog
onready var status_message: Label = $Message

func _ready() -> void:	
	connect("visibility_changed", self, "_clear_status")
	save_button.connect("pressed", self, "_on_save_button_pressed")
	save_dialog.connect("file_selected", self, "_on_file_selected")

# Properties
func set_icon_name(value : String) -> void:
	icon_name = value
	_clear_status()

func set_type_name(value : String) -> void:
	type_name = value
	_clear_status()

# Helpers
func _show_status(success : bool, message : String = "") -> void:
	if (!is_inside_tree() || !Engine.editor_hint):
		return
	
	if (success):
		save_button.icon = get_icon("StatusSuccess", "EditorIcons")
	else:
		save_button.icon = get_icon("StatusError", "EditorIcons")
	
	if (message):
		status_message.text = message
		if (success):
			status_message.add_color_override("font_color", get_color("font_color", "Label"))
		else:
			status_message.add_color_override("font_color", get_color("error_color", "Editor"))
		
		status_message.show()
	else:
		status_message.hide()

func _clear_status() -> void:
	if (!is_inside_tree() || !Engine.editor_hint):
		return
	
	save_button.icon = null
	status_message.hide()

# Handlers
func _on_save_button_pressed() -> void:
	if (icon_name):
		save_dialog.current_file = "%s.png" % icon_name
	save_dialog.popup_centered()

func _on_file_selected(path: String) -> void:
	if (!has_icon(icon_name, type_name)):
		_show_status(false, "Can't load icon. Is a valid icon selected?")
		return
	
	var unique_icon := get_icon(icon_name, type_name).duplicate(true)
	var error = ResourceSaver.save(path, unique_icon)
	if (error != OK):
		_show_status(false, "Error while saving icon.")
		return
	
	_show_status(true)
	emit_signal("filesystem_changed")
