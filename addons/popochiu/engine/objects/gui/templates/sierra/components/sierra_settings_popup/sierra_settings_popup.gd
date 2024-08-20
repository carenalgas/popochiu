@tool
extends PopochiuPopup

signal option_selected(option_name)

@onready var save: Button = %Save
@onready var load: Button = %Load
@onready var sound: Button = %Sound
@onready var text: Button = %Text
@onready var quit: Button = %Quit


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	if Engine.is_editor_hint(): return
	
	# Connect to childrens' signals
	save.pressed.connect(_on_option_pressed.bind("save"))
	load.pressed.connect(_on_option_pressed.bind("load"))
	sound.pressed.connect(_on_option_pressed.bind("sound"))
	text.pressed.connect(_on_option_pressed.bind("text"))
	quit.pressed.connect(_on_option_pressed.bind("quit"))
	
	# Connect to autoloads signals
	# Fix #219: Close the popup whenever a slot is selected for saving or loading
	E.game_saved.connect(close)
	E.game_load_started.connect(close)
	
	if OS.has_feature("web"):
		quit.hide()


#endregion

#region Private ####################################################################################
func _on_option_pressed(option_name: String) -> void:
	option_selected.emit(option_name)


#endregion
