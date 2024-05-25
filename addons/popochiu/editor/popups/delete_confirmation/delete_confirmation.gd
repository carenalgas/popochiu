@tool
extends Control

var title := ""
var message := ""
var ask := ""
var on_confirmed: Callable
var on_canceled: Callable

@onready var message_rtl: RichTextLabel = %Message
@onready var extra: PanelContainer = %Extra
@onready var ask_rtl: RichTextLabel = %Ask
@onready var check_box: CheckBox = %CheckBox


#region Public #####################################################################################
func on_about_to_popup() -> void:
	PopochiuEditorHelper.override_font(message_rtl, "normal_font", "main")
	PopochiuEditorHelper.override_font(message_rtl, "bold_font", "bold")
	PopochiuEditorHelper.override_font(message_rtl, "mono_font", "source")
	PopochiuEditorHelper.override_font(ask_rtl, "normal_font", "main")
	PopochiuEditorHelper.override_font(ask_rtl, "bold_font", "bold")
	PopochiuEditorHelper.override_font(ask_rtl, "mono_font", "source")
	
	message_rtl.text = message
	ask_rtl.text = ask
	extra.visible = !ask.is_empty()


#endregion
