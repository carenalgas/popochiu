class_name SimpleClickGUI
extends PopochiuGraphicInterface
## Defines the behavior of the 2-click Context-sensitive GUI.
##
## In this GUI, players interact with objects in the game based on the clicked mouse button. The
## inventory bar is in the top left corner of the screen, and the settings bar is in the top right
## corner of the screen.

@onready var settings_bar: Control = %SettingsBar
@onready var save_and_load_popup: Control = %SaveAndLoadPopup
@onready var text_settings_popup: Control = %TextSettingsPopup
@onready var sound_settings_popup: Control = %SoundSettingsPopup
@onready var history_popup: Control = %HistoryPopup
@onready var quit_popup: Control = %QuitPopup


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Connect to children's signals
	settings_bar.option_selected.connect(_on_settings_option_selected)
	
	# Connect to autoloads' signals
	PopochiuUtils.cursor.replace_frames($Cursor)
	PopochiuUtils.cursor.show_cursor()
	
	$Cursor.hide()


#endregion

#region Virtual ####################################################################################
## Called when the GUI is blocked and not intended to handle input events.
func _on_blocked(props := { blocking = true }) -> void:
	PopochiuUtils.cursor.show_cursor("wait")
	PopochiuUtils.cursor.is_blocked = true


## Called when the GUI is unblocked and can handle input events again.
func _on_unblocked() -> void:
	PopochiuUtils.cursor.is_blocked = false
	
	if PopochiuUtils.i.active:
		PopochiuUtils.cursor.hide_main_cursor()
		PopochiuUtils.cursor.show_secondary_cursor()
	elif PopochiuUtils.e.hovered:
		# Fixes #315 by showing the right cursor when it is over a PopochiuClickable after closing
		# the SystemText component
		PopochiuUtils.cursor.show_cursor(
			PopochiuUtils.cursor.get_type_name(PopochiuUtils.e.hovered.cursor)
		)
	else:
		PopochiuUtils.cursor.show_cursor(get_cursor_name())


## Called when a text is shown in the [SystemText] component. This erases the text in the
## [HoverText] component and shows the [code]"wait"[/code] cursor.
func _on_system_text_shown(msg: String) -> void:
	PopochiuUtils.g.show_hover_text()
	PopochiuUtils.cursor.show_cursor("wait", true)


## Called when the [SystemText] component hides. If an [PopochiuInventoryItem] is active, the cursor
## takes its texture, otherwise it takes its default one.
func _on_system_text_hidden() -> void:
	if PopochiuUtils.i.active:
		PopochiuUtils.cursor.hide_main_cursor()
		PopochiuUtils.cursor.show_secondary_cursor()
	else:
		PopochiuUtils.cursor.show_cursor()


## Called when the mouse enters (hovers) [param clickable]. It changes the texture of the cursor
## and displays a message with the [member PopochiuClickable.description] on the [HoverText]
## component.
func _on_mouse_entered_clickable(clickable: PopochiuClickable) -> void:
	if PopochiuUtils.g.is_blocked: return
	
	if not (PopochiuUtils.i.active or is_showing_dialog_line):
		PopochiuUtils.cursor.show_cursor(PopochiuUtils.cursor.get_type_name(clickable.cursor))
	if not PopochiuUtils.i.active:
		PopochiuUtils.g.show_hover_text(clickable.description)
	else:
		PopochiuUtils.g.show_hover_text(
			'Use %s with %s' % [PopochiuUtils.i.active.description, clickable.description]
		)


## Called when the mouse exits [param clickable]. Clears the text in the [HoverText] component and
## shows the default cursor texture if there is no [PopochiuInventoryItem] active.
func _on_mouse_exited_clickable(clickable: PopochiuClickable) -> void:
	PopochiuUtils.g.show_hover_text()
	
	if PopochiuUtils.i.active or is_showing_dialog_line: return
	
	PopochiuUtils.cursor.show_cursor("gui" if PopochiuUtils.d.current_dialog else "normal")


