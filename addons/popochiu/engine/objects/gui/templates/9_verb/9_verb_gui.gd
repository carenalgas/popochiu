class_name NineVerbGUI
extends PopochiuGraphicInterface
## Defines the behavior of the 9 Verbs GUI.
##
## In this GUI players interact with objects based on the ative command, which can be changed by
## clicking one of the nine buttons in the bottom panel. The inventory is always visible in the
## bottom right corner of the screen, and the settings popup can be opened using the button in the
## top right corner of the sceen.

signal settings_requested

# Used to go back to the WALK_TO command when hovering an inventory item without a verb selected
var _return_to_walk_to := false

## Used to access the [b]9VerbPanel[/b] component (the one at the bottom containing the verbs,
## the inventory, and the button to open the [b]9VerbSettingsPopup[/b].
@onready var _9_verb_panel: Control = %"9VerbPanel"
@onready var hover_text_cursor: Control = %HoverTextCursor
## Used to access the [b]9VerbSettingsPopup[/b] node.
@onready var settings_popup: PopochiuPopup = %"9VerbSettingsPopup"
@onready var save_and_load_popup: Control = %SaveAndLoadPopup
@onready var history_popup: Control = %HistoryPopup
## Used to access the [b]9VerbQuitPopup[/b] node.
@onready var quit_popup: PopochiuPopup = %"9VerbQuitPopup"


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	Cursor.replace_frames($Cursor)
	Cursor.show_cursor()
	
	$Cursor.hide()
	
	# Connect to own signals
	settings_requested.connect(_on_settings_requested)
	
	# Connect to childs signals
	settings_popup.classic_sentence_toggled.connect(_on_classic_sentence_toggled)
	settings_popup.option_selected.connect(_on_settings_option_selected)
	
	
	# Connect to singletons signals
	E.ready.connect(_on_popochiu_ready)


func _unhandled_input(event: InputEvent) -> void:
	# Make the PC move to the clicked point on RIGHT CLICK
	if PopochiuUtils.get_click_or_touch_index(event) == MOUSE_BUTTON_RIGHT:
		C.player.walk(R.current.get_local_mouse_position())


#endregion

#region Virtual ####################################################################################
## Called when the GUI is blocked. Makes the [member E.current_command] to be none of the available
## commands, hides the bottom panel and makes the GUI to stop processing unhandled input.
func _on_blocked(props := { blocking = true }) -> void:
	E.current_command = -1
	G.show_hover_text()
	_9_verb_panel.hide()
	
	set_process_unhandled_input(false)


## Called when the GUI is unblocked. Makes the [member E.current_command] to be
## [constant NineVerbCommands.WALK_TO], shows the bottom panel and makes the GUI to start processing
## unhandled input.
func _on_unblocked() -> void:
	if D.current_dialog:
		await get_tree().process_frame
		
		G.block()
		return
	
	E.current_command = NineVerbCommands.Commands.WALK_TO
	G.show_hover_text()
	_9_verb_panel.show()
	
	# Make all commands to look as no pressed
	_9_verb_panel.unpress_commands()
	
	set_process_unhandled_input(true)


## Called when [method G.show_system_text] is executed. Shows the [code]"wait"[/code] cursor.
func _on_system_text_shown(_msg: String) -> void:
	Cursor.show_cursor("wait")


## Called when [method G.show_system_text] is executed. Shows the [code]"normal"[/code] cursor.
func _on_system_text_hidden() -> void:
	Cursor.show_cursor()


## Called when the mouse enters (hovers) [param clickable]. It displays a text with the
## [member PopochiuClickable.description] in the [HoverText] component and shows the
## [code]"active"[/code] cursor.
func _on_mouse_entered_clickable(clickable: PopochiuClickable) -> void:
	if G.is_blocked: return
	
	if clickable.get("suggested_command"):
		_9_verb_panel.highlight_command(clickable.suggested_command)
	
	if I.active:
		_show_command_on(I.active.description, clickable.description)
	else:
		G.show_hover_text(clickable.description)


## Called when the mouse exits [param clickable]. Clears the text in the [HoverText] component and
## shows the [code]"normal"[/code] cursor.
func _on_mouse_exited_clickable(clickable: PopochiuClickable) -> void:
	if G.is_blocked: return
	
	if clickable.get("suggested_command"):
		_9_verb_panel.highlight_command(clickable.suggested_command, false)
	Cursor.show_cursor()
	
	if I.active:
		_show_command_on(I.active.description)
		return
	
	G.show_hover_text()


