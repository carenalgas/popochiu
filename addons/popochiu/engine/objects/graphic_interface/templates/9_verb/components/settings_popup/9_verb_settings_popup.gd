extends PopochiuPopup

signal quit_pressed
signal classic_sentence_toggled(pressed)

@onready var save: Button = %Save
@onready var load: Button = %Load
@onready var history: Button = %History
@onready var quit: Button = %Quit


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	
	# Connect to child signals
	save.pressed.connect(_on_save_pressed)
	load.pressed.connect(_on_load_pressed)
	history.pressed.connect(_on_history_pressed)
	quit.pressed.connect(_on_quit_pressed)
	%ClassicSentence.toggled.connect(_on_classic_sentence_toggled)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _on_save_pressed() -> void:
	G.show_save()


func _on_load_pressed() -> void:
	G.show_load()


func _on_history_pressed() -> void:
	G.show_history()


func _on_quit_pressed() -> void:
	quit_pressed.emit()


func _on_classic_sentence_toggled(button_pressed: bool) -> void:
	classic_sentence_toggled.emit(button_pressed)
