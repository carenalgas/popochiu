extends "../popochiu_popup.gd"

signal quit_pressed

@onready var save: Button = %Save
@onready var load: Button = %Load
@onready var history: Button = %History
@onready var quit: Button = %Quit


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Connect to child signals
	save.pressed.connect(_on_save_pressed)
	load.pressed.connect(_on_load_pressed)
	history.pressed.connect(_on_history_pressed)
	quit.pressed.connect(_on_quit_pressed)


#endregion

#region Virtual ####################################################################################
## Called when the popup is opened. At this point it is not visible yet.
func _open() -> void:
	pass


## Called when the popup is closed. The node hides after calling this method.
func _close() -> void:
	pass


## Called when OK is pressed.
func _on_ok() -> void:
	pass


## Called when CANCEL or X (top-right corner) are pressed.
func _on_cancel() -> void:
	pass


#endregion

#region Private ####################################################################################
func _on_save_pressed() -> void:
	G.show_save()


func _on_load_pressed() -> void:
	G.show_load()


func _on_history_pressed() -> void:
	G.show_history()


func _on_quit_pressed() -> void:
	close()
	quit_pressed.emit()


#endregion