## Called when the mouse enters (hovers) [param inventory_item]. It displays a text with the
## [member PopochiuInventoryItem.description] in the [HoverText] component and shows the
## [code]"active"[/code] cursor.
func _on_mouse_entered_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	if E.current_command == NineVerbCommands.Commands.WALK_TO:
		_return_to_walk_to = true
		E.current_command = NineVerbCommands.Commands.USE
	
	_9_verb_panel.highlight_command(NineVerbCommands.Commands.LOOK_AT)
	Cursor.show_cursor()
	
	if I.active:
		_show_command_on(I.active.description, inventory_item.description)
	else:
		G.show_hover_text(inventory_item.description)


## Called when the mouse exits [param inventory_item]. Clears the text in the [HoverText] component and
## shows the [code]"normal"[/code] cursor.
func _on_mouse_exited_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	if not I.active and _return_to_walk_to:
		E.current_command = NineVerbCommands.Commands.WALK_TO
		_return_to_walk_to = false
	
	_9_verb_panel.highlight_command(NineVerbCommands.Commands.LOOK_AT, false)
	Cursor.show_cursor()
	
	if I.active:
		_show_command_on(I.active.description)
		return
	
	G.show_hover_text()


## Called when a dialogue line starts. It shows the [code]"wait"[/code] cursor.
func _on_dialog_line_started() -> void:
	Cursor.show_cursor("wait")


## Called when a dialogue line finishes. It shows the [code]"gui"[/code] cursor if there is an
## active [PopochiuDialog], otherwise it shows the [code]"normal"[/code] cursor.
func _on_dialog_line_finished() -> void:
	Cursor.show_cursor("gui" if D.current_dialog else "normal")


## Called when a [PopochiuDialog] starts. It shows the [code]"gui"[/code] cursor.
func _on_dialog_started(_dialog: PopochiuDialog) -> void:
	Cursor.show_cursor("gui")


## Called when the running [PopochiuDialog] shows its options on screen. It shows the
## [code]"gui"[/code] cursor.
func _on_dialog_options_shown() -> void:
	Cursor.unblock()
	Cursor.show_cursor("gui")


## Called when a [PopochiuDialog] finishes. It shows the [code]"normal"[/code] cursor.
func _on_dialog_finished(_dialog: PopochiuDialog) -> void:
	Cursor.show_cursor()


## Called when [param item] is selected in the inventory (i.e. by clicking it). For this GUI, this
## will only occur when the current command is [constant NineVerbCommands.USE].
func _on_inventory_item_selected(item: PopochiuInventoryItem) -> void:
	if not item:
		E.current_command = NineVerbCommands.Commands.WALK_TO
		G.show_hover_text()
	else:
		_show_command_on(item.description)


## Called when the game is saved. By default, it shows [code]Game saved[/code] in the SystemText
## component.
func _on_game_saved() -> void:
	G.show_system_text("Game saved")


## Called when a game is loaded. [param loaded_game] has the loaded data. By default, it shows
## [code]Game loaded[/code] in the SystemText component.
func _on_game_loaded(loaded_game: Dictionary) -> void:
	await G.show_system_text("Game loaded")
	
	super(loaded_game)


#endregion

#region Private ####################################################################################
func _on_popochiu_ready() -> void:
	if is_instance_valid(C.player):
		C.player.started_walk_to.connect(_on_player_started_walk)


func _on_settings_requested() -> void:
	settings_popup.open()


func _on_player_started_walk(
	_character: PopochiuCharacter, _start_position: Vector2, _end_position: Vector2
) -> void:
	_on_unblocked()


func _on_classic_sentence_toggled(button_pressed: bool) -> void:
	hover_text_cursor.visible = not button_pressed
	_9_verb_panel.hover_text_centered.visible = button_pressed


func _on_settings_option_selected(option_name: String) -> void:
	match option_name:
		"save":
			save_and_load_popup.open_save()
		"load":
			save_and_load_popup.open_load()
		"history":
			history_popup.open()
		"quit":
			quit_popup.open()


func _show_command_on(item_1_name: String, item_2_name := "") -> void:
	var preposition = "on"
	if E.current_command == NineVerbCommands.Commands.GIVE:
		preposition = "to"
	G.show_hover_text("%s %s %s %s" % [
		E.get_current_command_name(), item_1_name, preposition, item_2_name
	])


#endregion
