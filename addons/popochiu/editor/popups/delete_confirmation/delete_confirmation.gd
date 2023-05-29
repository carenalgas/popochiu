@tool
extends ConfirmationDialog

@onready var message: RichTextLabel = $VBoxContainer/Message
@onready var ask: RichTextLabel = $VBoxContainer/Extra/HBoxContainer/Ask


func _ready() -> void:
	PopochiuUtils.override_font(
		message, 'normal_font', get_theme_font("main", "EditorFonts")
	)
	PopochiuUtils.override_font(
		message, 'bold_font', get_theme_font("bold", "EditorFonts")
	)
	PopochiuUtils.override_font(
		message, 'mono_font', get_theme_font("source", "EditorFonts")
	)
	
	PopochiuUtils.override_font(
		ask, 'normal_font', get_theme_font("main", "EditorFonts")
	)
	PopochiuUtils.override_font(
		ask, 'bold_font', get_theme_font("bold", "EditorFonts")
	)
	PopochiuUtils.override_font(
		ask, 'mono_font', get_theme_font("source", "EditorFonts")
	)
