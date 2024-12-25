class_name PopochiuGraphicInterface
extends Control
## Handles the in-game Graphic Interface.
##
## You can extend this class to create your own GUI, or use one of the built-in templates for:
## 2-click context-sensitive, 9 verbs and Sierra style.

## Stack of opened popups.
var popups_stack := []
## Whether a dialog line is being displayed.
var is_showing_dialog_line := false

var _components_map := {}


#region Godot ######################################################################################
func _ready():
	for node: Control in (
		get_tree().get_nodes_in_group("popochiu_gui_component")
		+ get_tree().get_nodes_in_group("popochiu_gui_popup")
	):
		_components_map[node.name] = node
	
	# Connect to singleton signals
	PopochiuUtils.g.blocked.connect(_on_blocked)
	PopochiuUtils.g.unblocked.connect(_on_unblocked)
	PopochiuUtils.g.hidden.connect(on_hidden)
	PopochiuUtils.g.shown.connect(on_shown)
	PopochiuUtils.g.system_text_shown.connect(_on_system_text_shown)
	PopochiuUtils.g.system_text_hidden.connect(_on_system_text_hidden)
	PopochiuUtils.g.mouse_entered_clickable.connect(_on_mouse_entered_clickable)
	PopochiuUtils.g.mouse_exited_clickable.connect(_on_mouse_exited_clickable)
	PopochiuUtils.g.mouse_entered_inventory_item.connect(_on_mouse_entered_inventory_item)
	PopochiuUtils.g.mouse_exited_inventory_item.connect(_on_mouse_exited_inventory_item)
	PopochiuUtils.g.dialog_line_started.connect(_on_dialog_line_started)
	PopochiuUtils.g.dialog_line_finished.connect(_on_dialog_line_finished)
	PopochiuUtils.d.dialog_started.connect(_on_dialog_started)
	PopochiuUtils.g.dialog_options_shown.connect(_on_dialog_options_shown)
	PopochiuUtils.d.dialog_finished.connect(_on_dialog_finished)
	PopochiuUtils.i.item_selected.connect(_on_inventory_item_selected)
	PopochiuUtils.e.game_saved.connect(_on_game_saved)
	PopochiuUtils.e.game_loaded.connect(_on_game_loaded)
	
	if PopochiuUtils.e.settings.is_pixel_art_game:
		# Apply this filter so the font doesn't blur
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	if PopochiuUtils.e.settings.scale_gui:
		size = get_viewport_rect().size / PopochiuUtils.e.scale
		scale = PopochiuUtils.e.scale
		
		# Adjust nodes with a "text" property that is a String in order to try to prevent glitches
		# when rendering its font
		_adjust_nodes_text(get_children())


#endregion

#region Virtual ####################################################################################
## Called when the GUI is blocked and not intended to handle input events.
func _on_blocked(props := { blocking = true }) -> void:
	pass


## Called when the GUI is unblocked and can handle input events again.
func _on_unblocked() -> void:
	pass


## Called when the GUI is hidden.
func _on_hidden() -> void:
	pass


## Called when the GUI is shown.
func _on_shown() -> void:
	pass


## Called when [method G.show_system_text] is executed. Shows [param msg] in the [SystemText]
## component.
func _on_system_text_shown(msg: String) -> void:
	pass


## Called once the player closes the [SystemText] component by default when clicking anywhere on the
## screen.
func _on_system_text_hidden() -> void:
	pass


## Called when the mouse enters (hovers) [param clickable].
func _on_mouse_entered_clickable(clickable: PopochiuClickable) -> void:
	pass


## Called when the mouse exits [param clickable].
func _on_mouse_exited_clickable(clickable: PopochiuClickable) -> void:
	pass


## Called when the mouse enters (hovers) [param inventory_item].
func _on_mouse_entered_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	pass


## Called when the mouse exits [param inventory_item].
func _on_mouse_exited_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	pass


## Called when a dialog line is said by a [PopochiuCharacter] (this is when
## [method PopochiuCharacter.say] is called.
func _on_dialog_line_started() -> void:
	pass


## Called when a dialog line said by a [PopochiuCharacter] finishes (this is after players click the
## screen anywhere to make the dialog line disappear).
func _on_dialog_line_finished() -> void:
	pass


## Called when [param dialog] starts (this is after calling [method PopochiuDialog.start]).
func _on_dialog_started(dialog: PopochiuDialog) -> void:
	pass


## Called when the running [PopochiuDialog] shows its options on screen.
func _on_dialog_options_shown() -> void:
	pass


## Called when [param dialog] finishes (this is afet calling [method PopochiuDialog.stop]).
func _on_dialog_finished(dialog: PopochiuDialog) -> void:
	pass


## Called when [param item] is selected in the inventory (i.e. by clicking it).
func _on_inventory_item_selected(item: PopochiuInventoryItem) -> void:
	pass


## Called when the game is saved. By default, it shows [code]Game saved[/code] in the SystemText
## component.
func _on_game_saved() -> void:
	pass


## Called when a game is loaded. [param loaded_game] has the loaded data. By default, this emits
## the [signal G.load_feedback_finished] signal.
func _on_game_loaded(loaded_game: Dictionary) -> void:
	PopochiuUtils.g.load_feedback_finished.emit()


## Called by [b]cursor.gd[/b] to get the name of the cursor texture to show.
func _get_cursor_name() -> String:
	return ""


#endregion

#region Public #####################################################################################
## Returns the GUI component which [member Node.name] matches [param component_name].
## GUI components are those nodes that are in any of this groups:
## [code]popochiu_gui_component[/code] and [code]popochiu_gui_popup[/code].
func get_component(component_name: String) -> Control:
	if _components_map.has(component_name):
		return _components_map[component_name]
	else:
		PopochiuUtils.print_warning("No GUI component with name %s" % component_name)
	
	return null


## Returns the name of the cursor texture to show. [code]"normal"[/code] is returned by default.
func get_cursor_name() -> String:
	return "normal" if _get_cursor_name().is_empty() else _get_cursor_name()


func on_hidden() -> void:
	hide()
	_on_hidden()


func on_shown() -> void:
	show()
	_on_shown()


#endregion

#region Private ####################################################################################
func _adjust_nodes_text(nodes_array: Array) -> void:
	for node: Node in nodes_array:
		_adjust_nodes_text(node.get_children())
		if not node.get("text") or not typeof(node.get("text")) == TYPE_STRING: continue
		if node.text.length() % 2 != 0:
			node.text += " "


#endregion
