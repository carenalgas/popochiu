@tool
class_name PopochiuPopup
extends PanelContainer
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

@export var closes_by_clicking_out := true
@export var script_name: StringName = ""
@export var title := "" : set = set_title

@onready var lbl_title: Label = %Title
@onready var btn_ok: Button = %Ok
@onready var btn_cancel: Button = %Cancel
@onready var btn_close: TextureButton = %Close


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	if not title.is_empty():
		lbl_title.text = title
	
	if Engine.is_editor_hint(): return
	
	# Connect to own signals
	gui_input.connect(_check_click)
	
	# Connect to child signals
	btn_ok.pressed.connect(on_ok_pressed)
	btn_cancel.pressed.connect(on_cancel_pressed)
	btn_close.pressed.connect(on_cancel_pressed)
	
	# Connect to singleton signals
	G.popup_requested.connect(_on_popup_requested)
	
	close()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
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


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
## Shows the popup scaling it and blocking interactions with the graphic interface.
func open() -> void:
	_open()
	
	# TODO: I'm not sure we should do this...
	if E.settings.scale_gui:
		scale = Vector2.ONE * E.scale
	
	G.block()
	Cursor.show_cursor("gui", true)
	
	(E.gi as PopochiuGraphicInterface).popups_stack.append(self)
	
	show()


## Closes the popup unlocking interactions with the graphic interface.
func close() -> void:
	(E.gi as PopochiuGraphicInterface).popups_stack.erase(self)
	
	if (E.gi as PopochiuGraphicInterface).popups_stack.is_empty():
		G.unblock()
		Cursor.unblock()
	
	_close()
	
	hide()


## Called when the OK button is pressed. It closes the popup afterwards.
func on_ok_pressed() -> void:
	_on_ok()
	
	close()


## Called when the CANCEL button is pressed. It closes the popup afterwards.
func on_cancel_pressed() -> void:
	_on_cancel()
	
	close()


## Called when the X (top-right corner) button is pressed. It closes the popup
## afterwards.
func on_close_pressed() -> void:
	_on_cancel()
	
	close()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SETGET ░░░░
func set_title(value: String) -> void:
	title = value
	
	if is_instance_valid(lbl_title):
		lbl_title.text = title


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
## Checks if the overlay area of the popup was clicked in order to close it.
func _check_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed()\
	and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT\
	and closes_by_clicking_out:
		_on_cancel()
		close()


func _on_popup_requested(popup_script_name: StringName) -> void:
	if popup_script_name == script_name:
		open()
