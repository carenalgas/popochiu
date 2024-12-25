class_name SierraGUI
extends PopochiuGraphicInterface
## Defines the behavior of the Sierra GUI.
##
## In this GUI players interact with objects based on the active command, which can be changed with
## right click or by using the buttons in the top bar that appears when the cursor moves to the
## top of the screen. The inventory can be opened with a button in the top bar, same for the
## settings.

@onready var sierra_bar: Control = %SierraBar
@onready var sierra_menu: Control = %SierraMenu
@onready var sierra_inventory_popup: Control = %SierraInventoryPopup
@onready var sierra_settings_popup: Control = %SierraSettingsPopup
@onready var sierra_sound_popup: Control = %SierraSoundPopup
@onready var text_settings_popup: Control = %TextSettingsPopup
@onready var save_and_load_popup: Control = %SaveAndLoadPopup
@onready var quit_popup: Control = %QuitPopup


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	PopochiuUtils.cursor.replace_frames($Cursor)
	PopochiuUtils.cursor.show_cursor()
	
	$Cursor.hide()
	
	PopochiuUtils.e.current_command = SierraCommands.Commands.WALK
	
	# Connect to child signals
	sierra_settings_popup.option_selected.connect(_on_settings_option_selected)
	sierra_menu.visibility_changed.connect(_on_menu_visibility_changed)


func _input(event: InputEvent) -> void:
	if PopochiuUtils.g.is_blocked: return
	
	match PopochiuUtils.get_click_or_touch_index(event):
		MOUSE_BUTTON_LEFT:
			# NOTE: When clicking anywhere with the Left Mouse Button, block
			# the player from moving to the clicked position since the Sierra
			# GUI allows characters to move only when the WALK command is
			# active.
			if (
				not sierra_menu.visible
				and not PopochiuUtils.e.hovered
				and PopochiuUtils.e.current_command != SierraCommands.Commands.WALK
			):
				accept_event()
		MOUSE_BUTTON_RIGHT:
			accept_event()
			
			if PopochiuUtils.i.active:
				PopochiuUtils.i.active = null
				PopochiuUtils.e.current_command = SierraCommands.Commands.WALK
			else:
				PopochiuUtils.e.current_command = posmod(
					PopochiuUtils.e.current_command + 1, SierraCommands.Commands.size()
				)


#endregion

#region Virtual ####################################################################################
## Called when the GUI is blocked. Makes the GUI to stop processing input.
func _on_blocked(props := { blocking = true }) -> void:
	set_process_input(false)


## Called when the GUI is unblocked. Makes the GUI to start processing input.
func _on_unblocked() -> void:
	set_process_input(true)


## Called when the mouse enters (hovers) [param clickable]. It displays a text with the
## [member PopochiuClickable.description] in the [HoverText] component.
func _on_mouse_entered_clickable(clickable: PopochiuClickable) -> void:
	if PopochiuUtils.g.is_blocked: return
	
	if not PopochiuUtils.i.active:
		PopochiuUtils.g.show_hover_text(clickable.description)
	else:
		PopochiuUtils.g.show_hover_text(
			"Use %s with %s" % [PopochiuUtils.i.active.description, clickable.description]
		)


## Called when the mouse exits [param clickable]. Clears the text in the [HoverText] component.
func _on_mouse_exited_clickable(clickable: PopochiuClickable) -> void:
	if PopochiuUtils.g.is_blocked: return
	
	PopochiuUtils.g.show_hover_text()


## Called when a dialogue line starts. It shows the [code]"wait"[/code] cursor.
func _on_dialog_line_started() -> void:
	PopochiuUtils.cursor.hide()


## Called when a dialogue line finishes. It shows the [code]"normal"[/code] cursor.
func _on_dialog_line_finished() -> void:
	PopochiuUtils.cursor.show()


## Called when a [PopochiuDialog] starts. It shows the [code]"gui"[/code] cursor.
func _on_dialog_started(_dialog: PopochiuDialog) -> void:
	PopochiuUtils.cursor.show_cursor("gui")


## Called when the running [PopochiuDialog] shows its options on screen. It shows the
## [code]"gui"[/code] cursor.
func _on_dialog_options_shown() -> void:
	PopochiuUtils.cursor.unblock()
	PopochiuUtils.cursor.show_cursor("gui")


## Called when a [PopochiuDialog] finishes. It shows the cursor of the last active command.
func _on_dialog_finished(_dialog: PopochiuDialog) -> void:
	PopochiuUtils.cursor.show_cursor(PopochiuUtils.e.get_current_command_name().to_snake_case())


## Called when the active [PopochiuInventoryItem] changes. If there is one, it hides the main cursor
## to show the one that shows the [member PopochiuInventoryItem.texture], otherwise it shows the
## default cursor.
func _on_inventory_item_selected(item: PopochiuInventoryItem) -> void:
	if is_instance_valid(item):
		PopochiuUtils.cursor.set_secondary_cursor_texture(item.texture, true)
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


## Called by [b]cursor.gd[/b] to get the name of the cursor texture to show.
func _get_cursor_name() -> String:
	return PopochiuUtils.e.get_current_command_name().to_snake_case()


#endregion

#region Private ####################################################################################
func _on_settings_option_selected(option_name: String) -> void:
	match option_name:
		"sound":
			sierra_sound_popup.open()
		"text":
			text_settings_popup.open()
		"save":
			save_and_load_popup.open_save()
		"load":
			save_and_load_popup.open_load()
		"quit":
			quit_popup.open()


func _on_menu_visibility_changed():
	if sierra_menu.visible:
		sierra_bar.hide()
	else:
		sierra_bar.show()


#endregion
