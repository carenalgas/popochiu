extends Control
class_name PopochiuGraphicInterface
## Handles the in-game Graphic Interface.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

var popups_stack := []


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	# Connect to singleton signals
	G.blocked.connect(_on_blocked)
	G.unblocked.connect(_on_unblocked)
	G.hidden.connect(_on_hidden)
	G.shown.connect(_on_shown)
	G.system_text_shown.connect(_on_system_text_shown)
	G.system_text_hidden.connect(_on_system_text_hidden)
	G.mouse_entered_clickable.connect(_on_mouse_entered_clickable)
	G.mouse_exited_clickable.connect(_on_mouse_exited_clickable)
	G.mouse_entered_inventory_item.connect(_on_mouse_entered_inventory_item)
	G.mouse_exited_inventory_item.connect(_on_mouse_exited_inventory_item)
	G.dialog_line_started.connect(_on_dialog_line_started)
	G.dialog_line_finished.connect(_on_dialog_line_finished)
	D.dialog_started.connect(_on_dialog_started)
	D.dialog_finished.connect(_on_dialog_finished)
	I.item_selected.connect(_on_inventory_item_selected)
	
#	if E.settings.scale_gui:
#		$MainContainer.scale = E.scale


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
#region virtual
## Called when the GUI is blocked and not intended to handle input events.
func _on_blocked(props := { blocking = true }) -> void:
	pass


## Called when the GUI is unblocked and can handle input events again.
func _on_unblocked() -> void:
	pass


## Called to hide the GUI.
func _on_hidden() -> void:
	pass


## Called to show the GUI.
func _on_shown() -> void:
	pass


## Called when G.show_system_text() is triggered. Shows `msg` in the SystemText
## component.
func _on_system_text_shown(msg: String) -> void:
	pass


## Called once the player closes the SystemText component (by clicking the screen
## anywhere).
func _on_system_text_hidden() -> void:
	pass


## Called when the mouse enters (hover) a `clickable`.
func _on_mouse_entered_clickable(clickable: PopochiuClickable) -> void:
	pass


## Called when the mouse exits a `clickable`.
func _on_mouse_exited_clickable(clickable: PopochiuClickable) -> void:
	pass


## Called when the mouse enters (hover) an `inventory_item`.
func _on_mouse_entered_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	pass


## Called when the mouse exits an `inventory_item`.
func _on_mouse_exited_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	pass


## Called when a dialog line is said be a `PopochiuCharacter` (this is when
## `PopochiuCharacter.say()` is called.
func _on_dialog_line_started() -> void:
	pass


## Called when a dialog line finishes (this is after players click the screen
## anywhere to make the dialog line dissapear).
func _on_dialog_line_finished() -> void:
	pass


## Called when a `dialog` starts (afet calling `PopochiuDialog.start()`).
func _on_dialog_started(dialog: PopochiuDialog) -> void:
	pass


## Called when a `dialog` finishes (after calling `PopochiuDialog.stop()`).
func _on_dialog_finished(dialog: PopochiuDialog) -> void:
	pass


## Called when an `item` in the inventory is selected (i.e. by clicking it).
func _on_inventory_item_selected(item: PopochiuInventoryItem) -> void:
	pass


#endregion