## Called when the mouse enters (hovers) [param inventory_item]. It changes the texture of the
## cursor and displays a message with the [member PopochiuInventoryItem.description] on the
## [HoverText] component.
func _on_mouse_entered_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	if PopochiuUtils.g.is_blocked: return
	
	if not PopochiuUtils.i.active:
		PopochiuUtils.cursor.show_cursor(PopochiuUtils.cursor.get_type_name(inventory_item.cursor))
		PopochiuUtils.g.show_hover_text(inventory_item.description)
	elif PopochiuUtils.i.active != inventory_item:
		PopochiuUtils.g.show_hover_text(
			'Use %s with %s' % [PopochiuUtils.i.active.description, inventory_item.description]
		)
	else:
		PopochiuUtils.g.show_hover_text(inventory_item.description)


## Called when the mouse exits [param inventory_item]. Clears the text in the [HoverText] component
## and shows the default cursor texture if there is no [PopochiuInventoryItem] active.
func _on_mouse_exited_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	if PopochiuUtils.g.is_blocked: return
	
	PopochiuUtils.g.show_hover_text()
	
	if PopochiuUtils.i.active or $SettingsBar.is_open(): return
	
	PopochiuUtils.cursor.show_cursor()


## Called when a dialog line starts. It shows the [code]"wait"[/code] cursor.
func _on_dialog_line_started() -> void:
	is_showing_dialog_line = true
	
	PopochiuUtils.cursor.show_cursor("wait")


## Called when a dialog line finishes. It shows the [code]"normal"[/code] cursor if there is no
## [PopochiuDialog] active, otherwise shows the [code]"use"[/code] cursor.
func _on_dialog_line_finished() -> void:
	is_showing_dialog_line = false
	
	if PopochiuUtils.d.current_dialog:
		PopochiuUtils.cursor.show_cursor("gui")
	elif PopochiuUtils.e.hovered:
		PopochiuUtils.cursor.show_cursor(
			PopochiuUtils.cursor.get_type_name(PopochiuUtils.e.hovered.cursor)
		)
	else:
		PopochiuUtils.cursor.show_cursor("normal")


## Called when a [PopochiuDialog] starts. It shows the [code]"use"[/code] cursor and clears the
## [HoverText] component.
func _on_dialog_started(dialog: PopochiuDialog) -> void:
	PopochiuUtils.cursor.show_cursor("gui")
	PopochiuUtils.g.show_hover_text()


## Called when the running [PopochiuDialog] shows its options on screen. It shows the
## [code]"gui"[/code] cursor.
func _on_dialog_options_shown() -> void:
	PopochiuUtils.cursor.unblock()
	PopochiuUtils.cursor.show_cursor("gui")


## Called when a [PopochiuDialog] finishes. It shows the default cursor.
func _on_dialog_finished(dialog: PopochiuDialog) -> void:
	PopochiuUtils.cursor.show_cursor()


## Called when the active [PopochiuInventoryItem] changes. If there is one, it hides the main cursor
## to show the one that shows the [member PopochiuInventoryItem.texture], otherwise it shows the
## default cursor.
func _on_inventory_item_selected(item: PopochiuInventoryItem) -> void:
	if is_instance_valid(item):
		PopochiuUtils.cursor.set_secondary_cursor_texture(item.texture)
		PopochiuUtils.cursor.hide_main_cursor()
	else:
		PopochiuUtils.cursor.remove_secondary_cursor_texture()
		PopochiuUtils.cursor.show_cursor()


## Called when the game is saved. By default, it shows [code]Game saved[/code] in the SystemText
## component.
func _on_game_saved() -> void:
	PopochiuUtils.g.show_system_text("Game saved")


## Called when a game is loaded. [param loaded_game] has the loaded data. By default, it shows
## [code]Game loaded[/code] in the SystemText component.
func _on_game_loaded(loaded_game: Dictionary) -> void:
	await PopochiuUtils.g.show_system_text("Game loaded")
	
	super(loaded_game)


func _on_settings_option_selected(option_script_name: String) -> void:
	match option_script_name:
		"save":
			save_and_load_popup.open_save()
		"load":
			save_and_load_popup.open_load()
		"text_settings":
			text_settings_popup.open()
		"sound_settings":
			sound_settings_popup.open()
		"history":
			history_popup.open()
		"quit":
			quit_popup.open()


#endregion
