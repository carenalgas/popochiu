@tool
extends PopochiuPopup

signal option_selected(option_name: String)
signal classic_sentence_toggled(pressed: bool)

@onready var classic_sentence: CheckButton = %ClassicSentence
@onready var save_btn: Button = %Save
@onready var load_btn: Button = %Load
@onready var history_btn: Button = %History
@onready var quit_btn: Button = %Quit


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	if Engine.is_editor_hint(): return
	
	# Connect to child signals
	save_btn.pressed.connect(option_selected.emit.bind("save"))
	load_btn.pressed.connect(option_selected.emit.bind("load"))
	history_btn.pressed.connect(option_selected.emit.bind("history"))
	quit_btn.pressed.connect(option_selected.emit.bind("quit"))
	classic_sentence.toggled.connect(_on_classic_sentence_toggled)
	
	# Connect to autoloads signals
	# Fix #219: Close the popup whenever a slot is selected for saving or loading
	PopochiuUtils.e.game_saved.connect(close)
	PopochiuUtils.e.game_load_started.connect(close)
	
	if OS.has_feature("web"):
		quit_btn.hide()


#endregion

#region Private ####################################################################################
func _on_classic_sentence_toggled(button_pressed: bool) -> void:
	classic_sentence_toggled.emit(button_pressed)


#endregion
