tool
extends VBoxContainer

# Node references
onready var code_input : TextEdit = $CodeText
onready var copy_code_button : Button = $CopyCodeButton

# Public variables
var code_text : String = "" setget set_code_text

func _ready() -> void:
	copy_code_button.connect("pressed", self, "_on_copy_button_pressed")

# Properties
func set_code_text(value : String) -> void:
	code_input.text = value
	copy_code_button.icon = null

# Handlers
func _on_copy_button_pressed() -> void:
	var copied_text = code_input.text.strip_edges()
	if (copied_text.empty()):
		return
	
	OS.clipboard = copied_text
	copy_code_button.icon = get_icon("StatusSuccess", "EditorIcons")
